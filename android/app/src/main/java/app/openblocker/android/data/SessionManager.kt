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
    
    private val prefs: SharedPreferences by lazy {
        OpenBlockerApplication.getAppContext()
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    private val _isBlocking = MutableStateFlow(loadIsBlocking())
    val isBlocking: StateFlow<Boolean> = _isBlocking.asStateFlow()
    
    private val _sessionStartTime = MutableStateFlow(loadSessionStartTime())
    val sessionStartTime: StateFlow<Long> = _sessionStartTime.asStateFlow()
    
    private fun loadIsBlocking(): Boolean {
        return prefs.getBoolean(KEY_IS_BLOCKING, false)
    }
    
    private fun loadSessionStartTime(): Long {
        return prefs.getLong(KEY_SESSION_START_TIME, 0L)
    }
    
    fun startSession() {
        val now = System.currentTimeMillis()
        prefs.edit()
            .putBoolean(KEY_IS_BLOCKING, true)
            .putLong(KEY_SESSION_START_TIME, now)
            .commit()
        _isBlocking.value = true
        _sessionStartTime.value = now
    }
    
    fun endSession() {
        prefs.edit()
            .putBoolean(KEY_IS_BLOCKING, false)
            .putLong(KEY_SESSION_START_TIME, 0L)
            .commit()
        _isBlocking.value = false
        _sessionStartTime.value = 0L
    }
    
    fun getSessionDurationMillis(): Long {
        if (!_isBlocking.value) return 0L
        return System.currentTimeMillis() - _sessionStartTime.value
    }
}
