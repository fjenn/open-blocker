import XCTest
@testable import OpenBlocker

final class ModeDefaultsTests: XCTestCase {
    func testFreshConfigGetsAnActiveStarterMode() throws {
        let seeded = try XCTUnwrap(ModeDefaults.seeded(PolicyStore.Config()))
        XCTAssertEqual(seeded.modes.count, 1)
        let starter = try XCTUnwrap(seeded.modes.first)
        XCTAssertEqual(seeded.activeModeID, starter.id)
        XCTAssertEqual(starter.name, "Detox")
        XCTAssertEqual(starter.kind, .allowOnly)
        XCTAssertEqual(starter.subtitle, "Blocks all apps")
    }
    
    func testExistingModesAreLeftAlone() {
        let config = PolicyStore.Config(modes: [BlockMode(name: "Mine")])
        XCTAssertNil(ModeDefaults.seeded(config))
    }
    
    func testEmptyBlockListSubtitle() {
        XCTAssertEqual(BlockMode(name: "New", kind: .block).subtitle, "Nothing chosen yet")
    }
}
