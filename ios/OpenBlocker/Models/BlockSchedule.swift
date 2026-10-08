// Adapted from Foqos (MIT, (c) 2024 Ali Waseem): Foqos/Models/Schedule.swift

import Foundation

struct BlockSchedule: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var weekdays: Set<Int>
    var startMinute: Int
    var endMinute: Int
    var modeID: UUID?
    var isOn: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        weekdays: Set<Int>,
        startMinute: Int,
        endMinute: Int,
        modeID: UUID? = nil,
        isOn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.weekdays = weekdays
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.modeID = modeID
        self.isOn = isOn
    }
    
    static func formatClock(_ minute: Int) -> String {
        let hour = minute / 60
        let min = minute % 60
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, min, period)
    }
    
    var timeRangeString: String {
        "\(Self.formatClock(startMinute)) - \(Self.formatClock(endMinute))"
    }
    
    /// Next start after `now`. Overnight windows still start on a selected weekday.
    func nextStartDate(now: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard !weekdays.isEmpty else { return nil }
        let startOfToday = calendar.startOfDay(for: now)
        for offset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else {
                continue
            }
            let weekday = calendar.component(.weekday, from: day)
            guard weekdays.contains(weekday) else { continue }
            guard let start = calendar.date(byAdding: .minute, value: startMinute, to: day) else {
                continue
            }
            if start > now {
                return start
            }
        }
        return nil
    }
    
    func nextRunString(now: Date = Date(), calendar: Calendar = .current) -> String {
        guard isOn else { return "Off" }
        guard let date = nextStartDate(now: now, calendar: calendar) else {
            return "No next run"
        }
        let weekday = calendar.component(.weekday, from: date)
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let day = names[(weekday - 1 + 7) % 7]
        return "Next: \(day) \(Self.formatClock(startMinute))"
    }
    
    var daysString: String {
        if weekdays.count == 7 {
            return "Everyday"
        }
        
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = weekdays.sorted().map { ($0 == 1 ? 7 : $0 - 1) % 7 }
        
        if Set(sortedDays) == Set([0, 6]) {
            return "Weekends"
        }
        if Set(sortedDays) == Set([1, 2, 3, 4, 5]) {
            return "Weekdays"
        }
        
        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }
    
    func isTodayScheduled(calendar: Calendar = .current) -> Bool {
        let today = calendar.component(.weekday, from: Date())
        return weekdays.contains(today)
    }
    
    var olderThan15Minutes: Bool {
        let duration = endMinute >= startMinute
            ? endMinute - startMinute
            : (24 * 60 - startMinute) + endMinute
        return duration >= 15
    }
}
