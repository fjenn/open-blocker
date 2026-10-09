package app.openblocker.android.debug

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast
import app.openblocker.android.data.AppearanceManager
import app.openblocker.android.data.ModeRepository
import app.openblocker.android.data.OnboardingStore
import app.openblocker.android.data.PreferencesManager
import app.openblocker.android.data.ScreenshotDirector
import app.openblocker.android.data.SessionHistory
import app.openblocker.android.data.SessionManager
import app.openblocker.android.domain.BlockMode
import app.openblocker.android.ui.theme.AppAppearance

/**
 * Debug-build only. Start or stop a blocking session from adb without NFC.
 * Not compiled into release.
 *
 * adb shell am broadcast -a app.openblocker.android.debug.START_SESSION \
 *   -n app.openblocker.android/.debug.DebugSessionReceiver
 * adb shell am broadcast -a app.openblocker.android.debug.END_SESSION \
 *   -n app.openblocker.android/.debug.DebugSessionReceiver
 * adb shell am broadcast -a app.openblocker.android.debug.PREP_SCREENSHOTS \
 *   --es appearance dark \
 *   -n app.openblocker.android/.debug.DebugSessionReceiver
 */
class DebugSessionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            ACTION_START -> {
                SessionManager.startSession()
                Log.i(TAG, "debug start session")
                Toast.makeText(context, "Blocking session started", Toast.LENGTH_SHORT).show()
            }
            ACTION_END -> {
                SessionManager.endSession()
                Log.i(TAG, "debug end session")
                Toast.makeText(context, "Blocking session ended", Toast.LENGTH_SHORT).show()
            }
            ACTION_PREP -> {
                val screen = intent.getStringExtra("screen") ?: "root"
                if (screen == "onboarding") {
                    OnboardingStore.clear()
                } else {
                    OnboardingStore.complete()
                }
                val appearance = AppAppearance.fromId(intent.getStringExtra("appearance"))
                AppearanceManager.setAppearance(appearance)
                if (PreferencesManager.getPairedKeyCount() == 0) {
                    PreferencesManager.addPairedQrPayload("openblocker://tag/v1/" + "ab".repeat(16))
                }
                val deep = ModeRepository.modes.value.find { it.name == "Deep work" }
                    ?: BlockMode(
                        name = "Deep work",
                        packages = (1..12).map { "demo.app.$it" }.toSet(),
                        websites = listOf("youtube.com", "reddit.com")
                    )
                if (ModeRepository.modes.value.none { it.id == deep.id }) {
                    ModeRepository.add(deep)
                } else {
                    ModeRepository.update(
                        deep.copy(
                            packages = if (deep.packages.size < 12) (1..12).map { "demo.app.$it" }.toSet() else deep.packages,
                            websites = if (deep.websites.isEmpty()) listOf("youtube.com", "reddit.com") else deep.websites
                        )
                    )
                }
                ModeRepository.setActive(ModeRepository.modes.value.first { it.name == "Deep work" })
                seedWeekIfEmpty()
                val hold = intent.getStringExtra("hold")?.toFloatOrNull()
                    ?: if (intent.hasExtra("hold")) intent.getFloatExtra("hold", -1f).takeIf { it >= 0f } else null
                if (intent.getBooleanExtra("blocking", false)) {
                    SessionManager.startSession()
                } else if (intent.getBooleanExtra("end", false)) {
                    SessionManager.endSession()
                }
                ScreenshotDirector.apply(
                    tab = intent.getStringExtra("tab"),
                    screen = screen,
                    onboardPage = intent.getIntExtra("page", if (screen == "onboarding") 1 else 0),
                    hold = hold,
                    forceReady = intent.getBooleanExtra("ready", true)
                )
                Log.i(TAG, "debug prep screenshots appearance=${appearance.id} tab=${intent.getStringExtra("tab")} screen=$screen")
            }
        }
    }

    private fun seedWeekIfEmpty() {
        if (SessionHistory.intervals().isNotEmpty()) return
        val now = System.currentTimeMillis()
        val day = 24L * 60 * 60 * 1000
        SessionHistory.add(now - 32 * 60 * 1000, now - 60 * 1000)
        SessionHistory.add(now - day - 50 * 60 * 1000, now - day)
        SessionHistory.add(now - 2 * day - 80 * 60 * 1000, now - 2 * day)
        SessionHistory.add(now - 3 * day - 40 * 60 * 1000, now - 3 * day)
        SessionHistory.add(now - 5 * day - 70 * 60 * 1000, now - 5 * day)
    }

    companion object {
        const val ACTION_START = "app.openblocker.android.debug.START_SESSION"
        const val ACTION_END = "app.openblocker.android.debug.END_SESSION"
        const val ACTION_PREP = "app.openblocker.android.debug.PREP_SCREENSHOTS"
        private const val TAG = "DebugSessionReceiver"
    }
}
