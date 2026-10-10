package app.openblocker.android.nfc

import android.content.Context
import android.nfc.NdefMessage
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.nfc.tech.NdefFormatable
import app.openblocker.android.data.DebugDataManager
import app.openblocker.android.data.PreferencesManager
import app.openblocker.android.format.OpenBlockerFormat
import app.openblocker.android.key.KeyMatcher
import app.openblocker.android.key.ScannedKey

class NfcHandler {
    
    fun handleTag(context: Context, tag: Tag) {
        val uid = tag.id?.let { OpenBlockerFormat.bytesToHex(it) } ?: return
        
        val ndefMessage = readNdefMessage(tag)
        var tagId: String? = null
        var packageName: String? = null
        var success = false
        var error: String? = null
        
        try {
                if (ndefMessage != null) {
                    val tagData = try {
                        OpenBlockerFormat.decode(ndefMessage.toByteArray())
                    } catch (e: Exception) {
                        error = "Failed to decode: ${e.message}"
                        null
                    }
                    
                    if (tagData != null) {
                        tagId = OpenBlockerFormat.bytesToHex(tagData.tagId)
                        packageName = tagData.androidPackage
                        
                        if (KeyMatcher.isPaired(ScannedKey.OpenBlockerTag(tagId))) {
                            KeyMatcher.applyPairedKey(context)
                            success = true
                        } else {
                            error = "Tag ID not paired"
                            KeyMatcher.reject(context)
                        }
                    } else if (KeyMatcher.isPaired(ScannedKey.Uid(uid))) {
                        KeyMatcher.applyPairedKey(context)
                        success = true
                    } else {
                        error = error ?: "Unknown tag format"
                        KeyMatcher.reject(context)
                    }
                } else if (KeyMatcher.isPaired(ScannedKey.Uid(uid))) {
                    KeyMatcher.applyPairedKey(context)
                    success = true
                } else {
                    error = "No NDEF data and UID not paired"
                    KeyMatcher.reject(context)
                }
        } catch (e: Exception) {
            error = "Exception: ${e.message}"
            KeyMatcher.reject(context, "Error reading tag")
        }
        
        DebugDataManager.recordTagScan(uid, tagId, packageName, success, error)
    }
    
    fun writeTag(tag: Tag, packageName: String): Boolean {
        val tagData = OpenBlockerFormat.TagData(
            tagId = OpenBlockerFormat.generateTagId(),
            androidPackage = packageName
        )
        
        val ndefMessage = OpenBlockerFormat.encode(tagData)
        val androidNdefMessage = NdefMessage(ndefMessage)
        
        val ndef = Ndef.get(tag)
        if (ndef != null) {
            return try {
                ndef.connect()
                ndef.writeNdefMessage(androidNdefMessage)
                ndef.close()
                
                val tagIdHex = OpenBlockerFormat.bytesToHex(tagData.tagId)
                PreferencesManager.addPairedTagId(tagIdHex)
                true
            } catch (e: Exception) {
                false
            }
        }
        
        val format = NdefFormatable.get(tag)
        if (format != null) {
            return try {
                format.connect()
                format.format(androidNdefMessage)
                format.close()
                
                val tagIdHex = OpenBlockerFormat.bytesToHex(tagData.tagId)
                PreferencesManager.addPairedTagId(tagIdHex)
                true
            } catch (e: Exception) {
                false
            }
        }
        
        return false
    }
    
    fun pairByUid(tag: Tag): Boolean {
        val uid = tag.id?.let { OpenBlockerFormat.bytesToHex(it) } ?: return false
        PreferencesManager.addPairedTagUid(uid)
        return true
    }
    
    private fun readNdefMessage(tag: Tag): NdefMessage? {
        val ndef = Ndef.get(tag) ?: return null
        
        return try {
            ndef.connect()
            val message = ndef.ndefMessage
            ndef.close()
            message
        } catch (e: Exception) {
            null
        }
    }
}
