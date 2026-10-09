package app.openblocker.android.data

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import app.openblocker.android.OpenBlockerApplication
import java.util.*

/**
 * Five emergency unblocks per six-month period. When the period runs out
 * the allowance goes back to five and a new period starts.
 * Stored in EncryptedSharedPreferences (survives reinstalls if possible).
 */
object EmergencyUnblockManager {
    
    private const val MAX_COUNT = 5
    private const val PERIOD_MONTHS = 6
    
    private const val PREFS_NAME = "emergency_prefs"
    private const val KEY_REMAINING = "remaining"
    private const val KEY_PERIOD_START = "period_start_ms"
    
    private val prefs: SharedPreferences by lazy {
        try {
            val masterKey = MasterKey.Builder(OpenBlockerApplication.getAppContext())
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            
            EncryptedSharedPreferences.create(
                OpenBlockerApplication.getAppContext(),
                PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            // Fallback to regular SharedPreferences if EncryptedSharedPreferences fails
            OpenBlockerApplication.getAppContext()
                .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
    }
    
    data class Status(
        val remaining: Int,
        val resetDate: Date
    )
    
    private data class Allowance(
        val remaining: Int,
        val periodStart: Date
    ) {
        fun resetDate(calendar: Calendar = Calendar.getInstance()): Date {
            val cal = calendar.clone() as Calendar
            cal.time = periodStart
            cal.add(Calendar.MONTH, PERIOD_MONTHS)
            return cal.time
        }
        
        fun renewed(now: Date, calendar: Calendar = Calendar.getInstance()): Allowance {
            return if (now >= resetDate(calendar)) {
                Allowance(remaining = MAX_COUNT, periodStart = now)
            } else {
                this
            }
        }
        
        fun usingOne(): Allowance? {
            return if (remaining > 0) {
                Allowance(remaining = remaining - 1, periodStart = periodStart)
            } else {
                null
            }
        }
    }
    
    /**
     * The current allowance and when it resets.
     */
    fun status(): Status {
        val allowance = load()
        return Status(
            remaining = allowance.remaining,
            resetDate = allowance.resetDate()
        )
    }
    
    /**
     * Use one emergency unblock. Returns true if there was one to use.
     */
    fun useOne(now: Date = Date()): Boolean {
        val current = load(now).renewed(now)
        val next = current.usingOne() ?: return false
        save(next)
        return load(now) == next
    }
    
    /**
     * Call on launch and when the app comes back: starts the first period,
     * and resets to five once six months have passed.
     */
    fun renewIfDue(now: Date = Date()) {
        val stored = load(now)
        val renewed = stored.renewed(now)
        if (renewed != stored || !prefs.contains(KEY_PERIOD_START)) {
            save(renewed)
        }
    }
    
    /**
     * Demo and testing: reset to full allowance.
     */
    fun resetToFull() {
        save(Allowance(remaining = MAX_COUNT, periodStart = Date()))
    }
    
    private fun load(now: Date = Date()): Allowance {
        val remaining = prefs.getInt(KEY_REMAINING, MAX_COUNT)
        val periodStartMs = prefs.getLong(KEY_PERIOD_START, -1L)
        val periodStart = if (periodStartMs > 0) {
            Date(periodStartMs)
        } else {
            now
        }
        return Allowance(
            remaining = remaining.coerceIn(0, MAX_COUNT),
            periodStart = periodStart
        )
    }
    
    private fun save(allowance: Allowance) {
        prefs.edit()
            .putInt(KEY_REMAINING, allowance.remaining)
            .putLong(KEY_PERIOD_START, allowance.periodStart.time)
            .apply()
    }
}
