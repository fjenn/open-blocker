import XCTest
@testable import OpenBlocker

final class ScheduleNextRunTests: XCTestCase {
    private func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
    
    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        calendar().date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute
        ))!
    }
    
    func testWeekdayMorningBeforeStartIsToday() {
        let schedule = BlockSchedule(
            name: "Work Hours",
            weekdays: [2, 3, 4, 5, 6],
            startMinute: 9 * 60,
            endMinute: 17 * 60,
            isOn: true
        )
        // Thursday 8 Oct 2026 06:15
        let now = date(year: 2026, month: 10, day: 8, hour: 6, minute: 15)
        XCTAssertEqual(
            schedule.nextRunString(now: now, calendar: calendar()),
            "Next: Thu 9:00 AM"
        )
    }
    
    func testAfterFridayWindowJumpsToMonday() {
        let schedule = BlockSchedule(
            name: "Work Hours",
            weekdays: [2, 3, 4, 5, 6],
            startMinute: 9 * 60,
            endMinute: 17 * 60,
            isOn: true
        )
        let now = date(year: 2026, month: 10, day: 9, hour: 18, minute: 0)
        XCTAssertEqual(
            schedule.nextRunString(now: now, calendar: calendar()),
            "Next: Mon 9:00 AM"
        )
    }
    
    func testOvernightNextStartStaysOnSelectedWeekday() {
        let schedule = BlockSchedule(
            name: "Night",
            weekdays: [2],
            startMinute: 22 * 60,
            endMinute: 7 * 60,
            isOn: true
        )
        let mondayEvening = date(year: 2026, month: 10, day: 5, hour: 20, minute: 0)
        XCTAssertEqual(
            schedule.nextRunString(now: mondayEvening, calendar: calendar()),
            "Next: Mon 10:00 PM"
        )
        let tuesdayMorning = date(year: 2026, month: 10, day: 6, hour: 3, minute: 0)
        XCTAssertEqual(
            schedule.nextRunString(now: tuesdayMorning, calendar: calendar()),
            "Next: Mon 10:00 PM"
        )
    }
    
    func testDisabledScheduleShowsOff() {
        let schedule = BlockSchedule(
            name: "Evening Focus",
            weekdays: [1, 2, 3, 4, 5, 6, 7],
            startMinute: 21 * 60,
            endMinute: 23 * 60,
            isOn: false
        )
        let now = date(year: 2026, month: 10, day: 8, hour: 6, minute: 15)
        XCTAssertEqual(
            schedule.nextRunString(now: now, calendar: calendar()),
            "Off"
        )
    }
}
