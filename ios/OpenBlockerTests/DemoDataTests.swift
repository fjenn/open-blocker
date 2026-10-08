import XCTest
@testable import OpenBlocker

final class DemoDataTests: XCTestCase {
    func testHistoryIsIdenticalAcrossTwoSeeds() {
        DemoData.setupDemo()
        let first = stamped(PolicyStore.loadHistory())
        DemoData.setupDemo()
        let second = stamped(PolicyStore.loadHistory())
        XCTAssertEqual(first.count, second.count)
        XCTAssertEqual(first, second)
        XCTAssertFalse(first.isEmpty)
    }
    
    func testWeekdayTotalsAreFixed() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 8, hour: 12))!
        let modes = [
            BlockMode(name: "A"),
            BlockMode(name: "B"),
            BlockMode(name: "C")
        ]
        let history = DemoData.history(
            modes: modes,
            keyID: UUID(),
            now: now,
            calendar: calendar
        )
        
        let wednesday = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7))!
        let wed = FocusStats.onDay(wednesday, intervals: history.map {
            FocusInterval(start: $0.start, end: $0.end)
        }, now: now, calendar: calendar)
        XCTAssertEqual(wed.duration, (100 + 63) * 60, accuracy: 0.5)
        XCTAssertEqual(wed.sessions, 2)
        
        let monday = calendar.date(from: DateComponents(year: 2026, month: 10, day: 5))!
        let mon = FocusStats.onDay(monday, intervals: history.map {
            FocusInterval(start: $0.start, end: $0.end)
        }, now: now, calendar: calendar)
        XCTAssertEqual(mon.duration, (50 + 25) * 60, accuracy: 0.5)
        
        let today = FocusStats.onDay(now, intervals: history.map {
            FocusInterval(start: $0.start, end: $0.end)
        }, now: now, calendar: calendar)
        XCTAssertEqual(today.sessions, 1)
        XCTAssertEqual(today.duration, 32 * 60, accuracy: 0.5)
    }
    
    private func stamped(_ history: [SessionRecord]) -> [String] {
        history
            .map { "\(Int($0.start.timeIntervalSince1970))-\(Int($0.end.timeIntervalSince1970))" }
            .sorted()
    }
}
