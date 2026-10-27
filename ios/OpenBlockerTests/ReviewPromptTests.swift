import XCTest
@testable import OpenBlocker

final class ReviewPromptTests: XCTestCase {
    private func record(_ reason: SessionRecord.EndReason) -> SessionRecord {
        SessionRecord(
            modeID: UUID(),
            source: .hold,
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 60),
            endedBy: reason
        )
    }
    
    func testCompletedCountIgnoresEmergencyAndRevokedAccess() {
        let history = [
            record(.key),
            record(.scheduleEnd),
            record(.passage),
            record(.emergency),
            record(.accessRevoked)
        ]
        XCTAssertEqual(ReviewPrompt.completedCount(in: history), 3)
        XCTAssertEqual(ReviewPrompt.completedCount(in: []), 0)
    }
    
    func testAsksAfterThirdCompletedBlockWhenIdle() {
        let two = [record(.key), record(.scheduleEnd)]
        XCTAssertFalse(
            ReviewPrompt.shouldAsk(history: two, isBlocking: false, appVersion: "1.0.1", askedVersions: []),
            "two completed blocks is not enough"
        )
        
        let three = two + [record(.passage)]
        XCTAssertTrue(
            ReviewPrompt.shouldAsk(history: three, isBlocking: false, appVersion: "1.0.1", askedVersions: []),
            "third completed block should ask"
        )
    }
    
    func testNeverAsksDuringABlock() {
        let three = [record(.key), record(.key), record(.key)]
        XCTAssertFalse(
            ReviewPrompt.shouldAsk(history: three, isBlocking: true, appVersion: "1.0.1", askedVersions: [])
        )
    }
    
    func testEmergencyUnblocksDoNotTriggerThePrompt() {
        let history = [record(.key), record(.key), record(.emergency)]
        XCTAssertFalse(
            ReviewPrompt.shouldAsk(history: history, isBlocking: false, appVersion: "1.0.1", askedVersions: [])
        )
    }
    
    func testAsksOnlyOncePerAppVersion() {
        let three = [record(.key), record(.key), record(.key)]
        XCTAssertFalse(
            ReviewPrompt.shouldAsk(
                history: three,
                isBlocking: false,
                appVersion: "1.0.1",
                askedVersions: ["1.0.1"]
            )
        )
        XCTAssertTrue(
            ReviewPrompt.shouldAsk(
                history: three,
                isBlocking: false,
                appVersion: "1.0.2",
                askedVersions: ["1.0.1"]
            ),
            "a new version may ask again"
        )
    }
    
    func testMarkAskedPersistsTheVersion() {
        let suite = "review-prompt-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        
        XCTAssertTrue(ReviewPrompt.askedVersions(in: defaults).isEmpty)
        ReviewPrompt.markAsked(version: "1.0.1", defaults: defaults)
        ReviewPrompt.markAsked(version: "1.0.1", defaults: defaults)
        XCTAssertEqual(ReviewPrompt.askedVersions(in: defaults), ["1.0.1"])
        
        let three = [record(.key), record(.key), record(.key)]
        XCTAssertFalse(
            ReviewPrompt.shouldAsk(
                history: three,
                isBlocking: false,
                appVersion: "1.0.1",
                askedVersions: ReviewPrompt.askedVersions(in: defaults)
            )
        )
    }
}
