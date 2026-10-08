import XCTest
@testable import OpenBlocker

final class ScheduleIntervalTests: XCTestCase {
    var calendar: Calendar!
    
    override func setUp() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        self.calendar = calendar
    }
    
    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }
    
    func testSameDayWindowStaysOnOneCalendarDay() {
        let startMin = 9 * 60
        let endMin = 17 * 60
        let (start, end) = ScheduleInterval.absoluteWindow(
            startMinute: startMin,
            endMinute: endMin,
            startingOn: date(2026, 1, 5, 12, 0),
            calendar: calendar
        )
        XCTAssertEqual(start, date(2026, 1, 5, 9, 0))
        XCTAssertEqual(end, date(2026, 1, 5, 17, 0))
        XCTAssertGreaterThan(end, start)
        XCTAssertFalse(ScheduleInterval.crossesMidnight(startMinute: startMin, endMinute: endMin))
    }
    
    func testOvernightWindowEndsNextDay() {
        let startMin = 22 * 60
        let endMin = 7 * 60
        let (start, end) = ScheduleInterval.absoluteWindow(
            startMinute: startMin,
            endMinute: endMin,
            startingOn: date(2026, 1, 5, 23, 0),
            calendar: calendar
        )
        XCTAssertEqual(start, date(2026, 1, 5, 22, 0))
        XCTAssertEqual(end, date(2026, 1, 6, 7, 0))
        XCTAssertGreaterThan(end, start)
        XCTAssertTrue(ScheduleInterval.crossesMidnight(startMinute: startMin, endMinute: endMin))
    }
    
    func testFoqosSameDayDatesWouldInvertOvernight() {
        let day = date(2026, 1, 5, 12, 0)
        let brokenStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: day)!
        let brokenEnd = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: day)!
        XCTAssertLessThan(brokenEnd, brokenStart)
        
        let (start, end) = ScheduleInterval.absoluteWindow(
            startMinute: 22 * 60,
            endMinute: 7 * 60,
            startingOn: day,
            calendar: calendar
        )
        XCTAssertEqual(start, brokenStart)
        XCTAssertNotEqual(end, brokenEnd)
        XCTAssertEqual(end, date(2026, 1, 6, 7, 0))
    }
    
    func testOvernightContainsLateMondayAndEarlyTuesday() {
        let weekdays: Set<Int> = [2]
        let mondayNight = date(2026, 1, 5, 23, 30)
        let tuesdayMorning = date(2026, 1, 6, 3, 0)
        let tuesdayAfternoon = date(2026, 1, 6, 15, 0)
        
        XCTAssertNotNil(ScheduleInterval.window(
            startMinute: 22 * 60, endMinute: 7 * 60, weekdays: weekdays,
            at: mondayNight, calendar: calendar
        ))
        XCTAssertNotNil(ScheduleInterval.window(
            startMinute: 22 * 60, endMinute: 7 * 60, weekdays: weekdays,
            at: tuesdayMorning, calendar: calendar
        ))
        XCTAssertNil(ScheduleInterval.window(
            startMinute: 22 * 60, endMinute: 7 * 60, weekdays: weekdays,
            at: tuesdayAfternoon, calendar: calendar
        ))
    }
    
    func testOvernightDoesNotMatchTheFollowingEvening() {
        let mondayOnly: Set<Int> = [2]
        XCTAssertNil(ScheduleInterval.window(
            startMinute: 22 * 60, endMinute: 7 * 60, weekdays: mondayOnly,
            at: date(2026, 1, 6, 23, 0), calendar: calendar
        ))
        XCTAssertNil(ScheduleInterval.window(
            startMinute: 22 * 60, endMinute: 7 * 60, weekdays: mondayOnly,
            at: date(2026, 1, 7, 3, 0), calendar: calendar
        ))
    }
    
    func testDeviceActivityBoundsKeepOvernightComponents() {
        let bounds = ScheduleInterval.deviceActivityBounds(startMinute: 22 * 60, endMinute: 7 * 60)
        XCTAssertEqual(bounds.start.hour, 22)
        XCTAssertEqual(bounds.start.minute, 0)
        XCTAssertEqual(bounds.end.hour, 7)
        XCTAssertEqual(bounds.end.minute, 0)
        XCTAssertLessThan(bounds.end.hour!, bounds.start.hour!)
    }
}
