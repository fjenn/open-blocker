import XCTest
@testable import OpenBlocker

final class ReviewPromptTests: XCTestCase {
    private func freshDefaults() -> (UserDefaults, String) {
        let suite = "review-prompt-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (defaults, suite)
    }
    
    func testOneAndTwoKeyUnblocksDoNotAsk() {
        let (defaults, suite) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        
        XCTAssertEqual(ReviewPrompt.recordKeyUnblock(defaults: defaults), 1)
        XCTAssertFalse(
            ReviewPrompt.shouldAsk(
                keyUnblockCount: ReviewPrompt.keyUnblockCount(in: defaults),
                appVersion: "1.0.1",
                askedVersions: []
            ),
            "one successful key unblock is not enough"
        )
        
        XCTAssertEqual(ReviewPrompt.recordKeyUnblock(defaults: defaults), 2)
        XCTAssertFalse(
            ReviewPrompt.shouldAsk(
                keyUnblockCount: ReviewPrompt.keyUnblockCount(in: defaults),
                appVersion: "1.0.1",
                askedVersions: []
            ),
            "two successful key unblocks is not enough"
        )
    }
    
    func testThirdKeyUnblockRequestsTheReview() {
        let (defaults, suite) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        
        _ = ReviewPrompt.recordKeyUnblock(defaults: defaults)
        _ = ReviewPrompt.recordKeyUnblock(defaults: defaults)
        XCTAssertEqual(ReviewPrompt.recordKeyUnblock(defaults: defaults), 3)
        
        XCTAssertTrue(
            ReviewPrompt.shouldAsk(
                keyUnblockCount: ReviewPrompt.keyUnblockCount(in: defaults),
                appVersion: "1.0.1",
                askedVersions: []
            ),
            "third successful key unblock should request the review"
        )
    }
    
    func testCounterPersistsAcrossReads() {
        let (defaults, suite) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        
        XCTAssertEqual(ReviewPrompt.keyUnblockCount(in: defaults), 0)
        _ = ReviewPrompt.recordKeyUnblock(defaults: defaults)
        _ = ReviewPrompt.recordKeyUnblock(defaults: defaults)
        XCTAssertEqual(ReviewPrompt.keyUnblockCount(in: defaults), 2)
    }
    
    func testEmergencyAndScheduleEndsDoNotCountTowardThreshold() {
        // Only recordKeyUnblock increments. Other end reasons never call it,
        // so three non-key completions leave the counter at zero.
        let (defaults, suite) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        
        XCTAssertEqual(ReviewPrompt.keyUnblockCount(in: defaults), 0)
        XCTAssertFalse(
            ReviewPrompt.shouldAsk(
                keyUnblockCount: 0,
                appVersion: "1.0.1",
                askedVersions: []
            )
        )
        
        // Two real key unblocks plus an emergency still fall short.
        _ = ReviewPrompt.recordKeyUnblock(defaults: defaults)
        _ = ReviewPrompt.recordKeyUnblock(defaults: defaults)
        XCTAssertFalse(
            ReviewPrompt.shouldAsk(
                keyUnblockCount: ReviewPrompt.keyUnblockCount(in: defaults),
                appVersion: "1.0.1",
                askedVersions: []
            ),
            "emergency unblocks must not fill the third slot"
        )
    }
    
    func testAsksOnlyOncePerAppVersion() {
        let three = 3
        XCTAssertFalse(
            ReviewPrompt.shouldAsk(
                keyUnblockCount: three,
                appVersion: "1.0.1",
                askedVersions: ["1.0.1"]
            )
        )
        XCTAssertTrue(
            ReviewPrompt.shouldAsk(
                keyUnblockCount: three,
                appVersion: "1.0.2",
                askedVersions: ["1.0.1"]
            ),
            "a new version may ask again"
        )
    }
    
    func testMarkAskedPersistsTheVersion() {
        let (defaults, suite) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        
        XCTAssertTrue(ReviewPrompt.askedVersions(in: defaults).isEmpty)
        ReviewPrompt.markAsked(version: "1.0.1", defaults: defaults)
        ReviewPrompt.markAsked(version: "1.0.1", defaults: defaults)
        XCTAssertEqual(ReviewPrompt.askedVersions(in: defaults), ["1.0.1"])
        
        XCTAssertFalse(
            ReviewPrompt.shouldAsk(
                keyUnblockCount: 3,
                appVersion: "1.0.1",
                askedVersions: ReviewPrompt.askedVersions(in: defaults)
            )
        )
    }
}
