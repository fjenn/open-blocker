package app.openblocker.android.ui.screens

import android.Manifest
import android.app.Activity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.DisposableEffect
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.openblocker.android.data.ModeRepository
import app.openblocker.android.data.PreferencesManager
import app.openblocker.android.data.ScreenshotDirector
import app.openblocker.android.data.SessionManager
import app.openblocker.android.ui.components.KeyModelScene
import app.openblocker.android.domain.BlockMode
import app.openblocker.android.domain.DurationText
import app.openblocker.android.domain.HoldFill
import app.openblocker.android.key.KeyMatcher
import app.openblocker.android.qr.QrScanActivity
import app.openblocker.android.ui.components.ButtonEmphasis
import app.openblocker.android.ui.components.Glyph
import app.openblocker.android.ui.components.GlyphIcon
import app.openblocker.android.ui.components.KeyPuck
import app.openblocker.android.ui.components.KeyStage
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.components.TodayPill
import app.openblocker.android.ui.permissions.PermissionKind
import app.openblocker.android.ui.permissions.PermissionStatusReader
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.asCopy
import app.openblocker.android.ui.theme.obColors
import app.openblocker.android.util.AccessibilityUtil
import kotlinx.coroutines.delay

enum class HomeReadiness { NEEDS_ACCESSIBILITY, NEEDS_KEY, NEEDS_APPS, READY }

data class BlockUiState(
    val blocking: Boolean,
    val sessionSeconds: Long,
    val todaySeconds: Long,
    val modeName: String,
    val modeSubtitle: String,
    val readiness: HomeReadiness,
    val holdProgress: Float = 0f,
    val holdHolding: Boolean = false
)

@Composable
fun BlockTab(
    onOpenModes: () -> Unit,
    onOpenKeySetup: () -> Unit,
    onDenied: (PermissionKind) -> Unit,
    onExplainAccessibility: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val blocking by SessionManager.isBlocking.collectAsState()
    val start by SessionManager.sessionStartTime.collectAsState()
    val modes by ModeRepository.modes.collectAsState()
    val activeId by ModeRepository.activeModeId.collectAsState()
    val mode = modes.find { it.id == activeId } ?: modes.firstOrNull()
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    var hold by remember { mutableStateOf(HoldFill()) }
    var toast by remember { mutableStateOf<String?>(null) }
    var resumeTick by remember { mutableStateOf(0) }

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) resumeTick++
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    LaunchedEffect(blocking) {
        while (blocking) {
            now = System.currentTimeMillis()
            delay(1000)
        }
    }

    val accessibilityOn = remember(resumeTick) {
        AccessibilityUtil.isAccessibilityServiceEnabled(context)
    }
    val shot by ScreenshotDirector.cue.collectAsState()
    val hasKey = PreferencesManager.getPairedKeyCount() > 0
    val readiness = when {
        shot.forceReady -> HomeReadiness.READY
        !accessibilityOn && !blocking -> HomeReadiness.NEEDS_ACCESSIBILITY
        !hasKey && !blocking -> HomeReadiness.NEEDS_KEY
        mode == null || !mode.hasAnythingToBlock() ->
            if (blocking) HomeReadiness.READY else HomeReadiness.NEEDS_APPS
        else -> HomeReadiness.READY
    }

    val sessionSeconds = if (blocking && start > 0) (now - start) / 1000 else 0L
    val today = SessionManager.todayBlockedSeconds()

    val previewHold = shot.hold

    val qrLauncher = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode != Activity.RESULT_OK) return@rememberLauncherForActivityResult
        val raw = result.data?.getStringExtra(QrScanActivity.EXTRA_PAYLOAD) ?: return@rememberLauncherForActivityResult
        KeyMatcher.onQrScanned(context, raw)
    }
    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        PermissionStatusReader.markAsked(context, "camera")
        if (granted) {
            qrLauncher.launch(QrScanActivity.intent(context, QrScanActivity.MODE_SESSION))
        } else {
            onDenied(PermissionKind.CAMERA)
        }
    }

    fun openQr() {
        PermissionStatusReader.handleRuntime(
            status = PermissionStatusReader.camera(context),
            request = {
                PermissionStatusReader.markAsked(context, "camera")
                cameraLauncher.launch(Manifest.permission.CAMERA)
            },
            granted = { qrLauncher.launch(QrScanActivity.intent(context, QrScanActivity.MODE_SESSION)) },
            denied = { onDenied(PermissionKind.CAMERA) }
        )
    }

    fun handleTap() {
        when (readiness) {
            HomeReadiness.NEEDS_ACCESSIBILITY -> onExplainAccessibility()
            HomeReadiness.NEEDS_KEY -> onOpenKeySetup()
            HomeReadiness.NEEDS_APPS -> onOpenModes()
            HomeReadiness.READY -> {
                if (PreferencesManager.getPairedQrPayloads().isNotEmpty() &&
                    PreferencesManager.getPairedTagIds().isEmpty() &&
                    PreferencesManager.getPairedTagUids().isEmpty() &&
                    PreferencesManager.getAnyCardUids().isEmpty()
                ) {
                    openQr()
                } else if (PreferencesManager.getPairedQrPayloads().isNotEmpty()) {
                    openQr()
                } else {
                    toast = if (blocking) "Tap your NFC key to unblock." else "Tap your NFC key, or hold the puck to block."
                }
            }
        }
    }

    BlockTabContent(
        state = BlockUiState(
            blocking = blocking,
            sessionSeconds = sessionSeconds,
            todaySeconds = today,
            modeName = mode?.name?.ifEmpty { "No mode" } ?: "No mode",
            modeSubtitle = mode?.subtitle ?: "Pick a mode to choose what gets blocked.",
            readiness = readiness,
            holdProgress = previewHold ?: hold.progress.toFloat(),
            holdHolding = previewHold != null || hold.isHolding
        ),
        toast = toast,
        onToastConsumed = { toast = null },
        onOpenModes = onOpenModes,
        onPrimary = {
            when (readiness) {
                HomeReadiness.NEEDS_ACCESSIBILITY -> onExplainAccessibility()
                HomeReadiness.NEEDS_KEY -> onOpenKeySetup()
                HomeReadiness.NEEDS_APPS -> onOpenModes()
                HomeReadiness.READY -> handleTap()
            }
        },
        keySlot = {
            when {
                blocking -> KeyModelScene(
                    progress = 1f,
                    yaw = 0.15f,
                    locked = true,
                    burst = 0.28f,
                    modifier = Modifier.fillMaxSize()
                )
                previewHold != null -> KeyModelScene(
                    progress = previewHold,
                    yaw = 0.15f,
                    locked = false,
                    burst = 0f,
                    modifier = Modifier.fillMaxSize()
                )
                else -> KeyStage(
                    locked = false,
                    enabled = readiness == HomeReadiness.READY,
                    onCompleted = { SessionManager.startSession(SessionManager.SOURCE_HOLD) },
                    onTap = { handleTap() },
                    onHoldWhileLocked = { toast = "Unblocking needs your key." },
                    onProgress = { hold = it },
                    modifier = Modifier.fillMaxSize()
                )
            }
        },
        modifier = modifier
    )
}

@Composable
fun BlockTabContent(
    state: BlockUiState,
    onOpenModes: () -> Unit,
    onPrimary: () -> Unit,
    modifier: Modifier = Modifier,
    toast: String? = null,
    onToastConsumed: () -> Unit = {},
    interactiveKey: Boolean = true,
    keySlot: (@Composable () -> Unit)? = null
) {
    val colors = obColors()
    val buttonTitle = when {
        state.blocking -> "Scan your key to unblock"
        state.readiness == HomeReadiness.NEEDS_ACCESSIBILITY -> "Allow Accessibility"
        state.readiness == HomeReadiness.NEEDS_KEY -> "Add a key"
        state.readiness == HomeReadiness.NEEDS_APPS -> "Choose apps to block"
        state.holdHolding -> "Keep holding"
        else -> "Tap your key or hold to block"
    }
    val hint = when {
        state.blocking -> "Lost your key? Settings has emergency unblocks."
        state.readiness == HomeReadiness.NEEDS_ACCESSIBILITY ->
            "Android requires this to block apps. We don't read your usage."
        state.readiness == HomeReadiness.NEEDS_KEY -> "Add a key to start. It is what unblocks you."
        state.readiness == HomeReadiness.NEEDS_APPS -> "This mode has nothing to block yet."
        state.holdHolding -> "Let go to cancel."
        else -> "Unblocking needs your key."
    }

    Box(modifier.fillMaxSize().background(colors.canvas).testTag("home_screen")) {
        Column(
            Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(Modifier.height(96.dp).fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
                if (state.blocking) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(top = Space.s).testTag("blocked_timer")
                    ) {
                        Text("Blocked for".asCopy(), style = ObText.footnote, color = colors.inkSecondary)
                        Text(DurationText.clock(state.sessionSeconds).asCopy(), style = ObText.timer, color = colors.ink, maxLines = 1)
                    }
                } else {
                    Box(Modifier.padding(top = Space.s)) {
                        TodayPill(state.todaySeconds)
                    }
                }
            }

            Spacer(Modifier.weight(1f))

            Box(
                Modifier
                    .widthIn(max = 300.dp)
                    .fillMaxWidth()
                    .aspectRatio(1f),
                contentAlignment = Alignment.Center
            ) {
                if (keySlot != null && interactiveKey) {
                    keySlot()
                } else {
                    KeyPuck(
                        progress = if (state.blocking) 1f else state.holdProgress,
                        yaw = 0.15f,
                        locked = state.blocking,
                        burst = if (state.blocking) 0.28f else 0f,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }

            Column(
                Modifier
                    .padding(horizontal = Space.margin)
                    .padding(top = Space.xs),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(Space.xxs)
            ) {
                Text(
                    state.modeName.asCopy(),
                    style = ObText.title.copy(fontWeight = FontWeight.Medium),
                    color = colors.ink,
                    maxLines = 1,
                    modifier = Modifier.testTag("mode_name")
                )
                Text(state.modeSubtitle.asCopy(), style = ObText.subhead, color = colors.inkSecondary, textAlign = TextAlign.Center)
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clickable(indication = null, interactionSource = remember { MutableInteractionSource() }, onClick = onOpenModes)
                        .padding(horizontal = Space.m, vertical = Space.xs)
                        .testTag("manage_modes")
                ) {
                    Text(
                        (if (state.blocking) "View modes" else "Manage modes").asCopy(),
                        style = ObText.footnote.copy(fontWeight = FontWeight.SemiBold),
                        color = colors.ink
                    )
                    Spacer(Modifier.size(4.dp))
                    GlyphIcon(Glyph.Chevron, colors.ink, size = 10.dp)
                }
            }

            Spacer(Modifier.height(Space.l))

            Box(Modifier.padding(horizontal = Space.xl)) {
                if (state.readiness != HomeReadiness.READY && !state.blocking) {
                    PrimaryButton(buttonTitle, emphasis = ButtonEmphasis.QUIET, testTag = "home_primary", onClick = onPrimary)
                } else {
                    PrimaryButton(
                        buttonTitle,
                        progress = if (state.blocking) 0f else state.holdProgress,
                        testTag = "home_primary",
                        onClick = onPrimary
                    )
                }
            }

            Text(
                hint.asCopy(),
                style = ObText.footnote.copy(fontWeight = FontWeight.Normal),
                color = colors.inkTertiary,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .padding(horizontal = Space.xxxl)
                    .padding(top = Space.s)
                    .heightIn(min = 36.dp)
                    .testTag("home-hint")
            )
            Spacer(Modifier.height(Space.s))
        }

        if (toast != null) {
            Text(
                toast,
                style = ObText.subhead.copy(fontWeight = FontWeight.Medium),
                color = colors.inkInverse,
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(top = Space.xs)
                    .background(colors.ink.copy(alpha = 0.92f), androidx.compose.foundation.shape.RoundedCornerShape(50))
                    .clickable { onToastConsumed() }
                    .padding(horizontal = Space.l, vertical = Space.s)
                    .testTag("toast")
            )
            LaunchedEffect(toast) {
                delay(2800)
                onToastConsumed()
            }
        }
    }
}
