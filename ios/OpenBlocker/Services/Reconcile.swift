// Adapted from Careful (MIT, (c) 2026 Alexander Montague): careful-ios/Shared/CarefulBlocker.swift

import Foundation
import FamilyControls
import ManagedSettings

/// The single source of truth for what should be blocked right now.
/// Called on launch, foreground, after every action, and from DeviceActivity callbacks.
enum Reconcile {
    
    enum Plan: Equatable {
        case unchanged
        case start(ActiveSession)
        case end(SessionRecord.EndReason, at: Date)
    }
    
    /// Pure decision used by the app, the Monitor extension, and tests.
    static func plan(
        config: PolicyStore.Config,
        state: PolicyStore.State,
        now: Date,
        authorized: Bool,
        calendar: Calendar = .current
    ) -> Plan {
        if !authorized, state.active != nil {
            return .end(.accessRevoked, at: now)
        }
        
        if let session = state.active,
           case .schedule = session.source,
           let end = session.scheduleEnd,
           now >= end {
            return .end(.scheduleEnd, at: end)
        }
        
        if state.active == nil,
           let window = activeWindow(at: now, config: config, calendar: calendar),
           shouldStartSchedule(window, state: state, now: now),
           let modeID = window.schedule.modeID {
            let session = ActiveSession(
                modeID: modeID,
                source: .schedule(window.schedule.id),
                startedAt: max(window.start, state.lastEnd ?? window.start),
                scheduleEnd: window.end
            )
            return .start(session)
        }
        
        return .unchanged
    }
    
    /// Compute the correct shield state and apply it. Returns the active mode if blocking.
    @discardableResult
    static func reconcile(now: Date = Date()) -> BlockMode? {
        var state = PolicyStore.loadState()
        let config = PolicyStore.loadConfig()
        
        var authorized = true
        #if !EXTENSION
        #if !targetEnvironment(simulator)
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        #endif
        #endif
        
        switch plan(config: config, state: state, now: now, authorized: authorized) {
        case .unchanged:
            break
        case .start(let session):
            state.active = session
        case .end(let reason, let at):
            endSession(&state, config: config, reason: reason, at: at)
        }
        
        PolicyStore.save(state)
        
        if let session = state.active, let mode = config.mode(session.modeID) {
            BlockEngine.apply(mode, rules: config.rules)
            return mode
        } else {
            BlockEngine.clear()
            return nil
        }
    }
    
    /// End the current session and record it to history.
    private static func endSession(
        _ state: inout PolicyStore.State,
        config: PolicyStore.Config,
        reason: SessionRecord.EndReason,
        at time: Date
    ) {
        guard let session = state.active else { return }
        
        let record = SessionRecord(
            modeID: session.modeID,
            source: session.source,
            start: session.startedAt,
            end: time,
            endedBy: reason
        )
        PolicyStore.appendToHistory(record)
        
        state.active = nil
        state.lastEnd = time
        
        // Set override if this was a scheduled session ended early
        if case .schedule(let scheduleID) = session.source,
           reason == .key,
           let scheduleEnd = session.scheduleEnd {
            state.override = ScheduleOverride(scheduleID: scheduleID, until: scheduleEnd)
        }
    }
    
    /// Find the active schedule window at a given time.
    static func activeWindow(
        at now: Date,
        config: PolicyStore.Config,
        calendar: Calendar = .current
    ) -> ScheduleWindow? {
        for schedule in config.schedules where schedule.isOn {
            if let span = ScheduleInterval.window(
                startMinute: schedule.startMinute,
                endMinute: schedule.endMinute,
                weekdays: schedule.weekdays,
                at: now,
                calendar: calendar
            ) {
                return ScheduleWindow(schedule: schedule, start: span.start, end: span.end)
            }
        }
        return nil
    }
    
    private static func shouldStartSchedule(
        _ window: ScheduleWindow,
        state: PolicyStore.State,
        now: Date
    ) -> Bool {
        // Don't start if there's an override for this schedule that hasn't expired
        if let override = state.override,
           override.scheduleID == window.schedule.id,
           override.until > now {
            return false
        }
        return true
    }
}

struct ScheduleWindow {
    let schedule: BlockSchedule
    let start: Date
    let end: Date
}
