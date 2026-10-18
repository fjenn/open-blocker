import XCTest
@testable import OpenBlocker

final class HoldHapticCurveTests: XCTestCase {
    func testBuildUpStartsSoftAndRisesSteadily() {
        let steps = stride(from: 0.0, through: 1.0, by: 0.05).map { $0 }
        let intensity = steps.map(HoldHapticCurve.intensity)
        let sharpness = steps.map(HoldHapticCurve.sharpness)
        XCTAssertLessThan(intensity.first!, 0.3, "soft at the start")
        XCTAssertGreaterThan(intensity.last!, 0.9, "strong at the end")
        XCTAssertEqual(intensity, intensity.sorted(), "never dips")
        XCTAssertEqual(sharpness, sharpness.sorted(), "never dips")
        XCTAssertTrue(intensity.allSatisfy { (0...1).contains($0) })
        XCTAssertTrue(sharpness.allSatisfy { (-1...1).contains($0) })
    }
    
    func testTapsSpeedUpOverTheHold() {
        let taps = HoldHapticCurve.tapProgress
        XCTAssertGreaterThan(taps.count, 12)
        XCTAssertTrue(taps.allSatisfy { (0..<1).contains($0) })
        let gaps = zip(taps.dropFirst(), taps).map { $0 - $1 }
        XCTAssertEqual(gaps, gaps.sorted(by: >), "each gap is shorter than the last")
        XCTAssertGreaterThan(gaps.first! / gaps.last!, 4, "sparse at first, a fast patter at the end")
    }
}
