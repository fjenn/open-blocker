package app.openblocker.android.data

import android.content.Context
import android.content.SharedPreferences
import app.openblocker.android.OpenBlockerApplication

object DebugDataManager {
    
    private const val PREFS_NAME = "debug_prefs"
    private const val KEY_LAST_TAG_UID = "last_tag_uid"
    private const val KEY_LAST_TAG_ID = "last_tag_id"
    private const val KEY_LAST_TAG_PACKAGE = "last_tag_package"
    private const val KEY_LAST_SCAN_TIME = "last_scan_time"
    private const val KEY_LAST_SCAN_SUCCESS = "last_scan_success"
    private const val KEY_LAST_SCAN_ERROR = "last_scan_error"
    
    private val prefs: SharedPreferences by lazy {
        OpenBlockerApplication.getAppContext()
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    fun recordTagScan(
        uid: String,
        tagId: String?,
        packageName: String?,
        success: Boolean,
        error: String?
    ) {
        prefs.edit()
            .putString(KEY_LAST_TAG_UID, uid)
            .putString(KEY_LAST_TAG_ID, tagId)
            .putString(KEY_LAST_TAG_PACKAGE, packageName)
            .putLong(KEY_LAST_SCAN_TIME, System.currentTimeMillis())
            .putBoolean(KEY_LAST_SCAN_SUCCESS, success)
            .putString(KEY_LAST_SCAN_ERROR, error)
            .apply()
    }
    
    fun getLastTagUid(): String? = prefs.getString(KEY_LAST_TAG_UID, null)
    fun getLastTagId(): String? = prefs.getString(KEY_LAST_TAG_ID, null)
    fun getLastTagPackage(): String? = prefs.getString(KEY_LAST_TAG_PACKAGE, null)
    fun getLastScanTime(): Long = prefs.getLong(KEY_LAST_SCAN_TIME, 0L)
    fun getLastScanSuccess(): Boolean = prefs.getBoolean(KEY_LAST_SCAN_SUCCESS, false)
    fun getLastScanError(): String? = prefs.getString(KEY_LAST_SCAN_ERROR, null)
}
