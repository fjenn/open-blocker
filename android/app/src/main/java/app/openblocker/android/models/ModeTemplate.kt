package app.openblocker.android.models

/**
 * Starting points offered when you create a mode. A template sets the name,
 * the behavior and, where it fits, a suggested schedule.
 */
enum class ModeTemplate(
    val id: String,
    val displayName: String,
    val summary: String,
    val symbol: String,
    val kind: ModeKind,
    val opensAppPicker: Boolean
) {
    DEEP_WORK(
        id = "deepWork",
        displayName = "Deep work",
        summary = "Block the apps that pull you away while you focus. You pick them next.",
        symbol = "scope",
        kind = ModeKind.BLOCK,
        opensAppPicker = true
    ),
    SLEEP(
        id = "sleep",
        displayName = "Sleep",
        summary = "Only the apps you pick stay on at night, like Phone and Clock.",
        symbol = "moon",
        kind = ModeKind.ALLOW_ONLY,
        opensAppPicker = true
    ),
    MINDFULNESS(
        id = "mindfulness",
        displayName = "Mindfulness",
        summary = "Block feeds, news and games so you can be where you are.",
        symbol = "leaf",
        kind = ModeKind.BLOCK,
        opensAppPicker = true
    ),
    FAMILY_TIME(
        id = "familyTime",
        displayName = "Family time",
        summary = "Only the apps you pick stay on, like Phone and Camera.",
        symbol = "figure.2.and.child.holdinghands",
        kind = ModeKind.ALLOW_ONLY,
        opensAppPicker = true
    ),
    DETOX(
        id = "detox",
        displayName = "Detox",
        summary = "Block every app. Nothing to pick.",
        symbol = "circle.slash",
        kind = ModeKind.ALLOW_ONLY,
        opensAppPicker = false
    ),
    BLANK(
        id = "blank",
        displayName = "Blank",
        summary = "Start empty and set it up your way.",
        symbol = "square.dashed",
        kind = ModeKind.BLOCK,
        opensAppPicker = false
    );
    
    /**
     * Suggested schedule window for this template.
     * weekdays: 1=Sunday, 2=Monday, ..., 7=Saturday (Calendar.SUNDAY numbering)
     * times are in minutes from midnight
     */
    fun suggestedSchedule(): ScheduleWindow? {
        return when (this) {
            DEEP_WORK -> ScheduleWindow(
                weekdays = setOf(2, 3, 4, 5, 6), // Mon-Fri
                startMinute = 9 * 60, // 9:00 AM
                endMinute = 12 * 60   // 12:00 PM
            )
            SLEEP -> ScheduleWindow(
                weekdays = setOf(1, 2, 3, 4, 5, 6, 7), // Every day
                startMinute = 22 * 60, // 10:00 PM
                endMinute = 7 * 60     // 7:00 AM
            )
            MINDFULNESS -> ScheduleWindow(
                weekdays = setOf(1, 2, 3, 4, 5, 6, 7), // Every day
                startMinute = 7 * 60,  // 7:00 AM
                endMinute = 8 * 60     // 8:00 AM
            )
            FAMILY_TIME -> ScheduleWindow(
                weekdays = setOf(1, 2, 3, 4, 5, 6, 7), // Every day
                startMinute = 18 * 60, // 6:00 PM
                endMinute = 20 * 60    // 8:00 PM
            )
            DETOX, BLANK -> null
        }
    }
    
    fun scheduleSummary(): String? {
        val window = suggestedSchedule() ?: return null
        val daysString = when {
            window.weekdays.size == 7 -> "Every day"
            window.weekdays == setOf(2, 3, 4, 5, 6) -> "Weekdays"
            else -> "Selected days"
        }
        val startHour = window.startMinute / 60
        val startMin = window.startMinute % 60
        val endHour = window.endMinute / 60
        val endMin = window.endMinute % 60
        val startTime = String.format("%d:%02d %s",
            if (startHour > 12) startHour - 12 else if (startHour == 0) 12 else startHour,
            startMin,
            if (startHour >= 12) "PM" else "AM"
        )
        val endTime = String.format("%d:%02d %s",
            if (endHour > 12) endHour - 12 else if (endHour == 0) 12 else endHour,
            endMin,
            if (endHour >= 12) "PM" else "AM"
        )
        return "$daysString, $startTime - $endTime"
    }
}

enum class ModeKind {
    BLOCK,       // Block selected apps
    ALLOW_ONLY   // Allow only selected apps
}

data class ScheduleWindow(
    val weekdays: Set<Int>,
    val startMinute: Int,
    val endMinute: Int
)
