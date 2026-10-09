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
import app.openblocker.android.ui.screens.BlockTabContent
import app.openblocker.android.ui.screens.BlockUiState
import app.openblocker.android.ui.screens.EmergencyUnblockContent
import app.openblocker.android.ui.screens.HomeReadiness
import app.openblocker.android.ui.screens.ModesSheetContent
import app.openblocker.android.ui.screens.PermissionDeniedSheetContent
import app.openblocker.android.ui.screens.PrivacyContent
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

    @Test fun homeIdleDark() = snap("home_idle_dark", AppAppearance.DARK) {
        BlockTabContent(idle(), {}, {}, interactiveKey = false)
    }

    @Test fun homeIdleLight() = snap("home_idle_light", AppAppearance.LIGHT) {
        BlockTabContent(idle(), {}, {}, interactiveKey = false)
    }

    @Test fun homeHoldDark() = snap("home_hold_dark", AppAppearance.DARK) {
        BlockTabContent(midHold(), {}, {}, interactiveKey = false)
    }

    @Test fun homeHoldLight() = snap("home_hold_light", AppAppearance.LIGHT) {
        BlockTabContent(midHold(), {}, {}, interactiveKey = false)
    }

    @Test fun homeBlockedDark() = snap("home_blocked_dark", AppAppearance.DARK) {
        BlockTabContent(blocked(), {}, {}, interactiveKey = false)
    }

    @Test fun homeBlockedLight() = snap("home_blocked_light", AppAppearance.LIGHT) {
        BlockTabContent(blocked(), {}, {}, interactiveKey = false)
    }

    @Test fun templatesDark() = snap("templates_dark", AppAppearance.DARK) {
        TemplatePickerContent({}, {})
    }

    @Test fun templatesLight() = snap("templates_light", AppAppearance.LIGHT) {
        TemplatePickerContent({}, {})
    }

    @Test fun settingsDark() = snap("settings_dark", AppAppearance.DARK) {
        SettingsTabContent(
            appearance = AppAppearance.DARK,
            onAppearance = {},
            emergencyLeft = 5,
            notifyOn = false,
            countOn = true,
            onCount = {},
            keyCount = 1,
            version = "1.0.0",
            onKeys = {},
            onEmergency = {},
            onNotifications = {},
            onHelp = {},
            onContact = {},
            onAbout = {},
            onPrivacy = {}
        )
    }

    @Test fun settingsLight() = snap("settings_light", AppAppearance.LIGHT) {
        SettingsTabContent(
            appearance = AppAppearance.LIGHT,
            onAppearance = {},
            emergencyLeft = 5,
            notifyOn = false,
            countOn = true,
            onCount = {},
            keyCount = 1,
            version = "1.0.0",
            onKeys = {},
            onEmergency = {},
            onNotifications = {},
            onHelp = {},
            onContact = {},
            onAbout = {},
            onPrivacy = {}
        )
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

    @Test fun modesDark() = snap("modes_dark", AppAppearance.DARK) {
        ModesSheetContent(
            modes = listOf(
                BlockMode(name = "Deep work", packages = setOf("a", "b")),
                BlockMode(name = "Sleep", kind = BlockMode.Kind.ALLOW_ONLY, packages = setOf("c", "d", "e")),
                ModeTemplate.DETOX.makeMode()
            ),
            activeId = null,
            onClose = {},
            onNew = {},
            onSelect = {},
            onEdit = {}
        )
    }
}
