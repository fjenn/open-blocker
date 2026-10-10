package app.openblocker.android.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import app.openblocker.android.ui.theme.LocalScreenshotCopy
import app.cash.paparazzi.DeviceConfig
import app.cash.paparazzi.Paparazzi
import app.openblocker.android.domain.BlockMode
import app.openblocker.android.domain.ModeTemplate
import app.openblocker.android.ui.permissions.PermissionCopyCatalog
import app.openblocker.android.ui.permissions.PermissionKind
import app.openblocker.android.domain.FocusInterval
import app.openblocker.android.ui.screens.ActivityTabContent
import app.openblocker.android.ui.screens.BlockTabContent
import app.openblocker.android.ui.screens.BlockUiState
import app.openblocker.android.ui.screens.EmergencyUnblockContent
import app.openblocker.android.ui.screens.HomeReadiness
import app.openblocker.android.ui.screens.OnboardingScreen
import app.openblocker.android.ui.screens.ModeEditContent
import app.openblocker.android.ui.screens.ModesSheetContent
import app.openblocker.android.ui.screens.PermissionDeniedSheetContent
import app.openblocker.android.ui.screens.PrivacyContent
import app.openblocker.android.ui.components.AppTab
import app.openblocker.android.ui.components.PhoneShell
import app.openblocker.android.data.StoredKey
import app.openblocker.android.ui.screens.AddKeyContent
import app.openblocker.android.ui.screens.KeyScanChooser
import app.openblocker.android.ui.screens.KeysContent
import app.openblocker.android.ui.screens.QrPasteContent
import app.openblocker.android.ui.screens.RulesContent
import app.openblocker.android.ui.screens.ScheduleTabContent
import app.openblocker.android.ui.screens.SettingsTabContent
import app.openblocker.android.ui.screens.TemplatePickerContent
import app.openblocker.android.ui.theme.AppAppearance
import app.openblocker.android.ui.theme.OpenBlockerTheme
import com.android.ide.common.rendering.api.SessionParams
import org.junit.Rule
import org.junit.Test
import java.util.Calendar
import java.util.Date
import java.util.TimeZone

class ScreenshotTest {
    @get:Rule
    val paparazzi = Paparazzi(
        deviceConfig = DeviceConfig.PIXEL_5.copy(softButtons = false),
        renderingMode = SessionParams.RenderingMode.NORMAL,
        showSystemUi = false
    )

    private val reset = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
        set(2027, Calendar.APRIL, 8, 12, 0, 0)
        set(Calendar.MILLISECOND, 0)
    }.time

    private fun snap(name: String, appearance: AppAppearance, content: @androidx.compose.runtime.Composable () -> Unit) {
        paparazzi.snapshot(name) {
            CompositionLocalProvider(LocalScreenshotCopy provides true) {
                OpenBlockerTheme(appearance) {
                    Box(Modifier.fillMaxSize().background(app.openblocker.android.ui.theme.obColors().canvas)) {
                        content()
                    }
                }
            }
        }
    }

    private fun snapTab(
        name: String,
        appearance: AppAppearance,
        tab: AppTab,
        content: @androidx.compose.runtime.Composable () -> Unit
    ) {
        paparazzi.snapshot(name) {
            CompositionLocalProvider(LocalScreenshotCopy provides true) {
                OpenBlockerTheme(appearance) {
                    PhoneShell(tab = tab) { content() }
                }
            }
        }
    }

    private fun idle() = BlockUiState(
        blocking = false,
        sessionSeconds = 0,
        todaySeconds = 32 * 60,
        modeName = "Deep work",
        modeSubtitle = "Blocks 12 apps · 2 websites",
        readiness = HomeReadiness.READY
    )

    private fun midHold() = idle().copy(holdProgress = 0.48f, holdHolding = true)

    private fun blocked() = BlockUiState(
        blocking = true,
        sessionSeconds = 30 * 60 + 3,
        todaySeconds = 32 * 60,
        modeName = "Deep work",
        modeSubtitle = "Blocks 12 apps · 2 websites",
        readiness = HomeReadiness.READY
    )

    @Test fun homeIdleDark() = snapTab("home_idle_dark", AppAppearance.DARK, AppTab.BLOCK) {
        BlockTabContent(idle(), {}, {}, interactiveKey = false)
    }

    @Test fun homeIdleLight() = snapTab("home_idle_light", AppAppearance.LIGHT, AppTab.BLOCK) {
        BlockTabContent(idle(), {}, {}, interactiveKey = false)
    }

    @Test fun homeHoldDark() = snapTab("home_hold_dark", AppAppearance.DARK, AppTab.BLOCK) {
        BlockTabContent(midHold(), {}, {}, interactiveKey = false)
    }

    @Test fun homeHoldLight() = snapTab("home_hold_light", AppAppearance.LIGHT, AppTab.BLOCK) {
        BlockTabContent(midHold(), {}, {}, interactiveKey = false)
    }

    @Test fun homeBlockedDark() = snapTab("home_blocked_dark", AppAppearance.DARK, AppTab.BLOCK) {
        BlockTabContent(blocked(), {}, {}, interactiveKey = false)
    }

    @Test fun homeBlockedLight() = snapTab("home_blocked_light", AppAppearance.LIGHT, AppTab.BLOCK) {
        BlockTabContent(blocked(), {}, {}, interactiveKey = false)
    }

    private fun demoIntervals(): List<FocusInterval> {
        val now = reset.time
        val day = 86_400_000L
        return listOf(
            FocusInterval(now - 32 * 60 * 1000, now - 60 * 1000),
            FocusInterval(now - day - 50 * 60 * 1000, now - day),
            FocusInterval(now - 2 * day - 80 * 60 * 1000, now - 2 * day),
            FocusInterval(now - 3 * day - 40 * 60 * 1000, now - 3 * day),
            FocusInterval(now - 5 * day - 70 * 60 * 1000, now - 5 * day)
        )
    }

    @Test fun activityDark() = snapTab("activity_dark", AppAppearance.DARK, AppTab.ACTIVITY) {
        ActivityTabContent(demoIntervals(), reset.time, false)
    }

    @Test fun activityLight() = snapTab("activity_light", AppAppearance.LIGHT, AppTab.ACTIVITY) {
        ActivityTabContent(demoIntervals(), reset.time, false)
    }

    @Test fun onboardingWelcomeDark() = snap("onboarding_welcome_dark", AppAppearance.DARK) {
        OnboardingScreen({}, {}, accessibilityOn = false, initialPage = 0)
    }

    @Test fun onboardingDark() = snap("onboarding_dark", AppAppearance.DARK) {
        OnboardingScreen({}, {}, accessibilityOn = false, initialPage = 1)
    }

    @Test fun onboardingLight() = snap("onboarding_light", AppAppearance.LIGHT) {
        OnboardingScreen({}, {}, accessibilityOn = false, initialPage = 1)
    }

    @Test fun templatesDark() = snap("templates_dark", AppAppearance.DARK) {
        TemplatePickerContent({}, {})
    }

    @Test fun templatesLight() = snap("templates_light", AppAppearance.LIGHT) {
        TemplatePickerContent({}, {})
    }

    @Test fun settingsDark() = snapTab("settings_dark", AppAppearance.DARK, AppTab.SETTINGS) {
        SettingsTabContent(
            appearance = AppAppearance.DARK,
            onAppearance = {},
            emergencyLeft = 5,
            notifyOn = false,
            countOn = true,
            onCount = {},
            keyCount = 1,
            rulesOn = true,
            version = "1.0.0",
            onKeys = {},
            onRules = {},
            onEmergency = {},
            onNotifications = {},
            onHelp = {},
            onContact = {},
            onAbout = {},
            onPrivacy = {}
        )
    }

    @Test fun settingsLight() = snapTab("settings_light", AppAppearance.LIGHT, AppTab.SETTINGS) {
        SettingsTabContent(
            appearance = AppAppearance.LIGHT,
            onAppearance = {},
            emergencyLeft = 5,
            notifyOn = false,
            countOn = true,
            onCount = {},
            keyCount = 1,
            rulesOn = true,
            version = "1.0.0",
            onKeys = {},
            onRules = {},
            onEmergency = {},
            onNotifications = {},
            onHelp = {},
            onContact = {},
            onAbout = {},
            onPrivacy = {}
        )
    }

    @Test fun homeNeedsKeyDark() = snapTab("home_needs_key_dark", AppAppearance.DARK, AppTab.BLOCK) {
        BlockTabContent(
            idle().copy(
                todaySeconds = 0,
                modeName = "Detox",
                modeSubtitle = "Blocks all apps",
                readiness = HomeReadiness.NEEDS_KEY
            ),
            {},
            {},
            interactiveKey = false
        )
    }

    @Test fun addKeyDark() = snap("add_key_dark", AppAppearance.DARK) {
        AddKeyContent(
            kind = StoredKey.Kind.QR,
            onKind = {},
            name = "",
            onName = {},
            secret = "",
            qrBitmap = null,
            nfcStatus = null,
            nfcGood = false,
            cardFirst = null,
            busy = false,
            onMakeQr = {},
            onShareQr = {},
            onScanTag = {},
            onScanCard = {},
            onClose = {},
            onSave = {}
        )
    }

    @Test fun addKeyNfcDark() = snap("add_key_nfc_dark", AppAppearance.DARK) {
        AddKeyContent(
            kind = StoredKey.Kind.NFC_TAG,
            onKind = {},
            name = "",
            onName = {},
            secret = "",
            qrBitmap = null,
            nfcStatus = null,
            nfcGood = false,
            cardFirst = null,
            busy = false,
            onMakeQr = {},
            onShareQr = {},
            onScanTag = {},
            onScanCard = {},
            onClose = {},
            onSave = {}
        )
    }

    @Test fun keysDark() = snapTab("keys_dark", AppAppearance.DARK, AppTab.SETTINGS) {
        KeysContent(
            keys = listOf(
                StoredKey(
                    name = "Fridge QR",
                    kind = StoredKey.Kind.QR,
                    secret = "openblocker://tag/v1/demo",
                    addedAtMs = reset.time - 5_000
                )
            ),
            blocking = false,
            onBack = {},
            onAdd = {}
        )
    }

    @Test fun scheduleEmptyDark() = snapTab("schedule_empty_dark", AppAppearance.DARK, AppTab.SCHEDULE) {
        ScheduleTabContent(emptyList(), {}, { _, _ -> }, {})
    }

    @Test fun homeToastDark() = snapTab("home_toast_dark", AppAppearance.DARK, AppTab.BLOCK) {
        BlockTabContent(blocked(), {}, {}, interactiveKey = false, toast = "Unblocking needs your key.")
    }

    @Test fun qrPasteDark() = snap("qr_paste_dark", AppAppearance.DARK) {
        QrPasteContent("", {}, {}, {})
    }

    @Test fun rulesDark() = snap("rules_dark", AppAppearance.DARK) {
        RulesContent(on = true, onBack = {}, onOpenAccessibility = {})
    }

    @Test fun chooserDark() = snap("chooser_dark", AppAppearance.DARK) {
        Box(Modifier.fillMaxSize()) {
            BlockTabContent(blocked(), {}, {}, interactiveKey = false)
            KeyScanChooser({}, {}, {})
        }
    }

    @Test fun emergencyDark() = snap("emergency_dark", AppAppearance.DARK) {
        EmergencyUnblockContent(5, reset, false, null, {}, {}, {}, {})
    }

    @Test fun emergencyLight() = snap("emergency_light", AppAppearance.LIGHT) {
        EmergencyUnblockContent(5, reset, false, null, {}, {}, {}, {})
    }

    @Test fun privacyDark() = snap("privacy_dark", AppAppearance.DARK) {
        PrivacyContent({}, {})
    }

    @Test fun privacyLight() = snap("privacy_light", AppAppearance.LIGHT) {
        PrivacyContent({}, {})
    }

    @Test fun permissionDark() = snap("permission_dark", AppAppearance.DARK) {
        PermissionDeniedSheetContent(PermissionCopyCatalog.of(PermissionKind.CAMERA), {}, {})
    }

    @Test fun permissionLight() = snap("permission_light", AppAppearance.LIGHT) {
        PermissionDeniedSheetContent(PermissionCopyCatalog.of(PermissionKind.CAMERA), {}, {})
    }

    private fun demoModes() = listOf(
        BlockMode(
            id = "deep",
            name = "Deep work",
            packages = (1..12).map { "app$it" }.toSet(),
            websites = listOf("youtube.com", "reddit.com")
        ),
        BlockMode(name = "Sleep", kind = BlockMode.Kind.ALLOW_ONLY, packages = setOf("c", "d", "e", "f")),
        ModeTemplate.DETOX.makeMode()
    )

    @Test fun modesDark() = snap("modes_dark", AppAppearance.DARK) {
        ModesSheetContent(
            modes = demoModes(),
            activeId = "deep",
            onClose = {},
            onNew = {},
            onSelect = {},
            onEdit = {}
        )
    }

    @Test fun modesLight() = snap("modes_light", AppAppearance.LIGHT) {
        ModesSheetContent(
            modes = demoModes(),
            activeId = "deep",
            onClose = {},
            onNew = {},
            onSelect = {},
            onEdit = {}
        )
    }

    @Test fun addKeyLight() = snap("add_key_light", AppAppearance.LIGHT) {
        AddKeyContent(
            kind = StoredKey.Kind.QR,
            onKind = {},
            name = "",
            onName = {},
            secret = "",
            qrBitmap = null,
            nfcStatus = null,
            nfcGood = false,
            cardFirst = null,
            busy = false,
            onMakeQr = {},
            onShareQr = {},
            onScanTag = {},
            onScanCard = {},
            onClose = {},
            onSave = {}
        )
    }

    @Test fun modeEditDark() = snap("mode_edit_dark", AppAppearance.DARK) {
        ModeEditContent(
            isNew = false,
            name = "Deep work",
            onName = {},
            kind = BlockMode.Kind.BLOCK,
            onKind = {},
            packages = emptySet(),
            websites = emptyList(),
            onPickApps = {},
            onAddWebsite = { false },
            onRemoveWebsite = {},
            scheduleSummary = null,
            addsSchedule = false,
            onAddsSchedule = {},
            onBackToTemplates = null,
            onClose = {},
            onSave = {}
        )
    }
}
