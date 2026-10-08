import Foundation

/// Absolute schedule windows. Overnight ranges (22:00 to 07:00) end on the
/// next calendar day. Foqos's getTimeIntervalStartAndEnd built both Dates on
/// the same day, so end fell before start and DeviceActivity never fired.
enum ScheduleInterval {
    static func crossesMidnight(startMinute: Int, endMinute: Int) -> Bool {
        endMinute <= startMinute
    }
    
    /// Window that begins on `day`'s calendar date. Overnight end is +1 day.
    static func absoluteWindow(
        startMinute: Int,
        endMinute: Int,
        startingOn day: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        let startOfDay = calendar.startOfDay(for: day)
        let start = calendar.date(byAdding: .minute, value: startMinute, to: startOfDay)!
        if crossesMidnight(startMinute: startMinute, endMinute: endMinute) {
            let end = calendar.date(byAdding: .minute, value: endMinute + 24 * 60, to: startOfDay)!
            return (start, end)
        }
        let end = calendar.date(byAdding: .minute, value: endMinute, to: startOfDay)!
        return (start, end)
    }
    
    /// The window containing `now`, or nil if this schedule is off at `now`.
    /// Overnight: selected weekday is the start day, so 03:00 Tuesday still
    /// matches a Monday 22:00-07:00 schedule.
    static func window(
        startMinute: Int,
        endMinute: Int,
        weekdays: Set<Int>,
        at now: Date,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date)? {
        let weekday = calendar.component(.weekday, from: now)
        let minute = calendar.component(.hour, from: now) * 60
            + calendar.component(.minute, from: now)
        
        if !crossesMidnight(startMinute: startMinute, endMinute: endMinute) {
            guard weekdays.contains(weekday),
                  minute >= startMinute,
                  minute < endMinute else { return nil }
            return absoluteWindow(
                startMinute: startMinute,
                endMinute: endMinute,
                startingOn: now,
                calendar: calendar
            )
        }
        
        if weekdays.contains(weekday), minute >= startMinute {
            return absoluteWindow(
                startMinute: startMinute,
                endMinute: endMinute,
                startingOn: now,
                calendar: calendar
            )
        }
        
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let yesterdayWeekday = calendar.component(.weekday, from: yesterday)
        if weekdays.contains(yesterdayWeekday), minute < endMinute {
            return absoluteWindow(
                startMinute: startMinute,
                endMinute: endMinute,
                startingOn: yesterday,
                calendar: calendar
            )
        }
        
        return nil
    }
    
    /// Hour/minute components for DeviceActivitySchedule. An overnight range
    /// keeps end earlier in the day than start; Apple treats that as wrapping
    /// midnight. Do not convert both to Dates on the same calendar day.
    static func deviceActivityBounds(
        startMinute: Int,
        endMinute: Int
    ) -> (start: DateComponents, end: DateComponents) {
        (
            DateComponents(hour: startMinute / 60, minute: startMinute % 60),
            DateComponents(hour: endMinute / 60, minute: endMinute % 60)
        )
    }
}
