package app.openblocker.android.data

import android.content.Context
import android.content.SharedPreferences
import app.openblocker.android.OpenBlockerApplication
import app.openblocker.android.domain.EmergencyAllowance
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Date

object EmergencyUnblockManager {
    private const val PREFS_NAME = "emergency_prefs"
    private const val KEY_REMAINING = "remaining"
    private const val KEY_PERIOD_START = "period_start_ms"

    data class Status(val remaining: Int, val resetDate: Date)

    private val _remaining = MutableStateFlow(EmergencyAllowance.maxCount)
    val remaining: StateFlow<Int> = _remaining.asStateFlow()

    private val prefs: SharedPreferences by lazy {
        OpenBlockerApplication.getAppContext()
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun status(now: Date = Date()): Status {
        val allowance = load(now)
        _remaining.value = allowance.remaining
        return Status(allowance.remaining, allowance.resetDate())
    }

    fun useOne(now: Date = Date()): Boolean {
        val next = load(now).renewed(now).usingOne() ?: return false
        save(next)
        return true
    }

    fun renewIfDue(now: Date = Date()) {
        val stored = load(now)
        val renewed = stored.renewed(now)
        if (renewed != stored || !prefs.contains(KEY_PERIOD_START)) {
            save(renewed)
        }
    }

    fun resetToFull() {
        save(EmergencyAllowance.full(Date()))
    }

    private fun load(now: Date): EmergencyAllowance {
        val remaining = prefs.getInt(KEY_REMAINING, EmergencyAllowance.maxCount)
            .coerceIn(0, EmergencyAllowance.maxCount)
        val startMs = prefs.getLong(KEY_PERIOD_START, -1L)
        val start = if (startMs > 0) Date(startMs) else now
        return EmergencyAllowance(remaining, start)
    }

    private fun save(allowance: EmergencyAllowance) {
        prefs.edit()
            .putInt(KEY_REMAINING, allowance.remaining)
            .putLong(KEY_PERIOD_START, allowance.periodStart.time)
            .apply()
        _remaining.value = allowance.remaining
    }
}
