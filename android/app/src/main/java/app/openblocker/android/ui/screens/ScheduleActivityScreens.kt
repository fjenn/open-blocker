package app.openblocker.android.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.openblocker.android.data.ModeRepository
import app.openblocker.android.data.ScheduleRepository
import app.openblocker.android.data.SessionHistory
import app.openblocker.android.data.SessionManager
import app.openblocker.android.domain.BlockSchedule
import app.openblocker.android.domain.DurationText
import app.openblocker.android.domain.FocusStats
import app.openblocker.android.ui.components.ButtonEmphasis
import app.openblocker.android.ui.components.CardSurface
import app.openblocker.android.ui.components.EmptyState
import app.openblocker.android.ui.components.Glyph
import app.openblocker.android.ui.components.GlyphIcon
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.components.RoundIconButton
import app.openblocker.android.ui.components.ScrollColumn
import app.openblocker.android.ui.components.SettingsGroup
import app.openblocker.android.ui.components.SheetHeader
import app.openblocker.android.ui.components.TabHeader
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.asCopy
import app.openblocker.android.ui.theme.obColors
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

@Composable
fun ScheduleTab(onCreate: () -> Unit, onEdit: (BlockSchedule) -> Unit, modifier: Modifier = Modifier) {
    val schedules by ScheduleRepository.schedules.collectAsState()
    ScheduleTabContent(schedules, onCreate, { s, on -> ScheduleRepository.update(s.copy(isOn = on)) }, onEdit, modifier)
}

@Composable
fun ScheduleTabContent(
    schedules: List<BlockSchedule>,
    onCreate: () -> Unit,
    onToggle: (BlockSchedule, Boolean) -> Unit,
    onEdit: (BlockSchedule) -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = obColors()
    Box(modifier.fillMaxSize().background(colors.canvas).testTag("schedule_root")) {
        Column(Modifier.fillMaxSize()) {
            ScrollColumn {
                TabHeader("Schedules")
                if (schedules.isEmpty()) {
                    EmptyState("No schedules yet", "Block automatically at set times, every day or only on the days you pick.")
                } else {
                    schedules.forEach { schedule ->
                        CardSurface(Modifier.padding(bottom = Space.s).clickable { onEdit(schedule) }) {
                            Row(Modifier.padding(Space.m), verticalAlignment = Alignment.CenterVertically) {
                                Column(Modifier.weight(1f)) {
                                    Text(schedule.name.ifEmpty { "Schedule" }, style = ObText.body.copy(fontWeight = FontWeight.SemiBold), color = colors.ink)
                                    Text("${schedule.daysString}, ${schedule.timeRangeString}", style = ObText.subhead, color = colors.inkSecondary)
                                    Text(schedule.nextRunString(), style = ObText.footnote, color = colors.inkTertiary)
                                }
                                Switch(
                                    checked = schedule.isOn,
                                    onCheckedChange = { onToggle(schedule, it) },
                                    colors = SwitchDefaults.colors(checkedTrackColor = colors.accent, checkedThumbColor = androidx.compose.ui.graphics.Color.White)
                                )
                            }
                        }
                    }
                    Spacer(Modifier.height(120.dp))
                }
            }
        }
        Column(Modifier.align(Alignment.BottomCenter).padding(bottom = Space.l), horizontalAlignment = Alignment.CenterHorizontally) {
            Text("Create schedule", style = ObText.footnote, color = colors.inkSecondary)
            Spacer(Modifier.height(Space.s))
            RoundIconButton(Glyph.Plus, "Create schedule", testTag = "schedule_create", onClick = onCreate)
        }
    }
}

@Composable
fun ScheduleEditSheet(existing: BlockSchedule?, onClose: () -> Unit) {
    val colors = obColors()
    val modes by ModeRepository.modes.collectAsState()
    var name by remember { mutableStateOf(existing?.name ?: "") }
    var weekdays by remember { mutableStateOf(existing?.weekdays ?: setOf(2, 3, 4, 5, 6)) }
    var start by remember { mutableIntStateOf(existing?.startMinute ?: 9 * 60) }
    var end by remember { mutableIntStateOf(existing?.endMinute ?: 12 * 60) }
    var modeId by remember { mutableStateOf(existing?.modeId ?: ModeRepository.activeMode()?.id) }
    var isOn by remember { mutableStateOf(existing?.isOn ?: true) }
    val labels = listOf("S" to 1, "M" to 2, "T" to 3, "W" to 4, "T" to 5, "F" to 6, "S" to 7)

    Column(Modifier.fillMaxSize().background(colors.sheet).testTag("schedule_edit")) {
        SheetHeader(if (existing == null) "New schedule" else "Edit schedule", onClose)
        ScrollColumn {
            SettingsGroup {
                Row(Modifier.padding(Space.m), verticalAlignment = Alignment.CenterVertically) {
                    Text("Name", style = ObText.subhead, color = colors.inkSecondary, modifier = Modifier.weight(1f))
                    androidx.compose.material3.TextField(
                        value = name,
                        onValueChange = { name = it },
                        singleLine = true,
                        textStyle = ObText.subhead.copy(fontWeight = FontWeight.SemiBold, color = colors.ink),
                        colors = androidx.compose.material3.TextFieldDefaults.colors(
                            focusedContainerColor = androidx.compose.ui.graphics.Color.Transparent,
                            unfocusedContainerColor = androidx.compose.ui.graphics.Color.Transparent,
                            focusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
                            unfocusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent
                        )
                    )
                }
            }
            Spacer(Modifier.height(Space.s))
            Text("Days", style = ObText.caption, color = colors.inkSecondary)
            Row(Modifier.fillMaxWidth().padding(vertical = Space.s), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                labels.forEach { (label, day) ->
                    val on = weekdays.contains(day)
                    Box(
                        Modifier
                            .weight(1f)
                            .height(36.dp)
                            .background(if (on) colors.ink else colors.fillQuiet, CircleShape)
                            .clickable { weekdays = if (on) weekdays - day else weekdays + day },
                        contentAlignment = Alignment.Center
                    ) {
                        Text(label, style = ObText.footnote, color = if (on) colors.inkInverse else colors.ink)
                    }
                }
            }
            Text("Start ${BlockSchedule.formatClock(start)}", style = ObText.subhead, color = colors.ink)
            TimeStepper(start) { start = it }
            Text("End ${BlockSchedule.formatClock(end)}", style = ObText.subhead, color = colors.ink)
            TimeStepper(end) { end = it }
            Spacer(Modifier.height(Space.s))
            if (modes.isNotEmpty()) {
                Text("Mode", style = ObText.caption, color = colors.inkSecondary)
                modes.forEach { mode ->
                    val on = mode.id == modeId
                    Text(
                        mode.name,
                        style = ObText.body.copy(fontWeight = if (on) FontWeight.SemiBold else FontWeight.Normal),
                        color = if (on) colors.ink else colors.inkSecondary,
                        modifier = Modifier.clickable { modeId = mode.id }.padding(vertical = Space.xs)
                    )
                }
            }
            Spacer(Modifier.height(Space.m))
            PrimaryButton("Save schedule", emphasis = ButtonEmphasis.INK, enabled = name.isNotBlank() && weekdays.isNotEmpty()) {
                val next = (existing ?: BlockSchedule(name = name, weekdays = weekdays, startMinute = start, endMinute = end)).copy(
                    name = name.trim(),
                    weekdays = weekdays,
                    startMinute = start,
                    endMinute = end,
                    modeId = modeId,
                    isOn = isOn
                )
                if (existing == null) ScheduleRepository.add(next) else ScheduleRepository.update(next)
                onClose()
            }
            if (existing != null) {
                Spacer(Modifier.height(Space.s))
                PrimaryButton("Delete", onClick = { ScheduleRepository.delete(existing.id); onClose() })
            }
            Spacer(Modifier.height(Space.l))
        }
    }
}

@Composable
private fun TimeStepper(minute: Int, onChange: (Int) -> Unit) {
    val colors = obColors()
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Space.s)) {
        Text("-30", style = ObText.footnote, color = colors.ink, modifier = Modifier.clickable { onChange((minute - 30 + 1440) % 1440) }.padding(Space.xs))
        Text("-5", style = ObText.footnote, color = colors.ink, modifier = Modifier.clickable { onChange((minute - 5 + 1440) % 1440) }.padding(Space.xs))
        Text("+5", style = ObText.footnote, color = colors.ink, modifier = Modifier.clickable { onChange((minute + 5) % 1440) }.padding(Space.xs))
        Text("+30", style = ObText.footnote, color = colors.ink, modifier = Modifier.clickable { onChange((minute + 30) % 1440) }.padding(Space.xs))
    }
}

@Composable
fun ActivityTab(modifier: Modifier = Modifier) {
    val blocking by SessionManager.isBlocking.collectAsState()
    val start by SessionManager.sessionStartTime.collectAsState()
    val now = System.currentTimeMillis()
    val open = if (blocking) start else 0L
    val intervals = SessionHistory.allIncludingOpen(now, open)
    ActivityTabContent(intervals, now, blocking, modifier)
}

@Composable
fun ActivityTabContent(
    intervals: List<app.openblocker.android.domain.FocusInterval>,
    nowMs: Long,
    blocking: Boolean,
    modifier: Modifier = Modifier
) {
    val colors = obColors()
    val empty = !blocking && intervals.isEmpty()
    if (empty) {
        Box(modifier.fillMaxSize().background(colors.canvas).testTag("activity_scroll")) {
            EmptyState("No sessions yet", "Hold the key to block, and your time will show up here.")
        }
        return
    }
    val weekStart = SessionHistory.mondayWeekStart(nowMs)
    val hours = FocusStats.weekDurations(weekStart, intervals, nowMs).map { it / 3_600_000.0 }
    val averageHours = hours.sum() / 7.0
    val yMax = when {
        hours.maxOrNull() ?: 0.0 <= 2 -> 2.0
        (hours.maxOrNull() ?: 0.0) <= 4 -> 4.0
        else -> kotlin.math.ceil(hours.maxOrNull() ?: 2.0)
    }
    val dayLabel = remember { SimpleDateFormat("EEE", Locale.getDefault()) }
    val dayNum = remember { SimpleDateFormat("d", Locale.getDefault()) }
    val cardDay = remember { SimpleDateFormat("EEE, MMM d", Locale.getDefault()) }
    val todayStart = Calendar.getInstance().apply {
        timeInMillis = nowMs
        set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
    }.timeInMillis
    val recent = (0 until 7).map { offset ->
        val cal = Calendar.getInstance().apply { timeInMillis = nowMs; add(Calendar.DAY_OF_YEAR, -offset); set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0) }
        val stats = FocusStats.onDay(cal.timeInMillis, intervals, nowMs)
        Triple(cal.time, stats.durationMs, stats.sessions)
    }
    val longest = maxOf(recent.maxOf { it.second }, 1L)

    Column(modifier.fillMaxSize().background(colors.canvas).testTag("activity_scroll")) {
        ScrollColumn {
            TabHeader("Weekly activity")
            Text("TIME BLOCKED THIS WEEK".asCopy(), style = ObText.caption, color = colors.inkSecondary)
            Spacer(Modifier.height(Space.m))
            Text("Avg blocked time".asCopy(), style = ObText.subhead, color = colors.inkSecondary)
            Text(DurationText.hoursMinutes((averageHours * 3600).toLong()).asCopy(), style = ObText.largeTitle, color = colors.ink)
            Spacer(Modifier.height(Space.m))
            Canvas(Modifier.fillMaxWidth().height(170.dp)) {
                val barW = size.width / 16f
                val chartH = size.height * 0.72f
                val baseY = size.height * 0.82f
                hours.forEachIndexed { i, h ->
                    val x = size.width * (i + 0.5f) / 7f
                    val bh = ((h / yMax).toFloat() * chartH).coerceAtLeast(0f)
                    drawRoundRect(
                        color = colors.ink.copy(alpha = if (i == 6) 0.9f else 0.55f),
                        topLeft = Offset(x - barW / 2, baseY - bh),
                        size = Size(barW, bh),
                        cornerRadius = CornerRadius(4f, 4f)
                    )
                }
                if (averageHours > 0) {
                    val avgY = baseY - (averageHours / yMax).toFloat() * chartH
                    var x = 0f
                    while (x < size.width - 44f) {
                        drawLine(colors.inkTertiary, Offset(x, avgY), Offset(x + 6f, avgY), strokeWidth = 2f)
                        x += 10f
                    }
                }
            }
            Box(Modifier.fillMaxWidth()) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                    (0 until 7).forEach { i ->
                        val cal = Calendar.getInstance().apply { timeInMillis = weekStart; add(Calendar.DAY_OF_YEAR, i) }
                        val isToday = cal.get(Calendar.DAY_OF_YEAR) == Calendar.getInstance().apply { timeInMillis = nowMs }.get(Calendar.DAY_OF_YEAR)
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(dayLabel.format(cal.time).uppercase(Locale.getDefault()).asCopy(), style = ObText.caption.copy(fontWeight = FontWeight.Medium), color = if (isToday) colors.ink else colors.inkTertiary)
                            Text(dayNum.format(cal.time).asCopy(), style = ObText.caption.copy(fontWeight = FontWeight.Normal), color = if (isToday) colors.ink else colors.inkTertiary)
                        }
                    }
                }
                Box(
                    Modifier
                        .align(Alignment.CenterEnd)
                        .padding(end = 2.dp)
                        .background(colors.inkSecondary, CircleShape)
                        .padding(horizontal = 5.dp, vertical = 2.dp)
                ) {
                    Text("AVG".asCopy(), style = ObText.caption, color = colors.inkInverse)
                }
            }
            Spacer(Modifier.height(Space.xl))
            recent.forEach { (date, duration, sessions) ->
                val isToday = date.time == todayStart
                CardSurface(raised = isToday, modifier = Modifier.padding(bottom = Space.s)) {
                    Column(Modifier.padding(Space.m), verticalArrangement = Arrangement.spacedBy(Space.xs)) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                            if (isToday) {
                                Box(Modifier.size(5.dp).background(colors.ink, CircleShape))
                            }
                            Text((if (isToday) "TODAY" else cardDay.format(date).uppercase(Locale.getDefault())).asCopy(), style = ObText.caption, color = colors.inkSecondary)
                        }
                        Row(verticalAlignment = Alignment.Bottom) {
                            Column(Modifier.weight(1f)) {
                                Text(DurationText.hoursMinutes(duration / 1000).asCopy(), style = ObText.title, color = colors.ink)
                                Text("$sessions session${if (sessions == 1) "" else "s"}".asCopy(), style = ObText.subhead, color = colors.inkSecondary)
                            }
                            Box(
                                Modifier
                                    .width(96.dp)
                                    .height(3.dp)
                                    .background(colors.fillQuiet, CircleShape)
                            ) {
                                Box(
                                    Modifier
                                        .fillMaxWidth((duration.toFloat() / longest).coerceIn(0f, 1f))
                                        .height(3.dp)
                                        .background(colors.ink, CircleShape)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun OnboardingScreen(
    onFinished: () -> Unit,
    onAllowAccessibility: () -> Unit,
    accessibilityOn: Boolean,
    initialPage: Int = 0
) {
    var page by remember(initialPage) { mutableStateOf(initialPage.coerceIn(0, 2)) }
    val colors = obColors()
    val titles = listOf("Open Blocker", "Accessibility", "Your key")
    val subs = listOf(
        "Lock distracting apps. Only something you can hold unlocks them again.",
        "Android requires this permission to block apps and websites. Open Blocker doesn't read or track your usage.",
        "Add an NFC tag, a card, or a printed QR. Hold the key on screen to block any time. Only your real key unblocks."
    )
    Column(Modifier.fillMaxSize().background(colors.canvas).testTag("onboarding"), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.weight(1f))
        Box(Modifier.height(260.dp), contentAlignment = Alignment.Center) {
            when (page) {
                0 -> app.openblocker.android.ui.components.KeyModelScene(0f, 0.2f, false, modifier = Modifier.size(260.dp))
                1 -> OnboardingMedallion(Glyph.Hourglass)
                else -> OnboardingMedallion(Glyph.Key)
            }
        }
        Text(titles[page], style = ObText.title, color = colors.ink, modifier = Modifier.padding(top = Space.s))
        Text(subs[page], style = ObText.body, color = colors.inkSecondary, modifier = Modifier.padding(horizontal = Space.xxxl), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
        if (page == 1 && accessibilityOn) {
            Text("Accessibility is on.", style = ObText.subhead, color = colors.ink, modifier = Modifier.padding(Space.m).testTag("onboarding_note"))
        }
        Spacer(Modifier.weight(1f))
        Row(horizontalArrangement = Arrangement.spacedBy(Space.xs), modifier = Modifier.padding(bottom = Space.xl)) {
            repeat(3) { i ->
                Box(Modifier.size(if (i == page) 20.dp else 8.dp, 8.dp).background(if (i == page) colors.ink else colors.inkTertiary.copy(alpha = 0.5f), CircleShape))
            }
        }
        val title = when (page) {
            0 -> "Continue"
            1 -> if (accessibilityOn) "Continue" else "Allow Accessibility"
            else -> "Get Started"
        }
        PrimaryButton(title, emphasis = ButtonEmphasis.INK, modifier = Modifier.padding(horizontal = Space.xxxl), testTag = "onboarding_continue") {
            when (page) {
                0 -> page = 1
                1 -> if (accessibilityOn) page = 2 else onAllowAccessibility()
                else -> onFinished()
            }
        }
        Spacer(Modifier.height(Space.xxxl))
    }
}

@Composable
private fun OnboardingMedallion(glyph: Glyph) {
    val colors = obColors()
    val fill = if (colors.isDark) androidx.compose.ui.graphics.Color(0xFF2C2C2E) else androidx.compose.ui.graphics.Color.White
    val icon = if (colors.isDark) androidx.compose.ui.graphics.Color.White else androidx.compose.ui.graphics.Color(0xFF1B1B1B)
    Box(
        Modifier
            .size(168.dp)
            .shadow(30.dp, CircleShape, ambientColor = colors.shadow, spotColor = colors.shadow)
            .background(fill, CircleShape),
        contentAlignment = Alignment.Center
    ) {
        GlyphIcon(glyph, icon, size = 60.dp)
    }
}
