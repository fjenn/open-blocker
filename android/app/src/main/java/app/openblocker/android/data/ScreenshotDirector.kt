package app.openblocker.android.data

import app.openblocker.android.ui.components.AppTab
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

/** Debug screenshot cues. Release never writes this; the UI just reads defaults. */
data class ScreenshotCue(
    val tab: AppTab = AppTab.BLOCK,
    val screen: String = "root",
    val onboardPage: Int = 0,
    val hold: Float? = null,
    val forceReady: Boolean = false,
    val forceNeedsKey: Boolean = false,
    val askedAccessibility: Boolean = false,
    val tick: Int = 0
)

object ScreenshotDirector {
    private val _cue = MutableStateFlow(ScreenshotCue())
    val cue: StateFlow<ScreenshotCue> = _cue.asStateFlow()

    fun apply(
        tab: String? = null,
        screen: String? = null,
        onboardPage: Int? = null,
        hold: Float? = null,
        forceReady: Boolean? = null,
        forceNeedsKey: Boolean? = null,
        askedAccessibility: Boolean? = null
    ) {
        _cue.update { cur ->
            cur.copy(
                tab = tab?.let { parseTab(it) } ?: cur.tab,
                screen = screen ?: cur.screen,
                onboardPage = onboardPage ?: cur.onboardPage,
                hold = hold,
                forceReady = forceReady ?: cur.forceReady,
                forceNeedsKey = forceNeedsKey ?: cur.forceNeedsKey,
                askedAccessibility = askedAccessibility ?: cur.askedAccessibility,
                tick = cur.tick + 1
            )
        }
    }

    private fun parseTab(raw: String): AppTab = when (raw.lowercase()) {
        "schedule" -> AppTab.SCHEDULE
        "activity" -> AppTab.ACTIVITY
        "settings" -> AppTab.SETTINGS
        else -> AppTab.BLOCK
    }
}
