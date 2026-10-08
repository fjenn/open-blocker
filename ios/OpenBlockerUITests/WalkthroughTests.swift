import XCTest

/// One continuous session through the demo screens. Used for Finn's
/// walkthrough video and as a navigation smoke test.
final class WalkthroughTests: XCTestCase {
    private var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-demo"]
        app.launch()
    }
    
    func testWalkthrough() {
        let block = element("block-button")
        XCTAssertTrue(block.waitForExistence(timeout: 12), "home block button missing")
        XCTAssertTrue(isIdle(block), "home should start idle")
        pause(0.8)
        
        block.tap()
        tapNFC()
        XCTAssertTrue(waitForUnblockButton(), "block did not start")
        pause(0.9)
        
        tap("tab-schedule")
        XCTAssertTrue(element("schedule-root").waitForExistence(timeout: 4))
        pause(0.8)
        
        tap("tab-activity")
        let activity = element("activity-scroll")
        XCTAssertTrue(activity.waitForExistence(timeout: 4))
        if activity.isHittable {
            activity.swipeUp()
        } else {
            app.swipeUp()
        }
        pause(0.8)
        
        tap("tab-settings")
        pause(0.6)
        
        tap("settings-keys", labeled: "My Keys")
        pause(0.6)
        tap("add-key", labeled: "Add Key")
        XCTAssertTrue(
            app.staticTexts["Key Name"].waitForExistence(timeout: 4) ||
            app.navigationBars["Add Key"].waitForExistence(timeout: 1),
            "Add Key sheet missing"
        )
        pause(0.9)
        app.buttons["Cancel"].firstMatch.tap()
        goBack()
        
        tap("settings-rules", labeled: "My Rules")
        pause(0.7)
        goBack()
        
        tap("settings-help", labeled: "Help")
        XCTAssertTrue(app.staticTexts["How keys work"].waitForExistence(timeout: 4))
        pause(0.6)
        goBack()
        
        tap("settings-contact", labeled: "Contact")
        XCTAssertTrue(app.staticTexts["Bugs, questions, and ideas."].waitForExistence(timeout: 4))
        pause(0.5)
        goBack()
        
        tap("settings-about", labeled: "About")
        XCTAssertTrue(app.staticTexts["MIT License"].waitForExistence(timeout: 4))
        pause(0.5)
        goBack()
        
        tap("settings-notifications", labeled: "Notifications")
        XCTAssertTrue(app.staticTexts["When a block ends"].waitForExistence(timeout: 4))
        pause(0.5)
        goBack()
        
        tap("tab-block")
        tap("manage-modes", labeled: "Manage modes")
        XCTAssertTrue(element("modes-back").waitForExistence(timeout: 4))
        pause(0.5)
        tap("mode-edit", labeled: "Edit")
        XCTAssertTrue(
            app.staticTexts["Mode Name"].waitForExistence(timeout: 4),
            "mode edit screen missing"
        )
        pause(0.9)
        app.buttons["Cancel"].firstMatch.tap()
        element("modes-back").tap()
        pause(0.4)
        
        let unblock = element("block-button")
        XCTAssertTrue(unblock.waitForExistence(timeout: 4))
        unblock.tap()
        tapNFC()
        XCTAssertTrue(waitForIdleButton(), "unlock did not return home to idle")
        pause(0.9)
        
        element("block-button").tap()
        tapNFC()
        XCTAssertTrue(waitForUnblockButton(), "second block did not start")
        pause(0.6)
        
        tap("tab-settings")
        tap("settings-emergency", labeled: "Emergency Unblock")
        let count = element("emergency-count")
        XCTAssertTrue(count.waitForExistence(timeout: 4))
        XCTAssertTrue(waitForLabel(count, containing: "5 left"), "expected 5 left")
        tap("emergency-use", labeled: "Use an emergency unblock")
        let confirm = element("emergency-confirm")
        if confirm.waitForExistence(timeout: 4), confirm.isHittable {
            confirm.tap()
        } else {
            let use = app.buttons["Use"].firstMatch
            XCTAssertTrue(use.waitForExistence(timeout: 4), "confirm step missing")
            use.tap()
        }
        XCTAssertTrue(waitForLabel(count, containing: "4 left"), "count did not drop to 4")
        pause(0.9)
        goBack()
        
        tap("tab-block")
        XCTAssertTrue(waitForIdleButton(), "emergency unblock did not return home to idle")
        pause(0.5)
    }
    
    private func tapNFC() {
        let nfc = element("tap-nfc")
        if nfc.waitForExistence(timeout: 4), nfc.isHittable {
            nfc.tap()
            return
        }
        let labeled = app.buttons["Tap NFC key"]
        XCTAssertTrue(labeled.waitForExistence(timeout: 4), "NFC chooser missing")
        labeled.tap()
    }
    
    private func isIdle(_ button: XCUIElement) -> Bool {
        button.label.contains("Tap or hold to block")
    }
    
    private func waitForIdleButton() -> Bool {
        let button = element("block-button")
        return button.waitForExistence(timeout: 4) && waitForLabel(button, containing: "Tap or hold to block")
    }
    
    private func waitForUnblockButton() -> Bool {
        let button = element("block-button")
        return button.waitForExistence(timeout: 4) && waitForLabel(button, containing: "Tap to unblock")
    }
    
    private func waitForLabel(_ element: XCUIElement, containing text: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let expect = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expect], timeout: 4) == .completed
    }
    
    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }
    
    private func tap(_ id: String, labeled label: String? = nil) {
        let byId = element(id)
        if byId.waitForExistence(timeout: 4), byId.isHittable {
            byId.tap()
            return
        }
        if let label {
            let byLabel = app.buttons[label]
            XCTAssertTrue(byLabel.waitForExistence(timeout: 4), "missing \(id) / \(label)")
            byLabel.tap()
            return
        }
        XCTFail("missing \(id)")
    }
    
    private func goBack() {
        let back = element("nav-back")
        if back.waitForExistence(timeout: 3), back.isHittable {
            back.tap()
            return
        }
        let settings = app.navigationBars.buttons["Settings"]
        if settings.exists {
            settings.tap()
            return
        }
        app.navigationBars.buttons.firstMatch.tap()
    }
    
    private func pause(_ seconds: TimeInterval) {
        let expectation = expectation(description: "pause-\(seconds)")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: seconds + 2)
    }
}
