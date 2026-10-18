import XCTest
@testable import OpenBlocker

final class DurationTextTests: XCTestCase {
    func testHoursMinutes() {
        XCTAssertEqual(DurationText.hoursMinutes(0), "0h 0m")
        XCTAssertEqual(DurationText.hoursMinutes(59), "0h 0m")
        XCTAssertEqual(DurationText.hoursMinutes(3 * 3600 + 7 * 60 + 30), "3h 7m")
        XCTAssertEqual(DurationText.hoursMinutes(-5), "0h 0m")
    }
    
    func testClock() {
        XCTAssertEqual(DurationText.clock(9), "0m 09s")
        XCTAssertEqual(DurationText.clock(30 * 60 + 4), "30m 04s")
        XCTAssertEqual(DurationText.clock(2 * 3600 + 30 * 60 + 4), "2h 30m 04s")
    }
}
