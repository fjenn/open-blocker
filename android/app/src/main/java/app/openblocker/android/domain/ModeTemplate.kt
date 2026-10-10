package app.openblocker.android.domain

/**
 * Starting points offered when you create a mode. A template sets the name,
 * the behavior and, where it fits, a suggested schedule.
 */
enum class ModeTemplate(
    val raw: String,
    val displayName: String,
    val summary: String,
    val kind: BlockMode.Kind,
    val opensAppPicker: Boolean
) {
    DEEP_WORK(
        raw = "deepWork",
        displayName = "Deep work",
        summary = "Block the apps that pull you away while you focus. You pick them next.",
        kind = BlockMode.Kind.BLOCK,
        opensAppPicker = true
    ),
    SLEEP(
        raw = "sleep",
        displayName = "Sleep",
        summary = "Only the apps you pick stay on at night, like Phone and Clock.",
        kind = BlockMode.Kind.ALLOW_ONLY,
        opensAppPicker = true
    ),
    MINDFULNESS(
        raw = "mindfulness",
        displayName = "Mindfulness",
        summary = "Block feeds, news and games so you can be where you are.",
        kind = BlockMode.Kind.BLOCK,
        opensAppPicker = true
    ),
    FAMILY_TIME(
        raw = "familyTime",
        displayName = "Family time",
        summary = "Only the apps you pick stay on, like Phone and Camera.",
        kind = BlockMode.Kind.ALLOW_ONLY,
        opensAppPicker = true
    ),
    DETOX(
        raw = "detox",
        displayName = "Detox",
        summary = "Block every app. Nothing to pick.",
        kind = BlockMode.Kind.ALLOW_ONLY,
        opensAppPicker = false
    ),
    BLANK(
        raw = "blank",
        displayName = "Blank",
        summary = "Start empty and set it up your way.",
        kind = BlockMode.Kind.BLOCK,
        opensAppPicker = false
    );

    val title: String get() = if (this == BLANK) "Blank" else displayName

    val modeName: String get() = if (this == BLANK) "" else displayName

    fun suggestedWindow(): Triple<Set<Int>, Int, Int>? {
        val everyDay = setOf(1, 2, 3, 4, 5, 6, 7)
        return when (this) {
            DEEP_WORK -> Triple(setOf(2, 3, 4, 5, 6), 9 * 60, 12 * 60)
            SLEEP -> Triple(everyDay, 22 * 60, 7 * 60)
            MINDFULNESS -> Triple(everyDay, 7 * 60, 8 * 60)
            FAMILY_TIME -> Triple(everyDay, 18 * 60, 20 * 60)
            DETOX, BLANK -> null
        }
    }

    fun makeMode(isDefault: Boolean = false): BlockMode =
        BlockMode(name = modeName, kind = kind, isDefault = isDefault)

    fun suggestedSchedule(forMode: BlockMode): BlockSchedule? {
        val window = suggestedWindow() ?: return null
        return BlockSchedule(
            name = forMode.name,
            weekdays = window.first,
            startMinute = window.second,
            endMinute = window.third,
            modeId = forMode.id,
            isOn = true
        )
    }

    val scheduleSummary: String?
        get() = suggestedSchedule(makeMode())?.let { "${it.daysString}, ${it.timeRangeString}" }
}
