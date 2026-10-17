import XCTest

/// Press and hold the 3D key: a short hold drains back, a full hold blocks,
/// holding while blocked does nothing, and only a key scan unblocks.
final class HoldToFillTests: XCTestCase {
    private var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-demo"]
        app.launch()
    }
    
    func testHoldToFillBlocksAndOnlyAKeyUnblocks() {
        let key = element("key-stage")
        let button = element("block-button")
        XCTAssertTrue(key.waitForExistence(timeout: 12), "key missing")
        XCTAssertTrue(waitForLabel(button, containing: "hold to block"))
        pause(1.2)
        
        key.press(forDuration: 0.7)
        pause(1.0)
        XCTAssertTrue(waitForLabel(button, containing: "hold to block"), "a short hold must not block")
        XCTAssertFalse(element("blocked-timer").exists)
        pause(0.6)
        
        key.press(forDuration: HoldDuration.full)
        XCTAssertTrue(waitForLabel(button, containing: "Scan your key to unblock"), "a full hold should block")
        XCTAssertTrue(element("blocked-timer").waitForExistence(timeout: 4))
        pause(2.0)
        
        key.press(forDuration: 1.2)
        XCTAssertTrue(element("toast").waitForExistence(timeout: 3), "holding while blocked should explain the key")
        XCTAssertTrue(waitForLabel(button, containing: "Scan your key to unblock"), "holding must not unblock")
        pause(2.6)
        
        button.tap()
        let nfc = element("tap-nfc")
        XCTAssertTrue(nfc.waitForExistence(timeout: 4))
        pause(0.6)
        nfc.tap()
        XCTAssertTrue(waitForLabel(button, containing: "hold to block"), "key scan should unblock")
        pause(1.5)
    }
    
    private enum HoldDuration {
        /// Comfortably over the app's 5 s fill.
        static let full: TimeInterval = 6.5
    }
    
    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }
    
    private func waitForLabel(_ element: XCUIElement, containing text: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: 5) == .completed
    }
    
    private func pause(_ seconds: TimeInterval) {
        let expectation = expectation(description: "pause")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { expectation.fulfill() }
        wait(for: [expectation], timeout: seconds + 2)
    }
}
