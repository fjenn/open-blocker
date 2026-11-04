import XCTest
import FamilyControls
@testable import OpenBlocker

/// Regression tests for 1.0.4: swiping Open Blocker away and reopening it must
/// not end a block. A relaunch is a new process, where Screen Time access reads
/// as not determined until the app asks again.
final class BlockSurvivesRelaunchTests: XCTestCase {
    var calendar: Calendar!
    let modeID = UUID()
    let scheduleID = UUID()
    
    override func setUp() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        self.calendar = calendar
    }
    
    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int, _ s: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min, second: s))!
    }
    
    private var manualConfig: PolicyStore.Config {
        PolicyStore.Config(modes: [BlockMode(id: modeID, name: "Work")], activeModeID: modeID)
    }
    
    private func scheduleConfig() -> PolicyStore.Config {
        let mode = BlockMode(id: modeID, name: "Work", kind: .block)
        let schedule = BlockSchedule(
            id: scheduleID,
            name: "Hours",
            weekdays: [5],
            startMinute: 9 * 60,
            endMinute: 17 * 60,
            modeID: modeID,
            isOn: true
        )
        return PolicyStore.Config(modes: [mode], schedules: [schedule], activeModeID: modeID)
    }
    
    private func scheduledState() -> PolicyStore.State {
        PolicyStore.State(active: ActiveSession(
            modeID: modeID,
            source: .schedule(scheduleID),
            startedAt: date(2026, 1, 8, 9, 0),
            scheduleEnd: date(2026, 1, 8, 17, 0)
        ))
    }
    
    // MARK: - Screen Time access mapping
    
    func testNotDeterminedIsUnknownNotRevoked() {
        XCTAssertEqual(Reconcile.ScreenTimeAccess(.notDetermined), .unknown)
        XCTAssertEqual(Reconcile.ScreenTimeAccess(.denied), .revoked)
        XCTAssertEqual(Reconcile.ScreenTimeAccess(.approved), .approved)
    }
    
    // MARK: - Relaunch with an active session
    
    func testRelaunchKeepsHoldSessionWhenAccessUnknown() {
        let state = PolicyStore.State(active: ActiveSession(
            modeID: modeID, source: .hold, startedAt: date(2026, 1, 8, 10, 0)
        ))
        let plan = Reconcile.plan(
            config: manualConfig, state: state, now: date(2026, 1, 8, 10, 5),
            screenTime: .unknown, calendar: calendar
        )
        XCTAssertEqual(plan, .unchanged)
        XCTAssertEqual(Reconcile.shieldAction(state: state, config: manualConfig), .apply(modeID))
    }
    
    func testRelaunchKeepsKeySessionWhenAccessUnknown() {
        let state = PolicyStore.State(active: ActiveSession(
            modeID: modeID, source: .key(UUID()), startedAt: date(2026, 1, 8, 10, 0)
        ))
        let plan = Reconcile.plan(
            config: manualConfig, state: state, now: date(2026, 1, 9, 10, 0),
            screenTime: .unknown, calendar: calendar
        )
        XCTAssertEqual(plan, .unchanged)
        XCTAssertEqual(Reconcile.shieldAction(state: state, config: manualConfig), .apply(modeID))
    }
    
    func testRelaunchKeepsKeySessionWhenApproved() {
        let state = PolicyStore.State(active: ActiveSession(
            modeID: modeID, source: .key(UUID()), startedAt: date(2026, 1, 8, 10, 0)
        ))
        let plan = Reconcile.plan(
            config: manualConfig, state: state, now: date(2026, 1, 8, 12, 0),
            screenTime: .approved, calendar: calendar
        )
        XCTAssertEqual(plan, .unchanged)
    }
    
    func testRelaunchKeepsScheduledSessionInsideWindowWhenAccessUnknown() {
        let config = scheduleConfig()
        let state = scheduledState()
        let plan = Reconcile.plan(
            config: config, state: state, now: date(2026, 1, 8, 12, 0),
            screenTime: .unknown, calendar: calendar
        )
        XCTAssertEqual(plan, .unchanged)
        XCTAssertEqual(Reconcile.shieldAction(state: state, config: config), .apply(modeID))
    }
    
    func testRelaunchStillStartsScheduleWhenAccessUnknown() {
        let plan = Reconcile.plan(
            config: scheduleConfig(), state: PolicyStore.State(), now: date(2026, 1, 8, 12, 0),
            screenTime: .unknown, calendar: calendar
        )
        guard case .start(let session) = plan else { return XCTFail("expected start, got \(plan)") }
        XCTAssertEqual(session.scheduleEnd, date(2026, 1, 8, 17, 0))
    }
    
    func testScheduleStillEndsAtEndTimeWhenAccessUnknown() {
        let plan = Reconcile.plan(
            config: scheduleConfig(), state: scheduledState(), now: date(2026, 1, 8, 17, 0, 1),
            screenTime: .unknown, calendar: calendar
        )
        XCTAssertEqual(plan, .end(.scheduleEnd, at: date(2026, 1, 8, 17, 0)))
    }
    
    func testExplicitDenialStillEndsSession() {
        let plan = Reconcile.plan(
            config: manualConfig,
            state: PolicyStore.State(active: ActiveSession(modeID: modeID, source: .hold, startedAt: date(2026, 1, 8, 10, 0))),
            now: date(2026, 1, 8, 11, 0),
            screenTime: .revoked, calendar: calendar
        )
        XCTAssertEqual(plan, .end(.accessRevoked, at: date(2026, 1, 8, 11, 0)))
    }
    
    // MARK: - Shield action
    
    func testNoSessionClearsShield() {
        XCTAssertEqual(Reconcile.shieldAction(state: PolicyStore.State(), config: manualConfig), .clear)
    }
    
    func testActiveSessionWithUnreadableConfigKeepsShield() {
        let state = PolicyStore.State(active: ActiveSession(
            modeID: modeID, source: .hold, startedAt: date(2026, 1, 8, 10, 0)
        ))
        XCTAssertEqual(Reconcile.shieldAction(state: state, config: PolicyStore.Config()), .keep)
    }
    
    func testKeyEndClearsShield() {
        let state = PolicyStore.State(active: ActiveSession(
            modeID: modeID, source: .key(UUID()), startedAt: date(2026, 1, 8, 10, 0)
        ))
        let ended = Reconcile.ending(state, config: manualConfig, reason: .key, at: date(2026, 1, 8, 11, 0), calendar: calendar)
        XCTAssertNotNil(ended)
        XCTAssertEqual(Reconcile.shieldAction(state: ended!, config: manualConfig), .clear)
    }
    
    func testKeyEndOfScheduleClearsShieldAndDoesNotRearm() {
        let config = scheduleConfig()
        let ended = Reconcile.ending(scheduledState(), config: config, reason: .key, at: date(2026, 1, 8, 12, 0), calendar: calendar)!
        XCTAssertEqual(Reconcile.shieldAction(state: ended, config: config), .clear)
        XCTAssertEqual(
            Reconcile.plan(config: config, state: ended, now: date(2026, 1, 8, 12, 1), screenTime: .unknown, calendar: calendar),
            .unchanged
        )
    }
    
    // MARK: - Monitor intervalDidEnd timing
    
    func testIntervalDidEndJustBeforeEndEndsSchedule() {
        let config = scheduleConfig()
        let state = scheduledState()
        let early = date(2026, 1, 8, 16, 59, 30)
        let now = Reconcile.monitorEndTime(endingActivity: scheduleID.uuidString, state: state, now: early)
        XCTAssertEqual(now, date(2026, 1, 8, 17, 0))
        XCTAssertEqual(
            Reconcile.plan(config: config, state: state, now: now, screenTime: .approved, calendar: calendar),
            .end(.scheduleEnd, at: date(2026, 1, 8, 17, 0))
        )
    }
    
    func testIntervalDidEndForOtherActivityDoesNotEndEarly() {
        let early = date(2026, 1, 8, 16, 59, 30)
        XCTAssertEqual(Reconcile.monitorEndTime(endingActivity: UUID().uuidString, state: scheduledState(), now: early), early)
    }
    
    func testIntervalDidEndLongBeforeEndDoesNotEndEarly() {
        let early = date(2026, 1, 8, 12, 0)
        XCTAssertEqual(Reconcile.monitorEndTime(endingActivity: scheduleID.uuidString, state: scheduledState(), now: early), early)
    }
    
    func testIntervalDidEndNeverEndsManualSession() {
        let state = PolicyStore.State(active: ActiveSession(modeID: modeID, source: .hold, startedAt: date(2026, 1, 8, 10, 0)))
        let now = date(2026, 1, 8, 16, 59, 30)
        XCTAssertEqual(Reconcile.monitorEndTime(endingActivity: scheduleID.uuidString, state: state, now: now), now)
        XCTAssertEqual(Reconcile.plan(config: manualConfig, state: state, now: now, screenTime: .approved, calendar: calendar), .unchanged)
    }
    
    // MARK: - state.json reads
    
    func testStateLoadDistinguishesMissingUnreadableAndLoaded() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("state.json")
        
        guard case .missing = PolicyStore.loadStateResult(from: url) else { return XCTFail("expected missing") }
        
        try Data("{not json".utf8).write(to: url)
        guard case .unreadable = PolicyStore.loadStateResult(from: url) else { return XCTFail("expected unreadable") }
        
        let state = PolicyStore.State(active: ActiveSession(modeID: modeID, source: .hold, startedAt: Date()))
        try JSONEncoder().encode(state).write(to: url)
        guard case .loaded(let loaded) = PolicyStore.loadStateResult(from: url) else { return XCTFail("expected loaded") }
        XCTAssertEqual(loaded.active, state.active)
    }
}
