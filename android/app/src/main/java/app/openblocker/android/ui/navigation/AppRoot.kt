package app.openblocker.android.ui.navigation

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import app.openblocker.android.data.OnboardingStore
import app.openblocker.android.data.ScheduleRepository
import app.openblocker.android.data.ScreenshotDirector
import app.openblocker.android.data.SessionNotify
import app.openblocker.android.domain.BlockMode
import app.openblocker.android.domain.BlockSchedule
import app.openblocker.android.ui.components.AppTab
import app.openblocker.android.ui.components.PhoneShell
import app.openblocker.android.ui.components.StatusBarScrim
import app.openblocker.android.ui.permissions.PermissionKind
import app.openblocker.android.ui.permissions.PermissionStatusReader
import app.openblocker.android.ui.screens.AboutScreen
import app.openblocker.android.ui.screens.AccessibilityExplainer
import app.openblocker.android.ui.screens.ActivityTab
import app.openblocker.android.ui.screens.AddKeySheet
import app.openblocker.android.ui.screens.AnyCardPairingScreen
import app.openblocker.android.ui.screens.AppPickerScreen
import app.openblocker.android.ui.screens.BlockTab
import app.openblocker.android.ui.screens.ContactScreen
import app.openblocker.android.ui.screens.DebugScreen
import app.openblocker.android.ui.screens.EmergencyUnblockScreen
import app.openblocker.android.ui.screens.HelpScreen
import app.openblocker.android.ui.screens.KeysScreen
import app.openblocker.android.ui.screens.ModeEditFlow
import app.openblocker.android.ui.screens.ModesSheet
import app.openblocker.android.ui.screens.NotificationsScreen
import app.openblocker.android.ui.screens.OnboardingScreen
import app.openblocker.android.ui.screens.PermissionDeniedSheet
import app.openblocker.android.ui.screens.PrivacyScreen
import app.openblocker.android.ui.screens.QrKeyScreen
import app.openblocker.android.ui.screens.QrPasteScreen
import app.openblocker.android.ui.screens.RulesScreen
import app.openblocker.android.ui.screens.ScheduleEditSheet
import app.openblocker.android.ui.screens.ScheduleTab
import app.openblocker.android.ui.screens.SettingsTab
import app.openblocker.android.ui.screens.TagPairingScreen
import app.openblocker.android.ui.AppNotice
import app.openblocker.android.ui.theme.Motion
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.obColors
import app.openblocker.android.util.AccessibilityUtil
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import kotlinx.coroutines.delay

private object Routes {
    const val ROOT = "root"
    const val SETTINGS_EMERGENCY = "settings/emergency"
    const val SETTINGS_PRIVACY = "settings/privacy"
    const val SETTINGS_HELP = "settings/help"
    const val SETTINGS_CONTACT = "settings/contact"
    const val SETTINGS_ABOUT = "settings/about"
    const val SETTINGS_NOTIFICATIONS = "settings/notifications"
    const val SETTINGS_KEYS = "settings/keys"
    const val SETTINGS_RULES = "settings/rules"
    const val TAG_PAIR = "keys/nfc"
    const val ANY_CARD = "keys/anycard"
    const val QR_KEY = "keys/qr"
    const val QR_PASTE = "keys/qrpaste"
    const val DEBUG = "debug"
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppRoot() {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val nav = rememberNavController()
    var resumeTick by remember { mutableIntStateOf(0) }
    var tab by remember { mutableStateOf(AppTab.BLOCK) }
    var showModes by remember { mutableStateOf(false) }
    var editingMode by remember { mutableStateOf<BlockMode?>(null) }
    var creatingMode by remember { mutableStateOf(false) }
    var pickingApps by remember { mutableStateOf<((Set<String>) -> Unit)?>(null) }
    var pickKind by remember { mutableStateOf(BlockMode.Kind.BLOCK) }
    var pickSelected by remember { mutableStateOf<Set<String>>(emptySet()) }
    var showScheduleEdit by remember { mutableStateOf(false) }
    var editingSchedule by remember { mutableStateOf<BlockSchedule?>(null) }
    var denied by remember { mutableStateOf<PermissionKind?>(null) }
    var explainAccessibility by remember { mutableStateOf(false) }
    var showAddKey by remember { mutableStateOf(false) }
    var onboarded by remember { mutableStateOf(OnboardingStore.isComplete()) }
    val shot by ScreenshotDirector.cue.collectAsState()

    LaunchedEffect(shot.tick) {
        if (shot.tick == 0) return@LaunchedEffect
        if (shot.screen == "onboarding") {
            onboarded = false
            return@LaunchedEffect
        }
        onboarded = OnboardingStore.isComplete()
        tab = shot.tab
        showModes = shot.screen == "modes"
        creatingMode = shot.screen == "mode_templates"
        editingMode = if (shot.screen == "mode_edit") {
            app.openblocker.android.data.ModeRepository.modes.value.firstOrNull()
        } else {
            null
        }
        showScheduleEdit = shot.screen == "schedule_edit"
        showAddKey = shot.screen == "addkey"
        nav.popBackStack(Routes.ROOT, inclusive = false)
        when (shot.screen) {
            "keys" -> nav.navigate(Routes.SETTINGS_KEYS)
            "nfc" -> {
                nav.navigate(Routes.SETTINGS_KEYS)
                nav.navigate(Routes.TAG_PAIR)
            }
            "anycard" -> {
                nav.navigate(Routes.SETTINGS_KEYS)
                nav.navigate(Routes.TAG_PAIR)
                nav.navigate(Routes.ANY_CARD)
            }
            "qr" -> {
                nav.navigate(Routes.SETTINGS_KEYS)
                nav.navigate(Routes.QR_KEY)
            }
            "qrpaste" -> nav.navigate(Routes.QR_PASTE)
            "rules" -> nav.navigate(Routes.SETTINGS_RULES)
            "help" -> nav.navigate(Routes.SETTINGS_HELP)
            "about" -> nav.navigate(Routes.SETTINGS_ABOUT)
            "contact" -> nav.navigate(Routes.SETTINGS_CONTACT)
            "notifications" -> nav.navigate(Routes.SETTINGS_NOTIFICATIONS)
        }
    }

    val notifyLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        PermissionStatusReader.markAsked(context, "notifications")
        if (granted) {
            SessionNotify.isEnabled = true
        } else {
            denied = PermissionKind.NOTIFICATIONS
        }
    }

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                resumeTick++
                ScheduleRepository.tick()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    fun openAccessibilitySettings() {
        if (Build.VERSION.SDK_INT >= 33 && AccessibilityUtil.isRestrictedSettingsLikely(context)) {
            AccessibilityUtil.openAppSettings(context)
        } else {
            AccessibilityUtil.openAccessibilitySettings(context)
        }
    }

    val accessibilityOn = remember(resumeTick) {
        AccessibilityUtil.isAccessibilityServiceEnabled(context)
    }

    if (!onboarded || shot.screen == "onboarding") {
        OnboardingScreen(
            onFinished = {
                OnboardingStore.complete()
                onboarded = true
            },
            onAllowAccessibility = { explainAccessibility = true },
            accessibilityOn = accessibilityOn,
            initialPage = shot.onboardPage,
            askedAccessibility = shot.askedAccessibility
        )
        if (explainAccessibility) {
            ModalBottomSheet(
                onDismissRequest = { explainAccessibility = false },
                sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
                containerColor = obColors().sheet
            ) {
                AccessibilityExplainer(
                    restrictedLikely = AccessibilityUtil.isRestrictedSettingsLikely(context),
                    onContinue = {
                        explainAccessibility = false
                        openAccessibilitySettings()
                    },
                    onNotNow = { explainAccessibility = false }
                )
            }
        }
        return
    }

    val notice by AppNotice.message.collectAsState()
    Box(Modifier.fillMaxSize().background(obColors().chrome)) {
        NavHost(nav, startDestination = Routes.ROOT, modifier = Modifier.fillMaxSize()) {
            composable(Routes.ROOT) {
                PhoneShell(tab = tab, onTab = { tab = it }, modifier = Modifier.navigationBarsPadding()) {
                    Box(Modifier.fillMaxSize().statusBarsPadding()) {
                        AnimatedContent(
                            targetState = tab,
                            transitionSpec = { fadeIn(Motion.fade) togetherWith fadeOut(Motion.fade) },
                            label = "tab"
                        ) { current ->
                            when (current) {
                                AppTab.BLOCK -> BlockTab(
                                    onOpenModes = { showModes = true },
                                    onOpenKeySetup = { showAddKey = true },
                                    onOpenQrPaste = { nav.navigate(Routes.QR_PASTE) },
                                    onDenied = { denied = it },
                                    onExplainAccessibility = { explainAccessibility = true }
                                )
                                AppTab.SCHEDULE -> ScheduleTab(
                                    onCreate = { editingSchedule = null; showScheduleEdit = true },
                                    onEdit = { editingSchedule = it; showScheduleEdit = true }
                                )
                                AppTab.ACTIVITY -> ActivityTab()
                                AppTab.SETTINGS -> SettingsTab(
                                    onKeys = { nav.navigate(Routes.SETTINGS_KEYS) },
                                    onRules = { nav.navigate(Routes.SETTINGS_RULES) },
                                    onEmergency = { nav.navigate(Routes.SETTINGS_EMERGENCY) },
                                    onNotifications = { nav.navigate(Routes.SETTINGS_NOTIFICATIONS) },
                                    onHelp = { nav.navigate(Routes.SETTINGS_HELP) },
                                    onContact = { nav.navigate(Routes.SETTINGS_CONTACT) },
                                    onAbout = { nav.navigate(Routes.SETTINGS_ABOUT) },
                                    onPrivacy = { nav.navigate(Routes.SETTINGS_PRIVACY) }
                                )
                            }
                        }
                    }
                    StatusBarScrim()
                }
            }
            composable(Routes.SETTINGS_EMERGENCY) { EmergencyUnblockScreen(onBack = { nav.popBackStack() }) }
            composable(Routes.SETTINGS_PRIVACY) { PrivacyScreen(onBack = { nav.popBackStack() }) }
            composable(Routes.SETTINGS_HELP) { HelpScreen(onBack = { nav.popBackStack() }) }
            composable(Routes.SETTINGS_CONTACT) { ContactScreen(onBack = { nav.popBackStack() }) }
            composable(Routes.SETTINGS_ABOUT) { AboutScreen(onBack = { nav.popBackStack() }) }
            composable(Routes.SETTINGS_NOTIFICATIONS) {
                NotificationsScreen(
                    onBack = { nav.popBackStack() },
                    onRequestNotifications = {
                        PermissionStatusReader.markAsked(context, "notifications")
                        if (Build.VERSION.SDK_INT >= 33) {
                            notifyLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                        } else {
                            SessionNotify.isEnabled = true
                        }
                    },
                    onDenied = { denied = it }
                )
            }
            composable(Routes.SETTINGS_KEYS) {
                KeysScreen(
                    onBack = { nav.popBackStack() },
                    onAdd = { showAddKey = true }
                )
            }
            composable(Routes.SETTINGS_RULES) {
                RulesScreen(
                    onBack = { nav.popBackStack() },
                    onOpenAccessibility = { openAccessibilitySettings() }
                )
            }
            composable(Routes.QR_PASTE) {
                QrPasteScreen(onClose = { nav.popBackStack() })
            }
            composable(Routes.TAG_PAIR) {
                TagPairingScreen(
                    onBack = { nav.popBackStack() },
                    onNavigateToAnyCard = { nav.navigate(Routes.ANY_CARD) }
                )
            }
            composable(Routes.ANY_CARD) { AnyCardPairingScreen(onBack = { nav.popBackStack() }) }
            composable(Routes.QR_KEY) {
                QrKeyScreen(
                    onBack = { nav.popBackStack() },
                    onDenied = { denied = it }
                )
            }
            composable(Routes.DEBUG) { DebugScreen(onBack = { nav.popBackStack() }) }
        }

        if (pickingApps != null) {
            AppPickerScreen(
                initialSelected = pickSelected,
                title = if (pickKind == BlockMode.Kind.ALLOW_ONLY) "Allowed apps" else "Blocked apps",
                onSave = { pkgs ->
                    pickingApps?.invoke(pkgs)
                    pickingApps = null
                },
                onBack = { pickingApps = null }
            )
        }
        if (shot.screen == "privacy") {
            PrivacyScreen(onBack = {})
        }
        if (shot.screen == "emergency") {
            EmergencyUnblockScreen(onBack = {})
        }
        if (shot.screen == "rules") {
            RulesScreen(onBack = {}, onOpenAccessibility = { openAccessibilitySettings() })
        }
        if (notice != null) {
            val colors = obColors()
            Text(
                notice!!,
                style = ObText.subhead.copy(fontWeight = FontWeight.Medium),
                color = colors.inkInverse,
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .statusBarsPadding()
                    .padding(top = Space.xs)
                    .background(colors.ink.copy(alpha = 0.92f), RoundedCornerShape(50))
                    .clickable {
                        AppNotice.consume()
                    }
                    .padding(horizontal = Space.l, vertical = Space.s)
                    .testTag("app_notice")
            )
            LaunchedEffect(notice) {
                delay(Motion.toastMs)
                AppNotice.consume()
            }
        }
    }

    if (showModes && !creatingMode && editingMode == null && shot.screen != "privacy" && shot.screen != "emergency") {
        ModalBottomSheet(
            onDismissRequest = { showModes = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = obColors().sheet
        ) {
            ModesSheet(
                onClose = { showModes = false },
                onNew = { creatingMode = true },
                onEdit = { editingMode = it }
            )
        }
    }
    if (creatingMode || editingMode != null) {
        ModalBottomSheet(
            onDismissRequest = { creatingMode = false; editingMode = null },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = obColors().sheet
        ) {
            ModeEditFlow(
                existing = editingMode,
                onClose = { creatingMode = false; editingMode = null },
                onPickApps = { kind, selected, done ->
                    pickKind = kind
                    pickSelected = selected
                    pickingApps = done
                }
            )
        }
    }
    if (showAddKey || shot.screen == "addkey") {
        ModalBottomSheet(
            onDismissRequest = { showAddKey = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = obColors().sheet
        ) {
            AddKeySheet(onClose = { showAddKey = false })
        }
    }
    if (showScheduleEdit) {
        ModalBottomSheet(
            onDismissRequest = { showScheduleEdit = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = obColors().sheet
        ) {
            ScheduleEditSheet(editingSchedule) { showScheduleEdit = false }
        }
    }
    if (denied != null) {
        ModalBottomSheet(
            onDismissRequest = { denied = null },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = obColors().sheet
        ) {
            PermissionDeniedSheet(
                kind = denied!!,
                onOpenSettings = {
                    PermissionStatusReader.openAppSettings(context)
                    denied = null
                },
                onNotNow = { denied = null }
            )
        }
    }
    if (explainAccessibility) {
        ModalBottomSheet(
            onDismissRequest = { explainAccessibility = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = obColors().sheet
        ) {
            AccessibilityExplainer(
                restrictedLikely = AccessibilityUtil.isRestrictedSettingsLikely(context),
                onContinue = {
                    explainAccessibility = false
                    openAccessibilitySettings()
                },
                onNotNow = { explainAccessibility = false }
            )
        }
    }
}
