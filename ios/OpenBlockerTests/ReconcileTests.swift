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
}
