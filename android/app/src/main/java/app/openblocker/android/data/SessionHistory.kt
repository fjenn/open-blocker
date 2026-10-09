package app.openblocker.android.data

import android.content.Context
import app.openblocker.android.OpenBlockerApplication
import app.openblocker.android.domain.FocusInterval
import app.openblocker.android.domain.FocusStats
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

object SessionHistory {
    private const val PREFS = "session_history"
    private const val KEY_INTERVALS = "intervals"
    private const val MAX_INTERVALS = 400

    private val prefs by lazy {
        OpenBlockerApplication.getAppContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }

    fun intervals(): List<FocusInterval> {
        val raw = prefs.getString(KEY_INTERVALS, "[]") ?: "[]"
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { i ->
                val obj = array.getJSONObject(i)
                FocusInterval(obj.getLong("start"), obj.getLong("end"))
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun add(startMs: Long, endMs: Long) {
        if (endMs <= startMs) return
        val next = (intervals() + FocusInterval(startMs, endMs)).takeLast(MAX_INTERVALS)
        val array = JSONArray()
        next.forEach {
            array.put(JSONObject().put("start", it.startMs).put("end", it.endMs))
        }
        prefs.edit().putString(KEY_INTERVALS, array.toString()).apply()
    }

    fun allIncludingOpen(nowMs: Long, openStartMs: Long): List<FocusInterval> {
        val closed = intervals()
        return if (openStartMs > 0) closed + FocusInterval(openStartMs, nowMs) else closed
    }

    fun todayBlockedMs(nowMs: Long = System.currentTimeMillis(), openStartMs: Long = 0L): Long {
        val cal = Calendar.getInstance()
        cal.timeInMillis = nowMs
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return FocusStats.onDay(cal.timeInMillis, allIncludingOpen(nowMs, openStartMs), nowMs).durationMs
    }

    fun mondayWeekStart(nowMs: Long = System.currentTimeMillis()): Long {
        val cal = Calendar.getInstance()
        cal.timeInMillis = nowMs
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val day = cal.get(Calendar.DAY_OF_WEEK)
        val delta = if (day == Calendar.SUNDAY) -6 else Calendar.MONDAY - day
        cal.add(Calendar.DAY_OF_YEAR, delta)
        return cal.timeInMillis
    }
}
