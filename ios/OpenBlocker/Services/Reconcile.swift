// Adapted from Careful (MIT, (c) 2026 Alexander Montague): careful-ios/Shared/CarefulBlocker.swift

import Foundation
import os
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
    
    /// What this process can tell about Screen Time access right now.
    ///
    /// `AuthorizationCenter.authorizationStatus` starts as `.notDetermined` in
    /// every new process and is only filled in after `requestAuthorization`
    /// runs (Apple's docs: "The initial value is always notDetermined"). A
    /// relaunch after the app was swiped away is a new process, so
    /// `.notDetermined` is `.unknown`, never proof that access was revoked.
    enum ScreenTimeAccess: Equatable {
        case approved
        case revoked
        case unknown
        
        #if !EXTENSION
        init(_ status: AuthorizationStatus) {
            switch status {
            case .approved: self = .approved
            case .denied: self = .revoked
            default: self = .unknown
            }
        }
        #endif
    }
    
    /// Pure decision used by the app, the Monitor extension, and tests.
    static func plan(
        config: PolicyStore.Config,
        state: PolicyStore.State,
        now: Date,
        screenTime: ScreenTimeAccess,
        calendar: Calendar = .current
    ) -> Plan {
        // Only an explicit denial ends a session. Unknown keeps the block:
        // iOS itself drops every shield if access really was revoked.
        if screenTime == .revoked, state.active != nil {
            return .end(.accessRevoked, at: now)
        }
        
        if let session = state.active,
           case .schedule = session.source,
           let end = session.scheduleEnd,
           now >= end {
            return .end(.scheduleEnd, at: end)
        }
        
        // Check every active window: one that was ended by key today must not
        // hide another schedule or limit that is also active now.
        if state.active == nil,
           let window = activeWindows(at: now, config: config, limitReached: state.limitReached ?? [:], keepOn: blockingIDs(state), calendar: calendar)
               .first(where: { shouldStartSchedule($0, state: state, now: now) && $0.schedule.modeID != nil }),
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
    
    /// What to do with the shield after planning.
    enum ShieldAction: Equatable {
        case apply(BlockMode.ID)
        case clear
        /// Leave whatever iOS is enforcing as it is.
        case keep
    }
    
    /// Pure: never clear while a session is active. If the session's mode
    /// can't be found (config unreadable), keep the shield already in place.
    static func shieldAction(state: PolicyStore.State, config: PolicyStore.Config) -> ShieldAction {
        guard let session = state.active else { return .clear }
        guard config.mode(session.modeID) != nil else { return .keep }
        return .apply(session.modeID)
    }
    
    /// DeviceActivity can call `intervalDidStart` a little before the exact
    /// start minute. When the starting activity's window opens that soon,
    /// treat it as open so the block starts on time instead of never.
    static func monitorStartTime(
        startingActivity: String,
        config: PolicyStore.Config,
        now: Date,
        tolerance: TimeInterval = 120,
        calendar: Calendar = .current
    ) -> Date {
        guard let schedule = config.schedules.first(where: { $0.id.uuidString == startingActivity }),
              !schedule.isLimit else { return now }
        let opensNow = ScheduleInterval.window(
            startMinute: schedule.startMinute, endMinute: schedule.effectiveEndMinute,
            weekdays: schedule.weekdays, at: now, calendar: calendar
        ) != nil
        if opensNow { return now }
        let soon = now.addingTimeInterval(tolerance)
        guard let span = ScheduleInterval.window(
            startMinute: schedule.startMinute, endMinute: schedule.effectiveEndMinute,
            weekdays: schedule.weekdays, at: soon, calendar: calendar
        ), span.start > now else { return now }
        return span.start
    }
    
    /// DeviceActivity can call `intervalDidEnd` a little before the exact end
    /// minute. When the ending activity is the active schedule and its end is
    /// that close, treat the end as reached so the block lifts on time.
    static func monitorEndTime(
        endingActivity: String?,
        state: PolicyStore.State,
        now: Date,
        tolerance: TimeInterval = 120
    ) -> Date {
        guard let endingActivity,
              let session = state.active,
              case .schedule(let scheduleID) = session.source,
              scheduleID.uuidString == endingActivity,
              let end = session.scheduleEnd,
              now < end,
              end.timeIntervalSince(now) <= tolerance
        else { return now }
        return end
    }
    
    /// Compute the correct shield state and apply it. Returns the active mode if blocking.
    /// Pass `config` when the caller already has it in memory (the app does),
    /// so launch doesn't read and decode config.json twice.
    /// `endingActivity` is the DeviceActivity name from `intervalDidEnd`.
    @discardableResult
    static func reconcile(
        now: Date = Date(),
        config knownConfig: PolicyStore.Config? = nil,
        endingActivity: String? = nil,
        startingActivity: String? = nil
    ) -> BlockMode? {
        #if EXTENSION
        // Without the shared container the extension would read an empty
        // private folder, see no session, and clear the app's block.
        guard PolicyStore.usesAppGroup else {
            print("[Reconcile] App Group unavailable in extension; leaving shields untouched")
            return nil
        }
        #endif
        
        var state: PolicyStore.State
        switch PolicyStore.loadStateResult() {
        case .loaded(let loaded):
            state = loaded
        case .missing:
            state = PolicyStore.State()
        case .unreadable:
            // Unknown is not "not blocking": don't clear, don't overwrite.
            print("[Reconcile] state.json unreadable; leaving shields untouched")
            return nil
        }
        let config = knownConfig ?? PolicyStore.loadConfig()
        
        var screenTime = ScreenTimeAccess.approved
        #if !EXTENSION
        #if !targetEnvironment(simulator)
        screenTime = ScreenTimeAccess(AuthorizationCenter.shared.authorizationStatus)
        #endif
        #endif
        
        let effectiveNow = startingActivity.map {
            monitorStartTime(startingActivity: $0, config: config, now: now)
        } ?? monitorEndTime(endingActivity: endingActivity, state: state, now: now)
        
        let decision = plan(config: config, state: state, now: effectiveNow, screenTime: screenTime)
        ScheduleLog.log.notice("reconcile now=\(now, privacy: .public) effective=\(effectiveNow, privacy: .public) start=\(startingActivity ?? "-", privacy: .public) end=\(endingActivity ?? "-", privacy: .public) active=\(state.active != nil) override=\(state.override != nil) more=\(state.moreOverrides?.count ?? 0) schedulesOn=\(config.schedules.filter(\.isOn).count) plan=\(String(describing: decision), privacy: .public)")
        switch decision {
        case .unchanged:
            break
        case .start(let session):
            state.active = session
            PolicyStore.save(state)
        case .end(let reason, let at):
            endSession(&state, config: config, reason: reason, at: at)
            // Another schedule or limit may still be on: start it right away.
            if case .start(let next) = plan(config: config, state: state, now: effectiveNow, screenTime: screenTime) {
                state.active = next
            }
            PolicyStore.save(state)
        }
        
        let result: BlockMode?
        switch shieldAction(state: state, config: config) {
        case .apply(let modeID):
            if let mode = config.mode(modeID) {
                BlockEngine.apply(mode, rules: config.rules)
            }
            result = config.mode(modeID)
        case .keep:
            print("[Reconcile] active session's mode not found; keeping current shield")
            result = nil
        case .clear:
            BlockEngine.clear()
            result = nil
        }
        
        // Everything else that is on right now blocks too.
        let extras = extraWindows(state: state, config: config, now: effectiveNow).compactMap { window in
            window.schedule.modeID.flatMap(config.mode).map { (id: window.schedule.id.uuidString, mode: $0) }
        }
        let previous = state.extraShields ?? []
        BlockEngine.applyExtras(extras, rules: config.rules, previous: previous)
        let ids = extras.map(\.id)
        if ids != previous {
            state.extraShields = ids.isEmpty ? nil : ids
            PolicyStore.save(state)
        }
        return result
    }
    
    /// Schedules and limits that are on now next to the active block. Each
    /// adds its own shield; one unblock suppresses them all.
    static func extraWindows(
        state: PolicyStore.State,
        config: PolicyStore.Config,
        now: Date,
        calendar: Calendar = .current
    ) -> [ScheduleWindow] {
        guard let session = state.active else { return [] }
        var ownID: UUID?
        if case .schedule(let id) = session.source { ownID = id }
        return activeWindows(at: now, config: config, limitReached: state.limitReached ?? [:], keepOn: blockingIDs(state), calendar: calendar)
            .filter { $0.schedule.id != ownID && $0.schedule.modeID != nil && shouldStartSchedule($0, state: state, now: now) }
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
            limitReached: state.limitReached ?? [:],
            calendar: calendar
        ) {
            next.override = override
        }
        if reason == .key {
            suppressActiveWindows(&next, config: config, at: time, calendar: calendar)
        }
        return next
    }
    
    /// One unblock ends everything: every schedule or limit active at `time`
    /// stays off until its own end, so none of them re-arms the block.
    static func suppressActiveWindows(
        _ state: inout PolicyStore.State,
        config: PolicyStore.Config,
        at time: Date,
        calendar: Calendar = .current
    ) {
        var list = (state.moreOverrides ?? []).filter { $0.until > time }
        let windows = activeWindows(at: time, config: config, limitReached: state.limitReached ?? [:], keepOn: blockingIDs(state), calendar: calendar)
        for window in windows where shouldStartSchedule(window, state: state, now: time) {
            list.removeAll { $0.scheduleID == window.schedule.id }
            list.append(ScheduleOverride(scheduleID: window.schedule.id, until: window.end))
        }
        state.moreOverrides = list.isEmpty ? nil : list
    }
    
    /// After a key ends a scheduled session early, suppress the rest of that
    /// window so Monitor `intervalDidStart` / app reconcile cannot re-arm it.
    /// The next occurrence (override expired) still starts normally.
    static func scheduleOverride(
        afterEnding session: ActiveSession,
        reason: SessionRecord.EndReason,
        at time: Date,
        config: PolicyStore.Config,
        limitReached: [String: Date] = [:],
        calendar: Calendar = .current
    ) -> ScheduleOverride? {
        guard reason == .key else { return nil }
        guard case .schedule(let scheduleID) = session.source else { return nil }
        let until = session.scheduleEnd ?? activeWindows(at: time, config: config, limitReached: limitReached, calendar: calendar)
            .first(where: { $0.schedule.id == scheduleID })?.end
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
    
    /// Every schedule window active at a given time, in list order.
    static func activeWindows(
        at now: Date,
        config: PolicyStore.Config,
        limitReached: [String: Date] = [:],
        keepOn: Set<String> = [],
        calendar: Calendar = .current
    ) -> [ScheduleWindow] {
        var windows: [ScheduleWindow] = []
        // Switching off something that is blocking right now must not lift
        // it: it counts as on until its window ends or the key is used.
        for schedule in config.schedules where schedule.isOn || keepOn.contains(schedule.id.uuidString) {
            guard let span = ScheduleInterval.window(
                startMinute: schedule.startMinute,
                endMinute: schedule.effectiveEndMinute,
                weekdays: schedule.weekdays,
                at: now,
                calendar: calendar
            ) else { continue }
            guard schedule.isLimit else {
                windows.append(ScheduleWindow(schedule: schedule, start: span.start, end: span.end))
                continue
            }
            // A daily limit only blocks once it was used up in this window
            // (and never without apps to count).
            if config.dailyLimit(for: schedule) != nil,
               let hit = limitReached[schedule.id.uuidString], hit >= span.start, hit <= now {
                windows.append(ScheduleWindow(schedule: schedule, start: hit, end: span.end))
            }
        }
        return windows
    }
    
    /// Schedules and limits blocking right now (the session's own and the extras).
    static func blockingIDs(_ state: PolicyStore.State) -> Set<String> {
        var ids = Set(state.extraShields ?? [])
        if let session = state.active, case .schedule(let id) = session.source {
            ids.insert(id.uuidString)
        }
        return ids
    }
    
    /// Called by the Monitor extension when a schedule's daily limit is used up.
    static func limitReached(activity: String, now: Date = Date()) {
        var state: PolicyStore.State
        switch PolicyStore.loadStateResult() {
        case .loaded(let loaded): state = loaded
        case .missing: state = PolicyStore.State()
        case .unreadable: return
        }
        state.limitReached = (state.limitReached ?? [:]).merging([activity: now]) { $1 }
        PolicyStore.save(state)
        reconcile(now: now)
    }
    
    private static func shouldStartSchedule(
        _ window: ScheduleWindow,
        state: PolicyStore.State,
        now: Date
    ) -> Bool {
        // Don't start if there's an override for this schedule that hasn't expired
        let overrides = [state.override].compactMap { $0 } + (state.moreOverrides ?? [])
        return !overrides.contains { $0.scheduleID == window.schedule.id && $0.until > now }
    }
}

struct ScheduleWindow {
    let schedule: BlockSchedule
    let start: Date
    let end: Date
}

/// Shows up in the phone's system log (Console / `log collect`) under
/// subsystem org.openblocker, so schedule problems can be diagnosed.
enum ScheduleLog {
    static let log = Logger(subsystem: "org.openblocker", category: "schedule")
}
