import XCTest
@testable import OpenBlocker

final class KeyNamePromptTests: XCTestCase {
    func testMissingNameHintMatchesToneAndHasNoEmDash() {
        XCTAssertEqual(KeySetupScreen.missingNameHint, "Add a name")
        XCTAssertFalse(KeySetupScreen.missingNameHint.contains("\u{2014}"))
        XCTAssertFalse(KeySetupScreen.missingNameHint.contains("\u{2013}"))
    }
}
