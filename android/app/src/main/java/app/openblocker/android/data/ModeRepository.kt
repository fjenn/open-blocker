package app.openblocker.android.data

import android.content.Context
import app.openblocker.android.OpenBlockerApplication
import app.openblocker.android.domain.BlockMode
import app.openblocker.android.domain.ModeDefaults
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONObject

object ModeRepository {
    private const val PREFS = "mode_prefs"
    private const val KEY_MODES = "modes"
    private const val KEY_ACTIVE = "active_mode_id"

    private val prefs by lazy {
        OpenBlockerApplication.getAppContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }

    private val _modes = MutableStateFlow(loadModes())
    val modes: StateFlow<List<BlockMode>> = _modes.asStateFlow()

    private val _activeModeId = MutableStateFlow(prefs.getString(KEY_ACTIVE, null))
    val activeModeId: StateFlow<String?> = _activeModeId.asStateFlow()

    fun seedIfNeeded() {
        val seeded = ModeDefaults.seeded(_modes.value, _activeModeId.value) ?: return
        _modes.value = seeded.first
        _activeModeId.value = seeded.second
        persist()
        applyActiveToBlockList()
    }

    fun activeMode(): BlockMode? {
        val id = _activeModeId.value
        return _modes.value.find { it.id == id } ?: _modes.value.firstOrNull()
    }

    fun setActive(mode: BlockMode) {
        _activeModeId.value = mode.id
        persist()
        applyActiveToBlockList()
    }

    fun add(mode: BlockMode) {
        _modes.value = _modes.value + mode
        if (_activeModeId.value == null) _activeModeId.value = mode.id
        persist()
        applyActiveToBlockList()
    }

    fun update(mode: BlockMode) {
        _modes.value = _modes.value.map { if (it.id == mode.id) mode else it }
        persist()
        applyActiveToBlockList()
    }

    fun delete(mode: BlockMode) {
        if (mode.isDefault) return
        _modes.value = _modes.value.filterNot { it.id == mode.id }
        if (_activeModeId.value == mode.id) {
            _activeModeId.value = _modes.value.firstOrNull()?.id
        }
        persist()
        applyActiveToBlockList()
    }

    fun applyActiveToBlockList() {
        val mode = activeMode() ?: return
        if (mode.kind == BlockMode.Kind.BLOCK) {
            PreferencesManager.setBlockedApps(mode.packages)
        }
    }

    fun shouldBlockPackage(packageName: String, selfPackage: String): Boolean {
        val mode = activeMode()
        return mode?.shouldBlock(packageName, selfPackage)
            ?: PreferencesManager.getBlockedApps().contains(packageName)
    }

    fun shouldBlockHost(rawUrlOrHost: String): Boolean {
        return activeMode()?.shouldBlockHost(rawUrlOrHost) ?: false
    }

    private fun persist() {
        val array = JSONArray()
        _modes.value.forEach { mode ->
            val obj = JSONObject()
            obj.put("id", mode.id)
            obj.put("name", mode.name)
            obj.put("kind", mode.kind.raw)
            obj.put("packages", JSONArray(mode.packages.toList()))
            obj.put("websites", JSONArray(mode.websites))
            obj.put("isDefault", mode.isDefault)
            array.put(obj)
        }
        prefs.edit()
            .putString(KEY_MODES, array.toString())
            .putString(KEY_ACTIVE, _activeModeId.value)
            .apply()
    }

    private fun loadModes(): List<BlockMode> {
        val raw = prefs.getString(KEY_MODES, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { i ->
                val obj = array.getJSONObject(i)
                val packages = obj.optJSONArray("packages").toStringSet()
                val websites = obj.optJSONArray("websites").toStringList()
                BlockMode(
                    id = obj.getString("id"),
                    name = obj.getString("name"),
                    kind = BlockMode.Kind.fromRaw(obj.optString("kind")),
                    packages = packages,
                    websites = websites,
                    isDefault = obj.optBoolean("isDefault")
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun JSONArray?.toStringSet(): Set<String> {
        if (this == null) return emptySet()
        return (0 until length()).map { getString(it) }.toSet()
    }

    private fun JSONArray?.toStringList(): List<String> {
        if (this == null) return emptyList()
        return (0 until length()).map { getString(it) }
    }
}
