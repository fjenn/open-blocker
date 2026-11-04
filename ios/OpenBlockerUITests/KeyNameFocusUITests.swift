import XCTest

/// A tap on the left side of the Key Name box (the label area) must focus the
/// text field and bring up the keyboard.
final class KeyNameFocusUITests: XCTestCase {
    func testTapOnLeftSideOfNameBoxOpensKeyboard() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-screen", "key-setup"]
        app.launch()
        
        XCTAssertTrue(app.descendants(matching: .any)["key-setup-root"].waitForExistence(timeout: 8))
        let name = app.textFields["key-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 4))
        XCTAssertFalse(app.keyboards.element.exists)
        
        // Far left edge of the row, well away from the text field itself.
        let leftSide = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: 30, dy: name.frame.midY))
        leftSide.tap()
        
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 3), "keyboard should open")
        XCTAssertEqual(name.value(forKey: "hasKeyboardFocus") as? Bool, true)
        
        let dir = "/tmp/ob-1.0.2-artifacts"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? XCUIScreen.main.screenshot().pngRepresentation
            .write(to: URL(fileURLWithPath: dir + "/add_key_name_focused_after_left_tap.png"))
    }
}
