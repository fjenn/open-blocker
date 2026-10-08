import Foundation

struct FocusInterval: Equatable {
    var start: Date
    var end: Date
}

enum FocusStats {
    static func onDay(
        _ day: Date,
        intervals: [FocusInterval],
        now: Date,
        calendar: Calendar
    ) -> (duration: TimeInterval, sessions: Int) {
        let start = calendar.startOfDay(for: day)
        guard let next = calendar.date(byAdding: .day, value: 1, to: start) else {
            return (0, 0)
        }
        let end = min(now, next)
        guard end > start else { return (0, 0) }
        
        var duration: TimeInterval = 0
        var sessions = 0
        for interval in intervals {
            let overlapStart = max(interval.start, start)
            let overlapEnd = min(interval.end, end)
            if overlapStart < overlapEnd {
                duration += overlapEnd.timeIntervalSince(overlapStart)
                sessions += 1
            }
        }
        return (duration, sessions)
    }
    
    static func weekDurations(
        weekStart: Date,
        intervals: [FocusInterval],
        now: Date,
        calendar: Calendar
    ) -> [TimeInterval] {
        (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            return onDay(day, intervals: intervals, now: now, calendar: calendar).duration
        }
    }
    
    static func lifetime(
        intervals: [FocusInterval],
        now: Date
    ) -> TimeInterval {
        intervals.reduce(0) { total, interval in
            let end = min(interval.end, now)
            guard interval.start < end else { return total }
            return total + end.timeIntervalSince(interval.start)
        }
    }
}
