import XCTest
@testable import OpenBlocker

final class EmergencyUnblockTests: XCTestCase {
    func testResetThenUseOneDropsFromFiveToFour() {
        EmergencyUnblockManager.resetToFull()
        XCTAssertEqual(EmergencyUnblockManager.status().remaining, 5)
        XCTAssertTrue(EmergencyUnblockManager.useOne())
        XCTAssertEqual(EmergencyUnblockManager.status().remaining, 4)
    }
}
