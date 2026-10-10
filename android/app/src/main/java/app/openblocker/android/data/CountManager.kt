package app.openblocker.android.data

import android.content.Context
import android.content.SharedPreferences
import app.openblocker.android.BuildConfig
import app.openblocker.android.OpenBlockerApplication
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID

object CountManager {
    
    const val enabledByDefault = true
    const val SUMMARY = "Helps us count users. No personal data."
    const val DISCLOSURE = "One ping after your first block, with a random ID and the app version. Nothing about you or your apps."
    
    private const val PREFS_NAME = "count_prefs"
    private const val KEY_COUNT_ME_ENABLED = "count_me_enabled"
    private const val KEY_INSTALL_ID = "install_id"
    private const val KEY_FIRST_BLOCK_SENT = "first_block_sent"
    private const val KEY_SEND_PENDING = "send_pending"
    
    private val prefs: SharedPreferences by lazy {
        OpenBlockerApplication.getAppContext()
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    fun isPreferenceEnabled(): Boolean {
        return prefs.getBoolean(KEY_COUNT_ME_ENABLED, enabledByDefault)
    }

    fun isCountingEnabled(): Boolean {
        return BuildConfig.COUNT_ENABLED && isPreferenceEnabled()
    }
    
    fun setCountingEnabled(enabled: Boolean) {
        prefs.edit().putBoolean(KEY_COUNT_ME_ENABLED, enabled).apply()
        
        if (enabled) {
            ensureInstallId()
        }
    }
    
    private fun ensureInstallId() {
        if (prefs.getString(KEY_INSTALL_ID, null) == null) {
            val installId = UUID.randomUUID().toString()
            prefs.edit().putString(KEY_INSTALL_ID, installId).apply()
        }
    }
    
    fun recordFirstBlock() {
        if (!isCountingEnabled()) return
        if (prefs.getBoolean(KEY_FIRST_BLOCK_SENT, false)) return
        
        prefs.edit().putBoolean(KEY_SEND_PENDING, true).apply()
        sendFirstBlockEvent()
    }
    
    fun retrySendIfPending() {
        if (!isCountingEnabled()) return
        if (!prefs.getBoolean(KEY_SEND_PENDING, false)) return
        if (prefs.getBoolean(KEY_FIRST_BLOCK_SENT, false)) return
        
        sendFirstBlockEvent()
    }
    
    private fun sendFirstBlockEvent() {
        if (!BuildConfig.COUNT_ENABLED) return
        
        val installId = prefs.getString(KEY_INSTALL_ID, null) ?: return
        
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val url = URL("${BuildConfig.COUNT_URL}/rest/v1/pings")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.doOutput = true
                conn.setRequestProperty("Content-Type", "application/json")
                conn.setRequestProperty("apikey", BuildConfig.COUNT_KEY)
                conn.setRequestProperty("Authorization", "Bearer ${BuildConfig.COUNT_KEY}")
                conn.setRequestProperty("Prefer", "return=minimal")
                
                val json = JSONObject()
                json.put("install_id", installId)
                json.put("event", "first_block")
                json.put("app_version", BuildConfig.VERSION_NAME)
                
                conn.outputStream.use { os ->
                    os.write(json.toString().toByteArray())
                }
                
                val responseCode = conn.responseCode
                if (responseCode in 200..299) {
                    prefs.edit()
                        .putBoolean(KEY_FIRST_BLOCK_SENT, true)
                        .putBoolean(KEY_SEND_PENDING, false)
                        .apply()
                }
            } catch (e: Exception) {
                // Silent failure, will retry on next app open
            }
        }
    }
}
