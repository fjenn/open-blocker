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
                scheduleEnd: window.schedule.endsOnKey ? nil : window.end
            )
            return .start(session)
        }
        
        return .unchanged
    }
    
    /// Compute the correct shield state and apply it. Returns the active mode if blocking.
    @discardableResult
    /// Pass `config` when the caller already has it in memory (the app does),
    /// so launch doesn't read and decode config.json twice.
    static func reconcile(now: Date = Date(), config knownConfig: PolicyStore.Config? = nil) -> BlockMode? {
        var state = PolicyStore.loadState()
        let config = knownConfig ?? PolicyStore.loadConfig()
        
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
    
    /// Pure: clear the active session and, for a key end of a scheduled window,
    /// suppress re-arming until that window's end. History append is the caller's job.
    static func ending(
        _ state: PolicyStore.State,
        config: PolicyStore.Config,
        reason: SessionRecord.EndReason,
        at time: Date,
        calendar: Calendar = .current
    ) -> PolicyStore.State? {
        guard let session = state.active else { return nil }
        var next = state
        next.active = nil
        next.lastEnd = time
        if let override = scheduleOverride(
            afterEnding: session,
            reason: reason,
            at: time,
            config: config,
            calendar: calendar
        ) {
            next.override = override
        }
        return next
    }
    
    /// After a key ends a scheduled session early, suppress the rest of that
    /// window so Monitor `intervalDidStart` / app reconcile cannot re-arm it.
    /// The next occurrence (override expired) still starts normally.
    static func scheduleOverride(
        afterEnding session: ActiveSession,
        reason: SessionRecord.EndReason,
        at time: Date,
        config: PolicyStore.Config,
        calendar: Calendar = .current
    ) -> ScheduleOverride? {
        guard reason == .key else { return nil }
        guard case .schedule(let scheduleID) = session.source else { return nil }
        let until = session.scheduleEnd ?? activeWindow(at: time, config: config, calendar: calendar)
            .flatMap({ $0.schedule.id == scheduleID ? $0.end : nil })
        guard let until else { return nil }
        return ScheduleOverride(scheduleID: scheduleID, until: until)
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
        
        if let ended = ending(state, config: config, reason: reason, at: time) {
            state = ended
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
                endMinute: schedule.effectiveEndMinute,
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
