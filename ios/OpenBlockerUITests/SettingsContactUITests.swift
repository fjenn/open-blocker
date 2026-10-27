import XCTest

/// Settings shows Contact & feedback as a row. Tapping it leaves the app
/// (Safari), so this test only checks the label and does not tap through.
final class SettingsContactUITests: XCTestCase {
    func testContactAndFeedbackRowIsOnSettings() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo"]
        app.launch()
        
        let settings = app.descendants(matching: .any)["tab-settings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 12), "settings tab missing")
        settings.tap()
        
        let contact = app.descendants(matching: .any)["settings-contact"].firstMatch
        XCTAssertTrue(contact.waitForExistence(timeout: 4), "contact row missing")
        XCTAssertEqual(contact.label, "Contact & feedback")
        XCTAssertFalse(app.staticTexts["Bugs, questions, and ideas."].exists)
        XCTAssertFalse(app.buttons["Send feedback"].exists)
        
        let shot = XCUIScreen.main.screenshot()
        let shotURL = URL(fileURLWithPath: "/tmp/open-blocker-fresh/artifacts/ios-1.0.1/contact_and_feedback.png")
        try? FileManager.default.createDirectory(at: shotURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? shot.pngRepresentation.write(to: shotURL)
    }
}
