import XCTest

/// After a key is registered, Save Key stays tappable so an empty name can
/// show the shake, red outline, and "Add a name" hint.
final class KeyNamePromptUITests: XCTestCase {
    func testEmptyNameShowsHintThenClearsOnType() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-screen", "key-setup"]
        app.launch()
        
        XCTAssertTrue(app.descendants(matching: .any)["key-setup-root"].waitForExistence(timeout: 8))
        
        let makeQR = app.buttons["Make QR code"]
        XCTAssertTrue(makeQR.waitForExistence(timeout: 4))
        makeQR.tap()
        
        let save = app.descendants(matching: .any)["save-key"].firstMatch
        XCTAssertTrue(save.waitForExistence(timeout: 4))
        XCTAssertTrue(save.isEnabled, "Save Key should stay tappable after the key is ready")
        save.tap()
        
        let hint = app.descendants(matching: .any)["key-name-hint"].firstMatch
        XCTAssertTrue(hint.waitForExistence(timeout: 3), "empty name should show a hint")
        XCTAssertEqual(hint.label, "Add a name")
        
        let name = app.textFields["key-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 2))
        name.tap()
        name.typeText("Fridge QR")
        XCTAssertFalse(hint.exists, "typing a name should clear the hint")
        
        save.tap()
    }
}
