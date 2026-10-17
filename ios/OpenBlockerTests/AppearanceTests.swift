import XCTest
@testable import OpenBlocker

final class AppearanceTests: XCTestCase {
    func testAutoIsTheDefaultAndFollowsBlocking() {
        XCTAssertEqual(AppAppearance.standard, .auto)
        XCTAssertEqual(AppAppearance.auto.colorScheme(isBlocking: true), .dark)
        XCTAssertEqual(AppAppearance.auto.colorScheme(isBlocking: false), .light)
        XCTAssertEqual(AppAppearance.auto.interfaceStyle(isBlocking: true), .dark)
        XCTAssertEqual(AppAppearance.light.colorScheme(isBlocking: true), .light)
    }
    
    func testManualChoicesAndSystemFollowsTheDevice() {
        XCTAssertEqual(AppAppearance.allCases.map(\.title), ["Auto", "Light", "Dark", "System"])
        XCTAssertEqual(AppAppearance.dark.colorScheme, .dark)
        XCTAssertEqual(AppAppearance.light.colorScheme, .light)
        XCTAssertNil(AppAppearance.system.colorScheme)
        XCTAssertEqual(AppAppearance.system.interfaceStyle, .unspecified)
    }
    
    func testStoredValuesRoundTrip() {
        for appearance in AppAppearance.allCases {
            XCTAssertEqual(AppAppearance(rawValue: appearance.rawValue), appearance)
        }
    }
}
