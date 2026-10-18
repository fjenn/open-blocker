import AVFoundation
import FamilyControls
import UserNotifications
import XCTest
@testable import OpenBlocker

final class PermissionsTests: XCTestCase {
    func testCameraStatus() {
        XCTAssertEqual(PermissionStatus(AVAuthorizationStatus.authorized), .granted)
        XCTAssertEqual(PermissionStatus(AVAuthorizationStatus.notDetermined), .notDetermined)
        XCTAssertEqual(PermissionStatus(AVAuthorizationStatus.denied), .denied)
        XCTAssertEqual(PermissionStatus(AVAuthorizationStatus.restricted), .denied)
    }
    
    func testNotificationStatus() {
        XCTAssertEqual(PermissionStatus(UNAuthorizationStatus.authorized), .granted)
        XCTAssertEqual(PermissionStatus(UNAuthorizationStatus.provisional), .granted)
        XCTAssertEqual(PermissionStatus(UNAuthorizationStatus.notDetermined), .notDetermined)
        XCTAssertEqual(PermissionStatus(UNAuthorizationStatus.denied), .denied)
    }
    
    func testScreenTimeStatus() {
        XCTAssertEqual(PermissionStatus(AuthorizationStatus.approved), .granted)
        XCTAssertEqual(PermissionStatus(AuthorizationStatus.notDetermined), .notDetermined)
        XCTAssertEqual(PermissionStatus(AuthorizationStatus.denied), .denied)
    }
    
    @MainActor
    func testScreenTimeNeverGatesTheSimulator() {
        XCTAssertTrue(Permissions.screenTimeUnavailable)
        XCTAssertEqual(Permissions.screenTimeStatus, .granted)
    }
    
    func testScreenTimeCopySaysItIsNotTracking() {
        let text = Permission.screenTime.deniedMessage
        XCTAssertTrue(text.contains("Apple requires"))
        XCTAssertTrue(text.contains("don't read your usage"))
    }
    
    func testDeniedCopyPointsToSettingsWithoutEmDashes() {
        for permission in Permission.allCases {
            XCTAssertFalse(permission.deniedTitle.isEmpty)
            XCTAssertTrue(permission.deniedMessage.contains("Settings"), permission.rawValue)
            XCTAssertFalse(permission.deniedMessage.contains("\u{2014}"))
        }
    }
}
