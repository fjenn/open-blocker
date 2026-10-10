package app.openblocker.android.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.openblocker.android.BuildConfig
import app.openblocker.android.data.AppearanceManager
import app.openblocker.android.data.CountManager
import app.openblocker.android.data.EmergencyUnblockManager
import app.openblocker.android.data.PreferencesManager
import app.openblocker.android.data.SessionManager
import app.openblocker.android.data.SessionNotify
import app.openblocker.android.domain.EmergencyAllowance
import app.openblocker.android.ui.components.BrandMark
import app.openblocker.android.ui.components.ButtonEmphasis
import app.openblocker.android.ui.components.CardSurface
import app.openblocker.android.ui.components.Glyph
import app.openblocker.android.ui.components.HairlineDivider
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.components.PushedHeader
import app.openblocker.android.ui.components.ScrollColumn
import app.openblocker.android.ui.components.SegmentedPill
import app.openblocker.android.ui.components.SettingsGroup
import app.openblocker.android.ui.components.SettingsRow
import app.openblocker.android.ui.components.SettingsToggleRow
import app.openblocker.android.ui.components.TabHeader
import app.openblocker.android.ui.permissions.PermissionKind
import app.openblocker.android.ui.permissions.PermissionStatus
import app.openblocker.android.ui.permissions.PermissionStatusReader
import app.openblocker.android.ui.theme.AppAppearance
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.Radius
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.asCopy
import app.openblocker.android.ui.theme.obColors
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun SettingsTab(
    onKeys: () -> Unit,
    onRules: () -> Unit,
    onEmergency: () -> Unit,
    onNotifications: () -> Unit,
    onHelp: () -> Unit,
    onContact: () -> Unit,
    onAbout: () -> Unit,
    onPrivacy: () -> Unit,
    modifier: Modifier = Modifier
) {
    val appearance by AppearanceManager.appearance
    val remaining by EmergencyUnblockManager.remaining.collectAsState()
    var countOn by remember { mutableStateOf(CountManager.isPreferenceEnabled()) }
    val notifyOn = SessionNotify.isEnabled
    val keyCount = PreferencesManager.getPairedKeyCount()
    val context = LocalContext.current
    val rulesOn = app.openblocker.android.util.AccessibilityUtil.isAccessibilityServiceEnabled(context)

    SettingsTabContent(
        appearance = appearance,
        onAppearance = { AppearanceManager.setAppearance(it) },
        emergencyLeft = remaining,
        notifyOn = notifyOn,
        countOn = countOn,
        onCount = {
            CountManager.setCountingEnabled(it)
            countOn = it
        },
        keyCount = keyCount,
        rulesOn = rulesOn,
        version = BuildConfig.VERSION_NAME,
        onKeys = onKeys,
        onRules = onRules,
        onEmergency = onEmergency,
        onNotifications = onNotifications,
        onHelp = onHelp,
        onContact = onContact,
        onAbout = onAbout,
        onPrivacy = onPrivacy,
        modifier = modifier
    )
}

@Composable
fun SettingsTabContent(
    appearance: AppAppearance,
    onAppearance: (AppAppearance) -> Unit,
    emergencyLeft: Int,
    notifyOn: Boolean,
    countOn: Boolean,
    onCount: (Boolean) -> Unit,
    keyCount: Int,
    rulesOn: Boolean = false,
    version: String,
    onKeys: () -> Unit,
    onRules: () -> Unit = {},
    onEmergency: () -> Unit,
    onNotifications: () -> Unit,
    onHelp: () -> Unit,
    onContact: () -> Unit,
    onAbout: () -> Unit,
    onPrivacy: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = obColors()
    Column(modifier.fillMaxSize().background(colors.canvas).testTag("settings_screen")) {
        ScrollColumn {
            TabHeader("Settings")
            Spacer(Modifier.height(Space.l))
            SettingsGroup {
                SettingsRow(Glyph.Key, "My Keys", detail = "$keyCount", testTag = "settings_keys", onClick = onKeys)
                HairlineDivider()
                SettingsRow(Glyph.Clipboard, "My Rules", detail = if (rulesOn) "On" else "Off", testTag = "settings_rules", onClick = onRules)
                HairlineDivider()
                SettingsRow(Glyph.LifeRing, "Emergency Unblock", detail = "$emergencyLeft left", testTag = "settings_emergency", onClick = onEmergency)
                HairlineDivider()
                SettingsRow(Glyph.Bell, "Notifications", detail = if (notifyOn) "On" else "Off", testTag = "settings_notifications", onClick = onNotifications)
            }
            Spacer(Modifier.height(Space.m))
            SettingsGroup {
                Column(Modifier.padding(Space.m), verticalArrangement = Arrangement.spacedBy(Space.s)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(Space.s), verticalAlignment = Alignment.CenterVertically) {
                        app.openblocker.android.ui.components.GlyphIcon(Glyph.Appearance, colors.ink, Modifier.width(22.dp), 15.dp)
                        Text("Appearance".asCopy(), style = ObText.body.copy(fontWeight = FontWeight.Medium), color = colors.ink)
                    }
                    SegmentedPill(
                        options = AppAppearance.entries.map { it.title to it },
                        selected = appearance,
                        onSelect = onAppearance,
                        testTag = "appearance_picker"
                    )
                }
            }
            Spacer(Modifier.height(Space.m))
            SettingsGroup {
                SettingsRow(Glyph.Help, "Help", testTag = "settings_help", onClick = onHelp)
                HairlineDivider()
                SettingsRow(Glyph.Contact, "Contact", testTag = "settings_contact", onClick = onContact)
                HairlineDivider()
                SettingsRow(Glyph.About, "About", testTag = "settings_about", onClick = onAbout)
                HairlineDivider()
                SettingsRow(Glyph.Privacy, "Privacy", testTag = "settings_privacy", onClick = onPrivacy)
            }
            Spacer(Modifier.height(Space.m))
            SettingsGroup {
                SettingsToggleRow(
                    Glyph.People,
                    "Share anonymous count",
                    checked = countOn,
                    onCheckedChange = onCount,
                    subtitle = CountManager.SUMMARY,
                    testTag = "count_toggle"
                )
            }
            Spacer(Modifier.height(Space.l))
            Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                BrandMark(30.dp)
                Spacer(Modifier.height(Space.xs))
                Text("Open Blocker".asCopy(), style = ObText.headline, color = colors.ink)
                Text("Version $version · MIT License".asCopy(), style = ObText.footnote.copy(fontWeight = FontWeight.Normal), color = colors.inkTertiary)
            }
            Spacer(Modifier.height(Space.l))
        }
    }
}

@Composable
fun EmergencyUnblockScreen(onBack: () -> Unit, modifier: Modifier = Modifier) {
    var status by remember { mutableStateOf(EmergencyUnblockManager.status()) }
    var confirming by remember { mutableStateOf(false) }
    var notice by remember { mutableStateOf<String?>(null) }
    val blocking by SessionManager.isBlocking.collectAsState()
    EmergencyUnblockContent(
        remaining = status.remaining,
        resetDate = status.resetDate,
        confirming = confirming,
        notice = notice,
        onBack = onBack,
        onUse = {
            if (status.remaining <= 0) return@EmergencyUnblockContent
            if (blocking) {
                notice = null
                confirming = true
            } else {
                notice = "You're not blocked right now. This only works during a block."
            }
        },
        onCancel = { confirming = false },
        onConfirm = {
            val ok = EmergencyUnblockManager.useOne()
            if (ok) {
                status = EmergencyUnblockManager.status()
                SessionManager.endSession()
                notice = "Unblocked."
            } else {
                notice = "Could not use one right now."
            }
            confirming = false
        },
        modifier = modifier
    )
}

@Composable
fun EmergencyUnblockContent(
    remaining: Int,
    resetDate: Date,
    confirming: Boolean,
    notice: String?,
    onBack: () -> Unit,
    onUse: () -> Unit,
    onCancel: () -> Unit,
    onConfirm: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = obColors()
    val formatted = remember(resetDate) {
        SimpleDateFormat("MMM d, yyyy", Locale.getDefault()).format(resetDate)
    }
    Column(modifier.fillMaxSize().background(colors.canvas).testTag("emergency_screen")) {
        PushedHeader("Emergency Unblock", onBack)
        Column(
            Modifier.fillMaxSize().padding(horizontal = Space.margin),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.weight(1f))
            Row(horizontalArrangement = Arrangement.spacedBy(Space.xs)) {
                repeat(EmergencyAllowance.maxCount) { i ->
                    Box(
                        Modifier
                            .width(28.dp)
                            .height(8.dp)
                            .clip(RoundedCornerShape(50))
                            .background(if (i < remaining) colors.ink else colors.fillQuiet)
                    )
                }
            }
            Spacer(Modifier.height(Space.m))
            Text("$remaining left".asCopy(), style = ObText.timer, color = colors.ink, modifier = Modifier.testTag("emergency_count"))
            Text(
                "End a block without your key. Honesty, not a lock you cannot break.".asCopy(),
                style = ObText.body,
                color = colors.inkSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = Space.xxxl, vertical = Space.m)
            )
            Text("You get ${EmergencyAllowance.maxCount} every ${EmergencyAllowance.periodMonths} months.".asCopy(), style = ObText.subhead, color = colors.inkTertiary, textAlign = TextAlign.Center)
            Text("Resets on $formatted".asCopy(), style = ObText.subhead, color = colors.inkSecondary, textAlign = TextAlign.Center, modifier = Modifier.testTag("emergency_reset"))
            Spacer(Modifier.weight(1f))
            if (confirming) {
                CardSurface(raised = true, modifier = Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(Space.l), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(Space.m)) {
                        Text("Unblock without your key?".asCopy(), style = ObText.headline, color = colors.ink)
                        Text("You'll have ${maxOf(remaining - 1, 0)} left.".asCopy(), style = ObText.subhead, color = colors.inkSecondary)
                        Row(horizontalArrangement = Arrangement.spacedBy(Space.s)) {
                            Box(Modifier.weight(1f)) { PrimaryButton("Cancel", onClick = onCancel) }
                            Box(Modifier.weight(1f)) { PrimaryButton("Use", emphasis = ButtonEmphasis.INK, testTag = "emergency_confirm", onClick = onConfirm) }
                        }
                    }
                }
            } else {
                PrimaryButton(
                    "Use an emergency unblock",
                    emphasis = ButtonEmphasis.INK,
                    enabled = remaining > 0,
                    testTag = "emergency_use",
                    onClick = onUse
                )
            }
            if (notice != null) {
                Text(notice, style = ObText.subhead, color = colors.inkSecondary, textAlign = TextAlign.Center, modifier = Modifier.padding(top = Space.m))
            }
            Spacer(Modifier.height(Space.xl))
        }
    }
}

@Composable
fun PrivacyScreen(onBack: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    PrivacyContent(
        onBack = onBack,
        onPolicy = {
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://openblocker.vercel.app/privacy")))
        },
        modifier = modifier
    )
}

@Composable
fun PrivacyContent(onBack: () -> Unit, onPolicy: () -> Unit, modifier: Modifier = Modifier) {
    val colors = obColors()
    val permissions = listOf(
        Triple(Glyph.Hourglass, "Accessibility", "Android requires this so we can block apps and websites. While a block is on, we read the address bar in supported browsers to enforce your website list. We don't store or send those addresses. Time blocked is our own count."),
        Triple(Glyph.Nfc, "NFC", "Reads your key tag or card, and sets up new tags."),
        Triple(Glyph.Camera, "Camera", "Scans your QR key. Nothing is recorded."),
        Triple(Glyph.Bell, "Notifications", "Tells you when a block ends, if you turn it on.")
    )
    Column(modifier.fillMaxSize().background(colors.canvas).testTag("privacy_screen")) {
        PushedHeader("Privacy", onBack)
        ScrollColumn {
            CardSurface { Column(Modifier.padding(Space.l), verticalArrangement = Arrangement.spacedBy(Space.xs)) {
                Text("Stays on your phone".asCopy(), style = ObText.headline, color = colors.ink)
                Text("Your modes, keys, schedules and history stay on your phone. Open Blocker has no accounts and no ads.".asCopy(), style = ObText.body, color = colors.inkSecondary)
            } }
            Spacer(Modifier.height(Space.s))
            CardSurface { Column(Modifier.padding(Space.l), verticalArrangement = Arrangement.spacedBy(Space.xs)) {
                Text("Anonymous count".asCopy(), style = ObText.headline, color = colors.ink)
                Text((CountManager.DISCLOSURE + " Turn it off in Settings any time.").asCopy(), style = ObText.body, color = colors.inkSecondary)
            } }
            Text("Permissions".asCopy(), style = ObText.subhead.copy(fontWeight = FontWeight.SemiBold), color = colors.inkSecondary, modifier = Modifier.padding(top = Space.s, bottom = Space.xs))
            SettingsGroup {
                permissions.forEachIndexed { i, item ->
                    if (i > 0) HairlineDivider()
                    SettingsRow(item.first, item.second, subtitle = item.third, chevron = false)
                }
            }
            Spacer(Modifier.height(Space.s))
            PrimaryButton("Full privacy policy", onClick = onPolicy)
            Spacer(Modifier.height(Space.xxl))
        }
    }
}

@Composable
fun HelpScreen(onBack: () -> Unit) {
    val colors = obColors()
    val faqs = listOf(
        "How keys work" to "A physical key (an NFC tag, a card, or a printed QR) unblocks your phone. You can start a block by holding the key on screen, or by scanning your key. Honesty, not a lock you cannot break.",
        "Emergency unblocks" to "If your key is out of reach, an emergency unblock ends the session. You get five every six months. The Emergency Unblock page shows when they reset.",
        "Does it track my usage?" to "No. Android requires Accessibility to block apps and websites. While a block is on we read the address bar in supported browsers to enforce your website list. We don't store or send those addresses. Time blocked only counts your own blocks."
    )
    Column(Modifier.fillMaxSize().background(colors.canvas)) {
        PushedHeader("Help", onBack)
        ScrollColumn {
            faqs.forEach { (q, a) ->
                CardSurface(Modifier.padding(bottom = Space.s)) {
                    Column(Modifier.padding(Space.l), verticalArrangement = Arrangement.spacedBy(Space.xs)) {
                        Text(q, style = ObText.headline, color = colors.ink)
                        Text(a, style = ObText.body, color = colors.inkSecondary)
                    }
                }
            }
        }
    }
}

@Composable
fun AboutScreen(onBack: () -> Unit) {
    val colors = obColors()
    val context = LocalContext.current
    Column(Modifier.fillMaxSize().background(colors.canvas), horizontalAlignment = Alignment.CenterHorizontally) {
        PushedHeader("About", onBack)
        Spacer(Modifier.weight(1f))
        BrandMark(96.dp)
        Text("Open Blocker", style = ObText.largeTitle, color = colors.ink, modifier = Modifier.padding(top = Space.xs))
        Text("Version ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})", style = ObText.subhead, color = colors.inkSecondary)
        Text("MIT License", style = ObText.subhead, color = colors.inkSecondary)
        Text(
            "A physical key unblocks your phone. Free, open, and honest.",
            style = ObText.body,
            color = colors.inkSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = Space.xxxl, vertical = Space.xs)
        )
        Spacer(Modifier.weight(1f))
        PrimaryButton("Project page", modifier = Modifier.padding(horizontal = Space.xxxl), onClick = {
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://openblocker.vercel.app")))
        })
        Spacer(Modifier.height(Space.xxxl))
    }
}

@Composable
fun ContactScreen(onBack: () -> Unit) {
    val colors = obColors()
    val context = LocalContext.current
    Column(Modifier.fillMaxSize().background(colors.canvas), horizontalAlignment = Alignment.CenterHorizontally) {
        PushedHeader("Contact", onBack)
        Spacer(Modifier.weight(1f))
        Box(Modifier.padding(Space.m).clip(androidx.compose.foundation.shape.CircleShape).background(colors.fillQuiet).padding(28.dp)) {
            app.openblocker.android.ui.components.GlyphIcon(Glyph.Contact, colors.inkSecondary, size = 32.dp)
        }
        Text("Bugs, questions, and ideas.", style = ObText.title, color = colors.ink, textAlign = TextAlign.Center)
        Text(
            "The project page is the public home for Open Blocker. Open an issue or say hello there.",
            style = ObText.body,
            color = colors.inkSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = Space.xxxl)
        )
        Spacer(Modifier.weight(1f))
        PrimaryButton("Open the project page", modifier = Modifier.padding(horizontal = Space.xxxl), onClick = {
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://openblocker.vercel.app")))
        })
        Spacer(Modifier.height(Space.xxxl))
    }
}

@Composable
fun NotificationsScreen(onBack: () -> Unit, onRequestNotifications: () -> Unit, onDenied: (PermissionKind) -> Unit) {
    val context = LocalContext.current
    var enabled by remember { mutableStateOf(SessionNotify.isEnabled) }
    val colors = obColors()
    Column(Modifier.fillMaxSize().background(colors.canvas)) {
        PushedHeader("Notifications", onBack)
        Column(Modifier.padding(horizontal = Space.margin, vertical = Space.xs)) {
            SettingsGroup {
                SettingsToggleRow(
                    Glyph.Bell,
                    "When a block ends",
                    checked = enabled,
                    subtitle = "A quiet notification when you unblock, use an emergency unblock, or a schedule ends.",
                    onCheckedChange = { on ->
                        if (!on) {
                            SessionNotify.isEnabled = false
                            enabled = false
                            return@SettingsToggleRow
                        }
                        val status = PermissionStatusReader.notifications(context)
                        when (status) {
                            PermissionStatus.GRANTED -> {
                                SessionNotify.isEnabled = true
                                enabled = true
                            }
                            PermissionStatus.NOT_DETERMINED -> onRequestNotifications()
                            PermissionStatus.DENIED -> onDenied(PermissionKind.NOTIFICATIONS)
                        }
                    },
                    testTag = "notifications_toggle"
                )
            }
        }
    }
}

@Composable
fun KeysScreen(onBack: () -> Unit, onAdd: () -> Unit) {
    val colors = obColors()
    val keys by app.openblocker.android.data.KeyStore.keys.collectAsState()
    val blocking by SessionManager.isBlocking.collectAsState()
    Column(Modifier.fillMaxSize().background(colors.canvas).testTag("keys_screen")) {
        PushedHeader("My Keys", onBack)
        Box(Modifier.fillMaxSize()) {
            if (keys.isEmpty()) {
                app.openblocker.android.ui.components.EmptyState(
                    "No keys yet",
                    "A key is the thing you hold: an NFC tag, a card, or a printed QR. It is what unblocks you.",
                    glyph = Glyph.Key
                )
            } else {
                ScrollColumn {
                    keys.forEach { key ->
                        KeyCardRow(key, canDelete = !blocking)
                        Spacer(Modifier.height(Space.s))
                    }
                    if (blocking) {
                        Text(
                            "Keys can't be removed while you're blocked.".asCopy(),
                            style = ObText.footnote.copy(fontWeight = FontWeight.Normal),
                            color = colors.inkTertiary
                        )
                    }
                    Spacer(Modifier.height(120.dp))
                }
            }
            PrimaryButton(
                "Add Key",
                emphasis = ButtonEmphasis.INK,
                testTag = "add_key",
                onClick = onAdd,
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(horizontal = Space.xxxl)
                    .padding(bottom = Space.l)
            )
        }
    }
}

@Composable
private fun KeyCardRow(key: app.openblocker.android.data.StoredKey, canDelete: Boolean) {
    val colors = obColors()
    var menu by remember { mutableStateOf(false) }
    var confirming by remember { mutableStateOf(false) }
    val glyph = when (key.kind) {
        app.openblocker.android.data.StoredKey.Kind.QR -> Glyph.Qr
        app.openblocker.android.data.StoredKey.Kind.NFC_TAG -> Glyph.Nfc
        app.openblocker.android.data.StoredKey.Kind.CARD -> Glyph.Card
    }
    CardSurface {
        Row(
            Modifier.fillMaxWidth().padding(Space.m).testTag("key_card"),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Space.m)
        ) {
            app.openblocker.android.ui.components.IconTile(glyph, size = 48.dp)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(key.name.asCopy(), style = ObText.headline, color = colors.ink)
                Text(
                    "${key.kind.title} · added ${app.openblocker.android.data.KeyCodec.addedAgo(key.addedAtMs)}".asCopy(),
                    style = ObText.subhead,
                    color = colors.inkSecondary
                )
            }
            Box {
                Box(
                    Modifier
                        .width(36.dp)
                        .height(36.dp)
                        .clip(androidx.compose.foundation.shape.CircleShape)
                        .background(colors.fillQuiet)
                        .clickable { menu = true }
                        .testTag("key_menu"),
                    contentAlignment = Alignment.Center
                ) {
                    app.openblocker.android.ui.components.GlyphIcon(Glyph.Ellipsis, colors.inkSecondary, size = 14.dp)
                }
                androidx.compose.material3.DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                    androidx.compose.material3.DropdownMenuItem(
                        text = { Text("Remove key", color = colors.danger) },
                        enabled = canDelete,
                        onClick = {
                            menu = false
                            confirming = true
                        }
                    )
                }
            }
        }
    }
    if (confirming) {
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { confirming = false },
            title = { Text("Remove \"${key.name}\"?") },
            text = { Text("It won't unblock this phone anymore.") },
            confirmButton = {
                androidx.compose.material3.TextButton(onClick = {
                    app.openblocker.android.data.KeyStore.remove(key.id)
                    confirming = false
                }) { Text("Remove", color = colors.danger) }
            },
            dismissButton = {
                androidx.compose.material3.TextButton(onClick = { confirming = false }) { Text("Cancel") }
            }
        )
    }
}

@Composable
fun RulesScreen(onBack: () -> Unit, onOpenAccessibility: () -> Unit) {
    val context = LocalContext.current
    val on = app.openblocker.android.util.AccessibilityUtil.isAccessibilityServiceEnabled(context)
    RulesContent(on = on, onBack = onBack, onOpenAccessibility = onOpenAccessibility)
}

@Composable
fun RulesContent(on: Boolean, onBack: () -> Unit, onOpenAccessibility: () -> Unit, modifier: Modifier = Modifier) {
    val colors = obColors()
    Column(modifier.fillMaxSize().background(colors.canvas).testTag("rules_screen")) {
        PushedHeader("My Rules", onBack)
        ScrollColumn {
            SettingsGroup {
                SettingsToggleRow(
                    Glyph.Hourglass,
                    "Accessibility",
                    checked = on,
                    onCheckedChange = { onOpenAccessibility() },
                    subtitle = "Android requires this to block apps and websites. Open Blocker doesn't read or track your usage.",
                    testTag = "rules_accessibility"
                )
            }
            Spacer(Modifier.height(Space.s))
            Text(
                "On iPhone these rows are Screen Time rules (prevent delete, block installs, purchases, adult sites). Android has no equivalent API, so blocking uses Accessibility and your modes instead.".asCopy(),
                style = ObText.subhead,
                color = colors.inkSecondary
            )
            Spacer(Modifier.height(Space.s))
            PrimaryButton("Open Accessibility settings", onClick = onOpenAccessibility)
            Spacer(Modifier.height(Space.l))
        }
    }
}
