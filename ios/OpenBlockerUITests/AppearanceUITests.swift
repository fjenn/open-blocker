import XCTest

/// Settings switches the whole app between light and dark, and the choice sticks.
final class AppearanceUITests: XCTestCase {
    private var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "settings"]
        app.launch()
    }
    
    override func tearDown() {
        // Leave the default look for the other tests.
        if app.buttons["Auto"].exists { app.buttons["Auto"].tap() }
        super.tearDown()
    }
    
    func testAppearanceSwitchPersists() {
        let picker = app.descendants(matching: .any)["appearance-picker"].firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 8), "appearance control missing")
        for title in ["Auto", "Light", "Dark", "System"] {
            XCTAssertTrue(app.buttons[title].exists, "\(title) option missing")
        }
        XCTAssertTrue(app.descendants(matching: .any)["count-toggle"].exists, "count switch missing")
        XCTAssertTrue(app.staticTexts["Share anonymous count"].exists)
        
        app.buttons["Light"].tap()
        XCTAssertTrue(app.buttons["Light"].isSelected)
        
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Light"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Light"].isSelected, "appearance should persist across launches")
    }
}
