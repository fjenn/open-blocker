package app.openblocker.android.data

import android.content.Context
import android.content.SharedPreferences
import app.openblocker.android.OpenBlockerApplication
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object SessionManager {

    private const val PREFS_NAME = "session_prefs"
    private const val KEY_IS_BLOCKING = "is_blocking"
    private const val KEY_SESSION_START_TIME = "session_start_time"
    private const val KEY_SOURCE = "session_source"

    const val SOURCE_HOLD = "hold"
    const val SOURCE_KEY = "key"
    const val SOURCE_SCHEDULE = "schedule"

    private val prefs: SharedPreferences by lazy {
        OpenBlockerApplication.getAppContext()
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private val _isBlocking = MutableStateFlow(loadIsBlocking())
    val isBlocking: StateFlow<Boolean> = _isBlocking.asStateFlow()

    private val _sessionStartTime = MutableStateFlow(loadSessionStartTime())
    val sessionStartTime: StateFlow<Long> = _sessionStartTime.asStateFlow()

    private fun loadIsBlocking(): Boolean = prefs.getBoolean(KEY_IS_BLOCKING, false)
    private fun loadSessionStartTime(): Long = prefs.getLong(KEY_SESSION_START_TIME, 0L)

    fun startSession(source: String = SOURCE_HOLD) {
        if (_isBlocking.value) return
        val now = System.currentTimeMillis()
        prefs.edit()
            .putBoolean(KEY_IS_BLOCKING, true)
            .putLong(KEY_SESSION_START_TIME, now)
            .putString(KEY_SOURCE, source)
            .commit()
        _isBlocking.value = true
        _sessionStartTime.value = now
        CountManager.recordFirstBlock()
    }

    fun endSession() {
        val start = _sessionStartTime.value
        val now = System.currentTimeMillis()
        if (_isBlocking.value && start > 0) {
            SessionHistory.add(start, now)
            SessionNotify.onBlockEnded()
        }
        prefs.edit()
            .putBoolean(KEY_IS_BLOCKING, false)
            .putLong(KEY_SESSION_START_TIME, 0L)
            .putString(KEY_SOURCE, "")
            .commit()
        _isBlocking.value = false
        _sessionStartTime.value = 0L
    }

    fun source(): String = prefs.getString(KEY_SOURCE, "") ?: ""

    fun getSessionDurationMillis(): Long {
        if (!_isBlocking.value) return 0L
        return System.currentTimeMillis() - _sessionStartTime.value
    }

    fun todayBlockedSeconds(): Long {
        val open = if (_isBlocking.value) _sessionStartTime.value else 0L
        return SessionHistory.todayBlockedMs(openStartMs = open) / 1000
    }
}
