package app.openblocker.android.data

import android.content.Context
import android.content.SharedPreferences
import app.openblocker.android.OpenBlockerApplication

object PreferencesManager {
    
    private const val PREFS_NAME = "open_blocker_prefs"
    private const val KEY_BLOCKED_APPS = "blocked_apps"
    private const val KEY_PAIRED_TAG_IDS = "paired_tag_ids"
    private const val KEY_PAIRED_TAG_UIDS = "paired_tag_uids"
    private const val KEY_ANY_CARD_UIDS = "any_card_uids"
    private const val KEY_PAIRED_QR_PAYLOADS = "paired_qr_payloads"
    
    private val prefs: SharedPreferences by lazy {
        OpenBlockerApplication.getAppContext()
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    fun getBlockedApps(): Set<String> {
        return prefs.getStringSet(KEY_BLOCKED_APPS, emptySet()) ?: emptySet()
    }
    
    fun setBlockedApps(apps: Set<String>) {
        prefs.edit().putStringSet(KEY_BLOCKED_APPS, HashSet(apps)).commit()
    }
    
    fun addBlockedApp(packageName: String) {
        val current = getBlockedApps().toMutableSet()
        current.add(packageName)
        setBlockedApps(current)
    }
    
    fun removeBlockedApp(packageName: String) {
        val current = getBlockedApps().toMutableSet()
        current.remove(packageName)
        setBlockedApps(current)
    }
    
    fun getPairedTagIds(): Set<String> {
        return prefs.getStringSet(KEY_PAIRED_TAG_IDS, emptySet()) ?: emptySet()
    }
    
    fun addPairedTagId(tagId: String) {
        val current = getPairedTagIds().toMutableSet()
        current.add(tagId)
        prefs.edit().putStringSet(KEY_PAIRED_TAG_IDS, current).apply()
    }

    fun removePairedTagId(tagId: String) {
        val current = getPairedTagIds().toMutableSet()
        current.remove(tagId)
        prefs.edit().putStringSet(KEY_PAIRED_TAG_IDS, current).apply()
    }
    
    fun getPairedTagUids(): Set<String> {
        return prefs.getStringSet(KEY_PAIRED_TAG_UIDS, emptySet()) ?: emptySet()
    }
    
    fun addPairedTagUid(uid: String) {
        val current = getPairedTagUids().toMutableSet()
        current.add(uid)
        prefs.edit().putStringSet(KEY_PAIRED_TAG_UIDS, current).apply()
    }

    fun removePairedTagUid(uid: String) {
        val current = getPairedTagUids().toMutableSet()
        current.remove(uid)
        prefs.edit().putStringSet(KEY_PAIRED_TAG_UIDS, current).apply()
    }
    
    fun getAnyCardUids(): Set<String> {
        return prefs.getStringSet(KEY_ANY_CARD_UIDS, emptySet()) ?: emptySet()
    }
    
    fun addAnyCardUid(uid: String) {
        val current = getAnyCardUids().toMutableSet()
        current.add(uid)
        prefs.edit().putStringSet(KEY_ANY_CARD_UIDS, current).apply()
    }

    fun removeAnyCardUid(uid: String) {
        val current = getAnyCardUids().toMutableSet()
        current.remove(uid)
        prefs.edit().putStringSet(KEY_ANY_CARD_UIDS, current).apply()
    }
    
    fun isUidPaired(uid: String): Boolean {
        return getPairedTagUids().contains(uid) || getAnyCardUids().contains(uid)
    }

    fun getPairedQrPayloads(): Set<String> {
        return prefs.getStringSet(KEY_PAIRED_QR_PAYLOADS, emptySet()) ?: emptySet()
    }

    fun addPairedQrPayload(payload: String) {
        val current = getPairedQrPayloads().toMutableSet()
        current.add(payload)
        prefs.edit().putStringSet(KEY_PAIRED_QR_PAYLOADS, HashSet(current)).commit()
    }

    fun removePairedQrPayload(payload: String) {
        val current = getPairedQrPayloads().toMutableSet()
        current.remove(payload)
        prefs.edit().putStringSet(KEY_PAIRED_QR_PAYLOADS, HashSet(current)).commit()
    }

    fun getPairedKeyCount(): Int {
        val named = try {
            KeyStore.count()
        } catch (_: Exception) {
            0
        }
        if (named > 0) return named
        return getPairedTagIds().size + getPairedTagUids().size +
            getAnyCardUids().size + getPairedQrPayloads().size
    }
}
