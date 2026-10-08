import XCTest
@testable import OpenBlocker

final class FocusStatsTests: XCTestCase {
    var calendar: Calendar!
    
    override func setUp() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        self.calendar = calendar
    }
    
    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }
    
    func testTodayClipsToNowAndIgnoresFuture() {
        let now = date(2026, 1, 8, 12, 0)
        let intervals = [
            FocusInterval(start: date(2026, 1, 8, 9, 0), end: date(2026, 1, 8, 10, 0)),
            FocusInterval(start: date(2026, 1, 8, 18, 0), end: date(2026, 1, 8, 19, 0))
        ]
        let today = FocusStats.onDay(now, intervals: intervals, now: now, calendar: calendar)
        XCTAssertEqual(today.duration, 3600, accuracy: 0.5)
        XCTAssertEqual(today.sessions, 1)
    }
    
    func testWeekDurationsAreSevenDaysMondayStart() {
        let weekStart = date(2026, 1, 5, 0, 0)
        let now = date(2026, 1, 8, 18, 0)
        let intervals = [
            FocusInterval(start: date(2026, 1, 5, 10, 0), end: date(2026, 1, 5, 12, 0)),
            FocusInterval(start: date(2026, 1, 7, 8, 0), end: date(2026, 1, 7, 8, 30)),
            FocusInterval(start: date(2026, 1, 8, 17, 0), end: now)
        ]
        let days = FocusStats.weekDurations(
            weekStart: weekStart, intervals: intervals, now: now, calendar: calendar
        )
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days[0], 7200, accuracy: 0.5)
        XCTAssertEqual(days[1], 0, accuracy: 0.5)
        XCTAssertEqual(days[2], 1800, accuracy: 0.5)
        XCTAssertEqual(days[3], 3600, accuracy: 0.5)
        XCTAssertEqual(days[4], 0, accuracy: 0.5)
    }
    
    func testLifetimeSumsClippedSessions() {
        let now = date(2026, 1, 8, 12, 0)
        let intervals = [
            FocusInterval(start: date(2026, 1, 1, 10, 0), end: date(2026, 1, 1, 11, 0)),
            FocusInterval(start: date(2026, 1, 8, 11, 0), end: date(2026, 1, 8, 14, 0))
        ]
        let total = FocusStats.lifetime(intervals: intervals, now: now)
        XCTAssertEqual(total, 3600 + 3600, accuracy: 0.5)
    }
}
