import XCTest
@testable import OpenBlocker

final class ModeTemplateTests: XCTestCase {
    func testTemplateSet() {
        XCTAssertEqual(
            ModeTemplate.allCases.map(\.title),
            ["Deep work", "Sleep", "Mindfulness", "Family time", "Detox", "Blank"]
        )
        for template in ModeTemplate.allCases {
            XCTAssertFalse(template.title.localizedCaseInsensitiveContains("almost none"))
            XCTAssertFalse(template.title.localizedCaseInsensitiveContains("brick"))
            XCTAssertFalse(template.summary.contains("\u{2014}"), "no em dashes in copy")
            XCTAssertFalse((template.scheduleSummary ?? "").contains("\u{2014}"), "no em dashes in copy")
        }
    }
    
    func testTemplatesPrefillBehavior() {
        XCTAssertEqual(ModeTemplate.deepWork.kind, .block)
        XCTAssertEqual(ModeTemplate.sleep.kind, .allowOnly)
        XCTAssertEqual(ModeTemplate.mindfulness.kind, .block)
        XCTAssertEqual(ModeTemplate.familyTime.kind, .allowOnly)
        XCTAssertEqual(ModeTemplate.detox.kind, .allowOnly)
        XCTAssertEqual(ModeTemplate.blank.kind, .block)
    }
    
    func testOnlyTemplatesThatNeedAppsOpenThePicker() {
        XCTAssertEqual(
            ModeTemplate.allCases.filter(\.opensAppPicker),
            [.deepWork, .sleep, .mindfulness, .familyTime]
        )
    }
    
    func testMadeModesStartWithoutApps() {
        let detox = ModeTemplate.detox.makeMode()
        XCTAssertEqual(detox.name, "Detox")
        XCTAssertEqual(detox.subtitle, "Blocks all apps")
        XCTAssertEqual(ModeTemplate.deepWork.makeMode().subtitle, "Nothing chosen yet")
        XCTAssertEqual(ModeTemplate.blank.makeMode().name, "")
    }
    
    func testSleepSuggestsAnOvernightScheduleForTheNewMode() throws {
        let sleep = ModeTemplate.sleep.makeMode()
        let schedule = try XCTUnwrap(ModeTemplate.sleep.suggestedSchedule(for: sleep))
        XCTAssertEqual(schedule.modeID, sleep.id)
        XCTAssertEqual(schedule.name, "Sleep")
        XCTAssertEqual(schedule.weekdays.count, 7)
        XCTAssertEqual(schedule.startMinute, 22 * 60)
        XCTAssertEqual(schedule.endMinute, 7 * 60)
        XCTAssertTrue(schedule.isOn)
        XCTAssertEqual(ModeTemplate.sleep.scheduleSummary, "Every day, 10:00 PM - 7:00 AM")
    }
    
    func testEveryScheduleSuggestionIsUsable() {
        for template in ModeTemplate.allCases {
            guard let schedule = template.suggestedSchedule(for: template.makeMode()) else { continue }
            XCTAssertFalse(schedule.weekdays.isEmpty, "\(template)")
            XCTAssertTrue(schedule.olderThan15Minutes, "\(template)")
        }
        XCTAssertNil(ModeTemplate.detox.scheduleSummary, "Detox is started by hand")
        XCTAssertNil(ModeTemplate.blank.scheduleSummary)
    }
    
    func testModeNamesAreTrimmedAndRequired() {
        XCTAssertEqual(ModeName.validated("  Reading  "), "Reading")
        XCTAssertNil(ModeName.validated(""))
        XCTAssertNil(ModeName.validated("   \n"))
    }
    
    func testRenamingKeepsTheSameMode() {
        let original = ModeTemplate.deepWork.makeMode()
        var renamed = original
        renamed.name = ModeName.validated(" Study ")!
        XCTAssertEqual(renamed, original, "same id, so updateMode replaces it in place")
        XCTAssertEqual(renamed.name, "Study")
        XCTAssertEqual(renamed.kind, original.kind)
    }
}
