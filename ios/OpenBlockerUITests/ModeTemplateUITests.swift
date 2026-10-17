import XCTest

/// Create a mode from a template, then rename it from the mode sheet.
final class ModeTemplateUITests: XCTestCase {
    private var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-demo"]
        app.launch()
    }
    
    func testCreateFromTemplateThenRename() {
        element("manage-modes").tap()
        XCTAssertTrue(element("modes-back").waitForExistence(timeout: 6))
        app.buttons["New mode"].firstMatch.tap()
        
        XCTAssertTrue(element("mode-templates").waitForExistence(timeout: 4), "template step missing")
        for title in ["Deep work", "Sleep", "Mindfulness", "Family time", "Detox", "Blank"] {
            XCTAssertTrue(app.staticTexts[title].exists, "\(title) template missing")
        }
        element("mode-template-detox").tap()
        
        let name = app.textFields.firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 4))
        XCTAssertEqual(name.value as? String, "Detox", "template pre-fills the name")
        replaceText(in: name, with: "Sunday reset")
        app.buttons["Save mode"].tap()
        XCTAssertTrue(app.staticTexts["Sunday reset"].waitForExistence(timeout: 4), "new mode not listed")
        
        // Rename an existing mode from its card menu.
        app.buttons["More"].firstMatch.tap()
        app.buttons["Rename"].tap()
        XCTAssertTrue(app.staticTexts["Edit mode"].waitForExistence(timeout: 4))
        let field = app.textFields.firstMatch
        replaceText(in: field, with: "Focus time")
        app.buttons["Save mode"].tap()
        XCTAssertTrue(app.staticTexts["Focus time"].waitForExistence(timeout: 4), "rename not saved")
    }
    
    private func replaceText(in field: XCUIElement, with text: String) {
        // The text is right aligned: tap its end so deletes clear it all.
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        let current = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 2))
        field.typeText(text)
    }
    
    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }
}
