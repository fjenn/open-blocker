import XCTest
@testable import OpenBlocker

final class ReconcileTests: XCTestCase {
    var calendar: Calendar!
    let modeID = UUID()
    let scheduleID = UUID()
    
    override func setUp() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        self.calendar = calendar
    }
    
    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }
    
    private func config(startMinute: Int, endMinute: Int, weekdays: Set<Int>) -> PolicyStore.Config {
        let mode = BlockMode(id: modeID, name: "Work", kind: .block)
        let schedule = BlockSchedule(
            id: scheduleID,
            name: "Hours",
            weekdays: weekdays,
            startMinute: startMinute,
            endMinute: endMinute,
            modeID: modeID,
            isOn: true
        )
        return PolicyStore.Config(modes: [mode], schedules: [schedule], activeModeID: modeID)
    }
    
    func testUnauthorizedEndsActiveSession() {
        let state = PolicyStore.State(active: ActiveSession(
            modeID: modeID, source: .hold, startedAt: date(2026, 1, 8, 10, 0)
        ))
        let plan = Reconcile.plan(
            config: PolicyStore.Config(modes: [BlockMode(id: modeID, name: "Work")]),
            state: state,
            now: date(2026, 1, 8, 11, 0),
            authorized: false,
            calendar: calendar
        )
        XCTAssertEqual(plan, .end(.accessRevoked, at: date(2026, 1, 8, 11, 0)))
    }
    
    func testSameDayScheduleStartsInsideWindow() {
        let config = config(startMinute: 9 * 60, endMinute: 17 * 60, weekdays: [5])
        let now = date(2026, 1, 8, 10, 0)
        let plan = Reconcile.plan(config: config, state: PolicyStore.State(), now: now, authorized: true, calendar: calendar)
        guard case .start(let session) = plan else {
            return XCTFail("expected start, got \(plan)")
        }
        XCTAssertEqual(session.modeID, modeID)
        XCTAssertEqual(session.scheduleEnd, date(2026, 1, 8, 17, 0))
    }
    
    func testSameDayScheduleDoesNotStartOutsideWindow() {
        let config = config(startMinute: 9 * 60, endMinute: 17 * 60, weekdays: [5])
        let plan = Reconcile.plan(
            config: config,
            state: PolicyStore.State(),
            now: date(2026, 1, 8, 18, 0),
            authorized: true,
            calendar: calendar
        )
        XCTAssertEqual(plan, .unchanged)
    }
    
    func testOvernightScheduleStartsBeforeMidnight() {
        let config = config(startMinute: 22 * 60, endMinute: 7 * 60, weekdays: [2])
        let now = date(2026, 1, 5, 23, 0)
        let plan = Reconcile.plan(config: config, state: PolicyStore.State(), now: now, authorized: true, calendar: calendar)
        guard case .start(let session) = plan else {
            return XCTFail("expected start, got \(plan)")
        }
        XCTAssertEqual(session.scheduleEnd, date(2026, 1, 6, 7, 0))
    }
    
    func testOvernightScheduleStillActiveAfterMidnightOnUnselectedWeekday() {
        let config = config(startMinute: 22 * 60, endMinute: 7 * 60, weekdays: [2])
        let now = date(2026, 1, 6, 3, 0)
        let plan = Reconcile.plan(config: config, state: PolicyStore.State(), now: now, authorized: true, calendar: calendar)
        guard case .start(let session) = plan else {
            return XCTFail("expected start after midnight, got \(plan)")
        }
        XCTAssertEqual(session.scheduleEnd, date(2026, 1, 6, 7, 0))
    }
    
    func testScheduledSessionEndsAtWindowEnd() {
        let config = config(startMinute: 9 * 60, endMinute: 17 * 60, weekdays: [5])
        let end = date(2026, 1, 8, 17, 0)
        let state = PolicyStore.State(active: ActiveSession(
            modeID: modeID,
            source: .schedule(scheduleID),
            startedAt: date(2026, 1, 8, 9, 0),
            scheduleEnd: end
        ))
        let plan = Reconcile.plan(config: config, state: state, now: date(2026, 1, 8, 17, 0), authorized: true, calendar: calendar)
        XCTAssertEqual(plan, .end(.scheduleEnd, at: end))
    }
    
    func testOverrideBlocksScheduleRestart() {
        let config = config(startMinute: 9 * 60, endMinute: 17 * 60, weekdays: [5])
        let state = PolicyStore.State(
            override: ScheduleOverride(scheduleID: scheduleID, until: date(2026, 1, 8, 17, 0))
        )
        let plan = Reconcile.plan(
            config: config,
            state: state,
            now: date(2026, 1, 8, 10, 0),
            authorized: true,
            calendar: calendar
        )
        XCTAssertEqual(plan, .unchanged)
    }
    
    func testOpenEndedScheduleStartsWithNilEnd() {
        let mode = BlockMode(id: modeID, name: "Work", kind: .block)
        let schedule = BlockSchedule(
            id: scheduleID,
            name: "Hours",
            weekdays: [5],
            startMinute: 9 * 60,
            endMinute: 17 * 60,
            modeID: modeID,
            isOn: true,
            endsOnKey: true
        )
        let config = PolicyStore.Config(modes: [mode], schedules: [schedule], activeModeID: modeID)
        let now = date(2026, 1, 8, 10, 0)
        let plan = Reconcile.plan(config: config, state: PolicyStore.State(), now: now, authorized: true, calendar: calendar)
        
        guard case .start(let session) = plan else {
            return XCTFail("expected start, got \(plan)")
        }
        XCTAssertEqual(session.modeID, modeID)
        XCTAssertNil(session.scheduleEnd, "Open-ended schedule should have nil scheduleEnd")
    }
    
    func testOpenEndedScheduleDoesNotEndAtScheduledTime() {
        let mode = BlockMode(id: modeID, name: "Work", kind: .block)
        let schedule = BlockSchedule(
            id: scheduleID,
            name: "Hours",
            weekdays: [5],
            startMinute: 9 * 60,
            endMinute: 17 * 60,
            modeID: modeID,
            isOn: true,
            endsOnKey: true
        )
        let config = PolicyStore.Config(modes: [mode], schedules: [schedule], activeModeID: modeID)
        let state = PolicyStore.State(
            active: ActiveSession(
                modeID: modeID,
                source: .schedule(scheduleID),
                startedAt: date(2026, 1, 8, 9, 0),
                scheduleEnd: nil
            )
        )
        
        let plan = Reconcile.plan(
            config: config,
            state: state,
            now: date(2026, 1, 8, 18, 0),
            authorized: true,
            calendar: calendar
        )
        XCTAssertEqual(plan, .unchanged, "Open-ended schedule should not end at scheduled time")
    }
    
    func testOpenEndedScheduleEndsOnKeyTap() {
        let mode = BlockMode(id: modeID, name: "Work", kind: .block)
        let schedule = BlockSchedule(
            id: scheduleID,
            name: "Hours",
            weekdays: [5],
            startMinute: 9 * 60,
            endMinute: 17 * 60,
            modeID: modeID,
            isOn: true,
            endsOnKey: true
        )
        let config = PolicyStore.Config(modes: [mode], schedules: [schedule], activeModeID: modeID)
        let state = PolicyStore.State(
            active: ActiveSession(
                modeID: modeID,
                source: .schedule(scheduleID),
                startedAt: date(2026, 1, 8, 9, 0),
                scheduleEnd: nil
            )
        )
        
        // User taps key - ends the session manually
        let plan = Reconcile.plan(
            config: config,
            state: state,
            now: date(2026, 1, 8, 12, 0),
            authorized: true,
            calendar: calendar
        )
        XCTAssertEqual(plan, .unchanged)
    }
    
    // MARK: - Key unblock during a scheduled window (1.0.1 bug)
    
    /// Hour into a 09:00–17:00 window: key end must clear the session and set
    /// an override through 17:00 so shields stay off for the rest of the window.
    func testKeyUnblockDuringScheduledWindowClearsAndSuppresses() {
        let config = config(startMinute: 9 * 60, endMinute: 17 * 60, weekdays: [5])
        let windowEnd = date(2026, 1, 8, 17, 0)
        let unblockAt = date(2026, 1, 8, 10, 0)
        let active = PolicyStore.State(active: ActiveSession(
            modeID: modeID,
            source: .schedule(scheduleID),
            startedAt: date(2026, 1, 8, 9, 0),
            scheduleEnd: windowEnd
        ))
        
        let ended = Reconcile.ending(active, config: config, reason: .key, at: unblockAt, calendar: calendar)
        guard let ended else {
            return XCTFail("key end should clear the active scheduled session")
        }
        XCTAssertNil(ended.active, "session cleared — shields must come down")
        XCTAssertEqual(ended.lastEnd, unblockAt)
        XCTAssertEqual(ended.override?.scheduleID, scheduleID)
        XCTAssertEqual(ended.override?.until, windowEnd)
        
        // Same window: Monitor intervalDidStart / foreground reconcile must not re-arm.
        let midWindow = Reconcile.plan(
            config: config,
            state: ended,
            now: date(2026, 1, 8, 14, 0),
            authorized: true,
            calendar: calendar
        )
        XCTAssertEqual(midWindow, .unchanged, "must not re-arm inside the same window")
    }
    
    func testKeyUnblockDoesNotRestartTimerViaLastEnd() {
        // Regression: without an override, plan() would .start again with
        // startedAt = lastEnd, which resets the "Blocked for" clock.
        let config = config(startMinute: 9 * 60, endMinute: 17 * 60, weekdays: [5])
        let unblockAt = date(2026, 1, 8, 10, 0)
        let ended = Reconcile.ending(
            PolicyStore.State(active: ActiveSession(
                modeID: modeID,
                source: .schedule(scheduleID),
                startedAt: date(2026, 1, 8, 9, 0),
                scheduleEnd: date(2026, 1, 8, 17, 0)
            )),
            config: config,
            reason: .key,
            at: unblockAt,
            calendar: calendar
        )!
        
        let plan = Reconcile.plan(
            config: config,
            state: ended,
            now: unblockAt,
            authorized: true,
            calendar: calendar
        )
        if case .start = plan {
            XCTFail("key unblock must not immediately start a new session (timer restart)")
        } else {
            XCTAssertEqual(plan, .unchanged)
        }
    }
    
    func testNextOccurrenceStillBlocksAfterKeyUnblock() {
        let config = config(startMinute: 9 * 60, endMinute: 17 * 60, weekdays: [5])
        let ended = Reconcile.ending(
            PolicyStore.State(active: ActiveSession(
                modeID: modeID,
                source: .schedule(scheduleID),
                startedAt: date(2026, 1, 8, 9, 0),
                scheduleEnd: date(2026, 1, 8, 17, 0)
            )),
            config: config,
            reason: .key,
            at: date(2026, 1, 8, 10, 0),
            calendar: calendar
        )!
        
        // Next Friday 10:00 — override expired at previous Friday 17:00.
        let nextWeek = date(2026, 1, 15, 10, 0)
        let plan = Reconcile.plan(
            config: config,
            state: ended,
            now: nextWeek,
            authorized: true,
            calendar: calendar
        )
        guard case .start(let session) = plan else {
            return XCTFail("next occurrence should block, got \(plan)")
        }
        XCTAssertEqual(session.modeID, modeID)
        if case .schedule(let id) = session.source {
            XCTAssertEqual(id, scheduleID)
        } else {
            XCTFail("expected schedule source")
        }
        XCTAssertEqual(session.scheduleEnd, date(2026, 1, 15, 17, 0))
    }
    
    func testScheduledEndStillAutoUnblocksAfterPriorKeyLogic() {
        // Auto end at window end is unchanged by the key-override path.
        let config = config(startMinute: 9 * 60, endMinute: 17 * 60, weekdays: [5])
        let end = date(2026, 1, 8, 17, 0)
        let state = PolicyStore.State(active: ActiveSession(
            modeID: modeID,
            source: .schedule(scheduleID),
            startedAt: date(2026, 1, 8, 9, 0),
            scheduleEnd: end
        ))
        XCTAssertEqual(
            Reconcile.plan(config: config, state: state, now: end, authorized: true, calendar: calendar),
            .end(.scheduleEnd, at: end)
        )
        
        // After a natural schedule end (no key override), the next day still starts.
        let afterEnd = Reconcile.ending(state, config: config, reason: .scheduleEnd, at: end, calendar: calendar)!
        XCTAssertNil(afterEnd.override, "scheduleEnd must not suppress the next window")
        let nextDay = Reconcile.plan(
            config: config,
            state: afterEnd,
            now: date(2026, 1, 15, 10, 0),
            authorized: true,
            calendar: calendar
        )
        guard case .start = nextDay else {
            return XCTFail("next occurrence after auto-end should block, got \(nextDay)")
        }
    }
    
    func testKeyUnblockOfManualSessionDoesNotSetScheduleOverride() {
        let config = config(startMinute: 9 * 60, endMinute: 17 * 60, weekdays: [5])
        let ended = Reconcile.ending(
            PolicyStore.State(active: ActiveSession(
                modeID: modeID,
                source: .hold,
                startedAt: date(2026, 1, 8, 10, 0)
            )),
            config: config,
            reason: .key,
            at: date(2026, 1, 8, 11, 0),
            calendar: calendar
        )!
        XCTAssertNil(ended.active)
        XCTAssertNil(ended.override)
        
        // A live schedule window with no override should still start.
        let plan = Reconcile.plan(
            config: config,
            state: ended,
            now: date(2026, 1, 8, 11, 0),
            authorized: true,
            calendar: calendar
        )
        guard case .start = plan else {
            return XCTFail("ending a manual session must not suppress an active schedule, got \(plan)")
        }
    }
    
    func testKeyUnblockOfOpenEndedScheduleSuppressesRestOfWindow() {
        let mode = BlockMode(id: modeID, name: "Work", kind: .block)
        let schedule = BlockSchedule(
            id: scheduleID,
            name: "Hours",
            weekdays: [5],
            startMinute: 9 * 60,
            endMinute: 17 * 60,
            modeID: modeID,
            isOn: true,
            endsOnKey: true
        )
        let config = PolicyStore.Config(modes: [mode], schedules: [schedule], activeModeID: modeID)
        let unblockAt = date(2026, 1, 8, 12, 0)
        let ended = Reconcile.ending(
            PolicyStore.State(active: ActiveSession(
                modeID: modeID,
                source: .schedule(scheduleID),
                startedAt: date(2026, 1, 8, 9, 0),
                scheduleEnd: nil
            )),
            config: config,
            reason: .key,
            at: unblockAt,
            calendar: calendar
        )!
        XCTAssertNil(ended.active)
        XCTAssertNotNil(ended.override, "open-ended key end must still suppress the current window")
        XCTAssertEqual(
            Reconcile.plan(config: config, state: ended, now: date(2026, 1, 8, 15, 0), authorized: true, calendar: calendar),
            .unchanged
        )
    }
}

/// Configs written by older builds (no `rules.blockAddingKeys`, no
/// `schedules[].endsOnKey`) must still load in full.
final class ConfigCompatibilityTests: XCTestCase {
    static let oldFormatConfig = """
    {
      "keys": [
        {"addedAt": 813273264.07, "secret": "04a1b2c3d4e5f6", "name": "Desk Key",
         "id": "4E3D5D28-684D-4813-9E33-27DB06CF7FDD", "kind": "openBlockerTag"},
        {"addedAt": 812668464.07, "secret": "demo-qr-789", "name": "Gym QR",
         "id": "C00D861E-0FBC-4DAB-A44B-028D076A21B9", "kind": "qr"}
      ],
      "activeModeID": "4D6F7BE8-B80A-49AA-9EB7-93C79ABB402D",
      "modes": [
        {"name": "Detox", "id": "4D6F7BE8-B80A-49AA-9EB7-93C79ABB402D", "isDefault": true,
         "typedDomains": [], "kind": "allowOnly"}
      ],
      "schedules": [
        {"modeID": "4D6F7BE8-B80A-49AA-9EB7-93C79ABB402D", "name": "Work Hours",
         "id": "3184C1C7-E7C0-4FA0-9B98-F34466BDC9F7", "isOn": true,
         "startMinute": 540, "endMinute": 1020, "weekdays": [2, 3, 4, 5, 6]}
      ],
      "rules": {"preventDelete": true, "blockInstalls": true, "blockPurchases": false, "blockAdultWeb": false}
    }
    """
    
    func testOldFormatConfigDecodesWithDefaults() throws {
        let config = try PolicyStore.decodeConfig(Data(Self.oldFormatConfig.utf8))
        XCTAssertEqual(config.modes.count, 1)
        XCTAssertEqual(config.keys.count, 2)
        XCTAssertEqual(config.schedules.count, 1)
        XCTAssertEqual(config.activeModeID, UUID(uuidString: "4D6F7BE8-B80A-49AA-9EB7-93C79ABB402D"))
        XCTAssertFalse(config.schedules[0].endsOnKey)
        XCTAssertEqual(config.schedules[0].endMinute, 1020)
        XCTAssertTrue(config.rules.blockInstalls, "existing rule values are kept")
        XCTAssertTrue(config.rules.blockAddingKeys, "new rule defaults to on")
    }
    
    func testOldConfigFileLoadsAndSurvivesRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("config.json")
        try Data(Self.oldFormatConfig.utf8).write(to: url)
        let config = PolicyStore.loadConfig(from: url)
        XCTAssertNil(PolicyStore.lastConfigLoadError)
        XCTAssertEqual(config.keys.count, 2)
        let reencoded = try PolicyStore.decodeConfig(JSONEncoder().encode(config))
        XCTAssertEqual(reencoded.keys.count, 2)
        XCTAssertEqual(reencoded.modes.count, 1)
    }
    
    func testMissingTopLevelKeysUseDefaults() throws {
        let config = try PolicyStore.decodeConfig(Data(#"{"keys": []}"#.utf8))
        XCTAssertTrue(config.modes.isEmpty)
        XCTAssertTrue(config.rules.preventDelete)
        XCTAssertTrue(config.rules.blockAddingKeys)
    }
    
    func testUndecodableConfigIsBackedUpNotLost() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("config.json")
        let garbage = Data(#"{"modes": "not-an-array"}"#.utf8)
        try garbage.write(to: url)
        let config = PolicyStore.loadConfig(from: url)
        XCTAssertNotNil(PolicyStore.lastConfigLoadError)
        XCTAssertTrue(config.modes.isEmpty)
        let backups = try FileManager.default.contentsOfDirectory(atPath: dir.path)
            .filter { $0.hasPrefix("config.corrupt-") }
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: dir.appendingPathComponent(backups[0])), garbage)
        XCTAssertEqual(try Data(contentsOf: url), garbage, "the original file is left in place")
    }
}

/// The anonymous count: one "block_completed" event per finished block,
/// always with the same random install ID, and nothing else.
@MainActor
final class AnonymousCountTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    private let endpoint = URL(string: "https://example.invalid/api/count")!
    
    override func setUp() {
        suite = "count-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }
    
    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }
    
    private func record(_ reason: SessionRecord.EndReason) -> SessionRecord {
        SessionRecord(modeID: UUID(), source: .hold, start: Date(timeIntervalSince1970: 0), end: Date(timeIntervalSince1970: 60), endedBy: reason)
    }
    
    private func bodies(_ requests: [URLRequest]) -> [[String: String]] {
        requests.compactMap { try? JSONSerialization.jsonObject(with: $0.httpBody ?? Data()) as? [String: String] }
    }
    
    func testPayloadCarriesOnlyAnonymousFields() {
        let r = record(.key)
        let payload = CountManager.payload(for: r, installId: "ABC", appVersion: "1.0.0")
        XCTAssertEqual(Set(payload.keys), ["installId", "event", "eventId", "appVersion", "platform"])
        XCTAssertEqual(payload["event"], "block_completed")
        XCTAssertEqual(payload["eventId"], r.id.uuidString)
    }
    
    func testOnlyCompletedBlocksCount() {
        let history = [record(.key), record(.scheduleEnd), record(.passage), record(.emergency), record(.accessRevoked)]
        XCTAssertEqual(CountManager.completed(in: history, excluding: []).count, 3)
        XCTAssertEqual(CountManager.completed(in: history, excluding: [history[0].id]).count, 2)
    }
    
    func testEachCompletedBlockSendsOneEventWithTheSameInstallID() async {
        var sent: [URLRequest] = []
        let manager = CountManager(defaults: defaults, endpoint: endpoint) { sent.append($0); return .delivered }
        await manager.reportCompletedBlocks(in: []) // first run sets the baseline
        
        var history = [record(.key), record(.scheduleEnd)]
        await manager.reportCompletedBlocks(in: history)
        await manager.reportCompletedBlocks(in: history) // nothing new: no resend
        history.append(record(.emergency))              // not a completed block
        history.append(record(.key))
        await manager.reportCompletedBlocks(in: history)
        
        let events = bodies(sent)
        XCTAssertEqual(events.count, 3, "one event per completed block")
        XCTAssertEqual(Set(events.compactMap { $0["installId"] }).count, 1, "one install ID per phone")
        XCTAssertEqual(sent.first?.url, endpoint)
        XCTAssertEqual(sent.first?.httpMethod, "POST")
        
        // The two metrics the server derives.
        let otherPhone = CountManager.payload(for: record(.key), installId: "OTHER", appVersion: "1")
        let metrics = CountManager.metrics(from: events + [otherPhone, events[0]]) // events[0] is a duplicate retry
        XCTAssertEqual(metrics.people, 2, "unique people who completed at least one block")
        XCTAssertEqual(metrics.blocks, 4, "total blocks completed, retries not double-counted")
    }
    
    func testFailedSendRetriesLater() async {
        var ok = false
        var sent = 0
        let manager = CountManager(defaults: defaults, endpoint: endpoint) { _ in sent += 1; return ok ? .delivered : .retry }
        await manager.reportCompletedBlocks(in: [])
        let history = [record(.key)]
        await manager.reportCompletedBlocks(in: history)
        ok = true
        await manager.reportCompletedBlocks(in: history)
        await manager.reportCompletedBlocks(in: history)
        XCTAssertEqual(sent, 2, "failed once, sent once, then nothing pending")
    }
    
    func testNothingSentWhenOffOrEndpointUnset() async {
        var sent = 0
        let noEndpoint = CountManager(defaults: defaults, endpoint: nil) { _ in sent += 1; return .delivered }
        await noEndpoint.reportCompletedBlocks(in: [])
        await noEndpoint.reportCompletedBlocks(in: [record(.key)])
        
        let off = CountManager(defaults: defaults, endpoint: endpoint) { _ in sent += 1; return .delivered }
        off.setEnabled(false)
        await off.reportCompletedBlocks(in: [record(.key)])
        XCTAssertEqual(sent, 0)
        XCTAssertTrue(CountManager.enabledByDefault)
    }
    
    func testBlocksFinishedBeforeTheFeatureAreNotSent() async {
        var sent = 0
        let manager = CountManager(defaults: defaults, endpoint: endpoint) { _ in sent += 1; return .delivered }
        let old = [record(.key), record(.key)]
        await manager.reportCompletedBlocks(in: old)
        await manager.reportCompletedBlocks(in: old)
        XCTAssertEqual(sent, 0)
    }
    
    func testStatusCodesMapToDelivery() {
        XCTAssertEqual(CountManager.delivery(forStatus: 200), .delivered)
        XCTAssertEqual(CountManager.delivery(forStatus: 201), .delivered)
        XCTAssertEqual(CountManager.delivery(forStatus: 409), .delivered, "duplicate = already stored")
        XCTAssertEqual(CountManager.delivery(forStatus: 400), .dropped)
        XCTAssertEqual(CountManager.delivery(forStatus: 429), .retry)
        XCTAssertEqual(CountManager.delivery(forStatus: 500), .retry)
    }
    
    func testDuplicateAndRejectedEventsAreNotResent() async {
        var responses: [CountManager.Delivery] = [.delivered, .dropped]
        var sent = 0
        let manager = CountManager(defaults: defaults, endpoint: endpoint) { _ in sent += 1; return responses.removeFirst() }
        await manager.reportCompletedBlocks(in: [])
        let history = [record(.key), record(.key)]
        await manager.reportCompletedBlocks(in: history)
        await manager.reportCompletedBlocks(in: history)
        XCTAssertEqual(sent, 2, "a 409 or 400 is final; nothing is resent")
    }
}

/// Real end-to-end check against the live count server. Runs only when
/// OB_LIVE_COUNT_TEST=1 is set (never in normal test runs).
@MainActor
final class LiveCountEndpointTests: XCTestCase {
    func testLiveEndpointAcceptsThenDeduplicates() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["OB_LIVE_COUNT_TEST"] == "1", "live test disabled")
        let endpoint = try XCTUnwrap(CountManager.endpoint, "COUNT_ENDPOINT not set in this build")
        let suite = "live-count-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        
        var statuses: [Int] = []
        let transport: CountManager.Transport = { request in
            guard let (_, response) = try? await URLSession.shared.data(for: request),
                  let http = response as? HTTPURLResponse else { return .retry }
            statuses.append(http.statusCode)
            return CountManager.delivery(forStatus: http.statusCode)
        }
        let manager = CountManager(defaults: defaults, endpoint: endpoint, transport: transport)
        await manager.reportCompletedBlocks(in: []) // baseline
        let record = SessionRecord(modeID: UUID(), source: .hold, start: Date().addingTimeInterval(-60), end: Date(), endedBy: .key)
        await manager.reportCompletedBlocks(in: [record])
        let installId = try XCTUnwrap(manager.installId)
        print("[LiveCount] installId=\(installId) eventId=\(record.id.uuidString) first=\(statuses)")
        
        // Resend the same event directly: the server must answer 409.
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: CountManager.payload(
            for: record, installId: installId,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"))
        let (_, response) = try await URLSession.shared.data(for: request)
        let second = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("[LiveCount] resend=\(second)")
        
        XCTAssertEqual(statuses, [200])
        XCTAssertEqual(second, 409)
        XCTAssertEqual(CountManager.delivery(forStatus: second), .delivered)
    }
}
