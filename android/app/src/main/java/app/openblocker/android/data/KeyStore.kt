package app.openblocker.android.data

import android.content.Context
import app.openblocker.android.OpenBlockerApplication
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

data class StoredKey(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val kind: Kind,
    val secret: String,
    val addedAtMs: Long = System.currentTimeMillis()
) {
    enum class Kind(val raw: String, val title: String, val placeholder: String) {
        QR("qr", "QR code", "Fridge QR"),
        NFC_TAG("openBlockerTag", "NFC tag", "Desk tag"),
        CARD("card", "NFC card", "Gym card");

        companion object {
            fun fromRaw(raw: String): Kind = entries.find { it.raw == raw } ?: QR
        }
    }

    val glyphKind: Kind get() = kind
}

object KeyCodec {
    fun encode(keys: List<StoredKey>): String {
        val array = JSONArray()
        keys.forEach { key ->
            array.put(
                JSONObject()
                    .put("id", key.id)
                    .put("name", key.name)
                    .put("kind", key.kind.raw)
                    .put("secret", key.secret)
                    .put("addedAtMs", key.addedAtMs)
            )
        }
        return array.toString()
    }

    fun decode(raw: String?): List<StoredKey> {
        if (raw.isNullOrBlank()) return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { i ->
                val obj = array.getJSONObject(i)
                StoredKey(
                    id = obj.getString("id"),
                    name = obj.getString("name"),
                    kind = StoredKey.Kind.fromRaw(obj.optString("kind")),
                    secret = obj.getString("secret"),
                    addedAtMs = obj.optLong("addedAtMs", 0L)
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun addedAgo(addedAtMs: Long, nowMs: Long = System.currentTimeMillis()): String {
        val seconds = ((nowMs - addedAtMs).coerceAtLeast(0L)) / 1000L
        return when {
            seconds < 45 -> "just now"
            seconds < 90 -> "1 minute ago"
            seconds < 45 * 60 -> "${seconds / 60} minutes ago"
            seconds < 90 * 60 -> "1 hour ago"
            seconds < 36 * 3600 -> "${seconds / 3600} hours ago"
            seconds < 60 * 3600 -> "1 day ago"
            else -> "${seconds / 86400} days ago"
        }
    }
}

object KeyStore {
    const val MOCK_NFC_UID = "04a1b2c3d4e5f6"

    private const val PREFS = "key_store"
    private const val KEY_KEYS = "keys"

    private val prefs by lazy {
        OpenBlockerApplication.getAppContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }

    private val _keys = MutableStateFlow(load())
    val keys: StateFlow<List<StoredKey>> = _keys.asStateFlow()

    fun all(): List<StoredKey> = _keys.value

    fun count(): Int = _keys.value.size

    fun hasQr(): Boolean = _keys.value.any { it.kind == StoredKey.Kind.QR }

    fun hasNfc(): Boolean = _keys.value.any { it.kind != StoredKey.Kind.QR }

    fun qrPayloads(): Set<String> = _keys.value.filter { it.kind == StoredKey.Kind.QR }.map { it.secret }.toSet()

    fun nfcSecrets(): Set<String> = _keys.value.filter { it.kind != StoredKey.Kind.QR }.map { it.secret.lowercase() }.toSet()

    fun add(key: StoredKey) {
        val next = _keys.value.filterNot { it.secret.equals(key.secret, ignoreCase = true) && it.kind == key.kind } + key
        persist(next)
        syncLegacy(key)
    }

    fun remove(id: String) {
        val gone = _keys.value.find { it.id == id }
        persist(_keys.value.filterNot { it.id == id })
        if (gone != null) dropLegacy(gone)
    }

    fun clear() {
        persist(emptyList())
    }

    private fun load(): List<StoredKey> {
        val stored = KeyCodec.decode(prefs.getString(KEY_KEYS, null))
        if (stored.isNotEmpty()) return stored
        return migrateLegacy()
    }

    private fun migrateLegacy(): List<StoredKey> {
        val now = System.currentTimeMillis()
        val migrated = mutableListOf<StoredKey>()
        PreferencesManager.getPairedQrPayloads().forEach { payload ->
            migrated += StoredKey(name = "QR key", kind = StoredKey.Kind.QR, secret = payload, addedAtMs = now)
        }
        PreferencesManager.getPairedTagUids().forEach { uid ->
            migrated += StoredKey(name = "NFC tag", kind = StoredKey.Kind.NFC_TAG, secret = uid, addedAtMs = now)
        }
        PreferencesManager.getPairedTagIds().forEach { id ->
            migrated += StoredKey(name = "NFC tag", kind = StoredKey.Kind.NFC_TAG, secret = id, addedAtMs = now)
        }
        PreferencesManager.getAnyCardUids().forEach { uid ->
            migrated += StoredKey(name = "Card", kind = StoredKey.Kind.CARD, secret = uid, addedAtMs = now)
        }
        if (migrated.isNotEmpty()) {
            prefs.edit().putString(KEY_KEYS, KeyCodec.encode(migrated)).commit()
        }
        return migrated
    }

    private fun persist(next: List<StoredKey>) {
        _keys.value = next
        prefs.edit().putString(KEY_KEYS, KeyCodec.encode(next)).commit()
    }

    private fun syncLegacy(key: StoredKey) {
        when (key.kind) {
            StoredKey.Kind.QR -> PreferencesManager.addPairedQrPayload(key.secret)
            StoredKey.Kind.NFC_TAG -> {
                if (key.secret.length == 32) {
                    PreferencesManager.addPairedTagId(key.secret)
                }
                PreferencesManager.addPairedTagUid(key.secret)
            }
            StoredKey.Kind.CARD -> PreferencesManager.addAnyCardUid(key.secret)
        }
    }

    private fun dropLegacy(key: StoredKey) {
        when (key.kind) {
            StoredKey.Kind.QR -> PreferencesManager.removePairedQrPayload(key.secret)
            StoredKey.Kind.NFC_TAG -> {
                PreferencesManager.removePairedTagId(key.secret)
                PreferencesManager.removePairedTagUid(key.secret)
            }
            StoredKey.Kind.CARD -> PreferencesManager.removeAnyCardUid(key.secret)
        }
    }
}
