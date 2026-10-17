import XCTest
@testable import OpenBlocker

final class EmergencyUnblockTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
    
    func testResetThenUseOneDropsFromFiveToFour() {
        EmergencyUnblockManager.resetToFull()
        XCTAssertEqual(EmergencyUnblockManager.status().remaining, 5)
        XCTAssertTrue(EmergencyUnblockManager.useOne())
        XCTAssertEqual(EmergencyUnblockManager.status().remaining, 4)
    }
    
    func testFiveEverySixMonths() {
        XCTAssertEqual(EmergencyAllowance.maxCount, 5)
        XCTAssertEqual(EmergencyAllowance.periodMonths, 6)
    }
    
    func testResetDateIsSixCalendarMonthsAfterThePeriodStarts() {
        let allowance = EmergencyAllowance.full(startingAt: date(2026, 10, 8))
        XCTAssertEqual(allowance.resetDate(calendar: calendar), date(2027, 4, 8))
    }
    
    func testNothingChangesBeforeTheResetDate() {
        let allowance = EmergencyAllowance(remaining: 2, periodStart: date(2026, 10, 8))
        XCTAssertEqual(allowance.renewed(at: date(2027, 4, 7), calendar: calendar), allowance)
    }
    
    func testBackToFiveWithANewPeriodOnTheResetDate() {
        let allowance = EmergencyAllowance(remaining: 0, periodStart: date(2026, 10, 8))
        let now = date(2027, 4, 8)
        let renewed = allowance.renewed(at: now, calendar: calendar)
        XCTAssertEqual(renewed.remaining, 5)
        XCTAssertEqual(renewed.periodStart, now)
        XCTAssertEqual(renewed.resetDate(calendar: calendar), date(2027, 10, 8))
    }
    
    func testANewPeriodStartsWhenTheAppOpensLate() {
        let allowance = EmergencyAllowance(remaining: 1, periodStart: date(2026, 1, 1))
        let now = date(2027, 3, 15)
        let renewed = allowance.renewed(at: now, calendar: calendar)
        XCTAssertEqual(renewed, .full(startingAt: now))
    }
    
    func testUsingOneCountsDownAndStopsAtZero() {
        let start = date(2026, 10, 8)
        XCTAssertEqual(EmergencyAllowance.full(startingAt: start).usingOne()?.remaining, 4)
        XCTAssertNil(EmergencyAllowance(remaining: 0, periodStart: start).usingOne())
    }
}
