import XCTest
@testable import OpenBlocker

final class HoldFillTests: XCTestCase {
    private let frame: TimeInterval = 1.0 / 60
    
    private func run(_ fill: inout HoldFill, for seconds: TimeInterval) -> [HoldFill.Event] {
        var events: [HoldFill.Event] = []
        var elapsed: TimeInterval = 0
        while elapsed < seconds - 1e-9 {
            events += fill.step(by: frame)
            elapsed += frame
        }
        return events
    }
    
    func testFullHoldCompletesOnceAtFillDuration() {
        var fill = HoldFill()
        XCTAssertTrue(fill.press())
        let early = run(&fill, for: HoldFill.fillDuration - 0.1)
        XCTAssertFalse(early.contains(.completed))
        XCTAssertLessThan(fill.progress, 1)
        
        var late: [HoldFill.Event] = []
        while !late.contains(.completed) && late.count < 100 {
            late += fill.step(by: frame)
        }
        XCTAssertEqual(late.filter { $0 == .completed }.count, 1)
        XCTAssertEqual(fill.progress, 1, "full at the moment it completes")
        XCTAssertFalse(fill.isHolding)
        
        // Once the session starts the fill stays full.
        fill.setLocked(true)
        XCTAssertEqual(run(&fill, for: 0.5), [])
        XCTAssertEqual(fill.progress, 1)
    }
    
    func testFillIsADeliberateHold() {
        XCTAssertGreaterThanOrEqual(HoldFill.fillDuration, 3)
        XCTAssertLessThanOrEqual(HoldFill.fillDuration, 8)
        XCTAssertLessThan(HoldFill.drainDuration, HoldFill.fillDuration)
    }
    
    func testEarlyReleaseDrainsWithoutCompleting() {
        var fill = HoldFill()
        fill.press()
        _ = run(&fill, for: HoldFill.fillDuration * 0.5)
        let halfway = fill.progress
        XCTAssertGreaterThan(halfway, 0.4)
        
        fill.release()
        let events = run(&fill, for: HoldFill.drainDuration)
        XCTAssertFalse(events.contains(.completed))
        XCTAssertEqual(fill.progress, 0, accuracy: 1e-9)
        XCTAssertTrue(fill.isSettled)
    }
    
    func testTicksFireOncePerStepAndRefireAfterDrain() {
        var fill = HoldFill()
        fill.press()
        let ticks = run(&fill, for: HoldFill.fillDuration * 0.55).filter { $0 != .completed }
        XCTAssertEqual(ticks, [.tick(1), .tick(2), .tick(3), .tick(4), .tick(5)])
        
        fill.release()
        _ = run(&fill, for: HoldFill.drainDuration)
        fill.press()
        let again = run(&fill, for: HoldFill.fillDuration * 0.25)
        XCTAssertEqual(again.first, .tick(1))
    }
    
    func testHoldingCannotEndASession() {
        var fill = HoldFill()
        fill.setLocked(true)
        fill.snapToRest()
        XCTAssertEqual(fill.progress, 1)
        XCTAssertFalse(fill.press(), "holding must never unlock; only a key does")
        XCTAssertEqual(run(&fill, for: 2), [])
        XCTAssertEqual(fill.progress, 1)
    }
    
    func testLockedKeySettlesFullAndDrainsAfterUnlock() {
        var fill = HoldFill()
        fill.setLocked(true)
        _ = run(&fill, for: HoldFill.settleDuration + 0.05)
        XCTAssertEqual(fill.progress, 1)
        
        fill.setLocked(false)
        _ = run(&fill, for: HoldFill.drainDuration + 0.05)
        XCTAssertEqual(fill.progress, 0)
    }
    
    func testReduceMotionSnapsWhenIdleButStillFillsWhileHolding() {
        var fill = HoldFill()
        fill.snapsWhenIdle = true
        fill.press()
        _ = run(&fill, for: HoldFill.fillDuration * 0.25)
        XCTAssertGreaterThan(fill.progress, 0.2)
        XCTAssertLessThan(fill.progress, 0.3)
        fill.release()
        _ = fill.step(by: frame)
        XCTAssertEqual(fill.progress, 0)
    }
    
    func testShaderLevelHidesEmptyAndOvershootsFull() {
        XCTAssertEqual(FillLevel.shaderLevel(for: 0), FillLevel.hidden)
        XCTAssertGreaterThan(FillLevel.shaderLevel(for: 1), 1)
        XCTAssertLessThan(FillLevel.shaderLevel(for: 0.5), FillLevel.shaderLevel(for: 0.6))
        XCTAssertEqual(FillLevel.shaderLevel(for: 0.5), 0.5, accuracy: 0.02, "the fill rises linearly")
    }
}
