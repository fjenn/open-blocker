package app.openblocker.android.data

import android.content.Context
import app.openblocker.android.OpenBlockerApplication
import app.openblocker.android.domain.BlockSchedule
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

object ScheduleRepository {
    private const val PREFS = "schedule_prefs"
    private const val KEY_SCHEDULES = "schedules"

    private val prefs by lazy {
        OpenBlockerApplication.getAppContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }

    private val _schedules = MutableStateFlow(load())
    val schedules: StateFlow<List<BlockSchedule>> = _schedules.asStateFlow()

    fun add(schedule: BlockSchedule) {
        _schedules.value = _schedules.value + schedule
        persist()
    }

    fun update(schedule: BlockSchedule) {
        _schedules.value = _schedules.value.map { if (it.id == schedule.id) schedule else it }
        persist()
    }

    fun delete(id: String) {
        _schedules.value = _schedules.value.filterNot { it.id == id }
        persist()
    }

    fun tick(now: Calendar = Calendar.getInstance()) {
        val active = _schedules.value.filter { it.isOn && it.contains(now) }
        val blocking = SessionManager.isBlocking.value
        when {
            active.isNotEmpty() && !blocking -> {
                active.first().modeId?.let { id ->
                    ModeRepository.modes.value.find { it.id == id }?.let { ModeRepository.setActive(it) }
                }
                SessionManager.startSession(SessionManager.SOURCE_SCHEDULE)
            }
            blocking &&
                SessionManager.source() == SessionManager.SOURCE_SCHEDULE &&
                active.isEmpty() -> SessionManager.endSession()
        }
    }

    private fun persist() {
        val array = JSONArray()
        _schedules.value.forEach { s ->
            array.put(
                JSONObject()
                    .put("id", s.id)
                    .put("name", s.name)
                    .put("weekdays", JSONArray(s.weekdays.toList()))
                    .put("startMinute", s.startMinute)
                    .put("endMinute", s.endMinute)
                    .put("modeId", s.modeId)
                    .put("isOn", s.isOn)
            )
        }
        prefs.edit().putString(KEY_SCHEDULES, array.toString()).apply()
    }

    private fun load(): List<BlockSchedule> {
        val raw = prefs.getString(KEY_SCHEDULES, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { i ->
                val obj = array.getJSONObject(i)
                val days = obj.optJSONArray("weekdays")
                val weekdays = if (days == null) emptySet() else {
                    (0 until days.length()).map { days.getInt(it) }.toSet()
                }
                BlockSchedule(
                    id = obj.getString("id"),
                    name = obj.getString("name"),
                    weekdays = weekdays,
                    startMinute = obj.getInt("startMinute"),
                    endMinute = obj.getInt("endMinute"),
                    modeId = obj.optString("modeId").ifEmpty { null },
                    isOn = obj.optBoolean("isOn")
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }
}
