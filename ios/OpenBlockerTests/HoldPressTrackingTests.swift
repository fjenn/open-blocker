import XCTest
@testable import OpenBlocker

final class HoldPressTrackingTests: XCTestCase {
    private let bounds = CGSize(width: 200, height: 80)
    
    func testFingerCanDriftInsideAndStillCountAsHolding() {
        XCTAssertTrue(HoldPressTracking.isInsideHoldArea(
            location: CGPoint(x: 100, y: 40),
            bounds: bounds
        ))
        XCTAssertTrue(HoldPressTracking.isInsideHoldArea(
            location: CGPoint(x: 20, y: 18),
            bounds: bounds
        ))
        XCTAssertTrue(HoldPressTracking.isInsideHoldArea(
            location: CGPoint(x: 210, y: 50),
            bounds: bounds
        ), "a small drift past the edge should still count")
    }
    
    func testLeavingTheAreaCancels() {
        XCTAssertFalse(HoldPressTracking.isInsideHoldArea(
            location: CGPoint(x: 280, y: 40),
            bounds: bounds
        ))
        XCTAssertFalse(HoldPressTracking.isInsideHoldArea(
            location: CGPoint(x: 100, y: -80),
            bounds: bounds
        ))
    }
    
    func testUnknownBoundsStayHolding() {
        XCTAssertTrue(HoldPressTracking.isInsideHoldArea(
            location: CGPoint(x: 900, y: 900),
            bounds: .zero
        ))
    }
    
    func testShortPressWithTinyMoveIsATap() {
        XCTAssertTrue(HoldPressTracking.isShortTap(held: 0.12, moved: 8))
        XCTAssertFalse(HoldPressTracking.isShortTap(held: 0.12, moved: 40))
        XCTAssertFalse(HoldPressTracking.isShortTap(held: 0.4, moved: 4))
    }
    
    func testTwelvePointMoveDoesNotLeaveAKey() {
        let key = CGSize(width: 280, height: 280)
        XCTAssertTrue(HoldPressTracking.isInsideHoldArea(
            location: CGPoint(x: 140 + 12, y: 140 + 12),
            bounds: key
        ))
    }
}
