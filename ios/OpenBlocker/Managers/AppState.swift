// AppState using PolicyStore and reconcile() architecture

import Foundation
import FamilyControls
import Combine
import SwiftUI

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var config: PolicyStore.Config
    @Published var state: PolicyStore.State
    @Published var history: [SessionRecord]
    
    @Published var isAuthorized: Bool = false
    @Published var hasSeenOnboarding: Bool = false
    
    @Published var emergencyStatus: EmergencyUnblockManager.Status
    
    let nfcScanner: NFCScannerProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        #if DEBUG
        // Seed demo data BEFORE loading from PolicyStore
        if ProcessInfo.processInfo.arguments.contains("-demo") {
            print("[AppState] 🌱 Seeding demo data before initialization...")
            DemoData.setupDemo()
        }
        #endif
        
        self.config = PolicyStore.loadConfig()
        self.state = PolicyStore.loadState()
        self.history = PolicyStore.loadHistory()
        self.emergencyStatus = EmergencyUnblockManager.status()
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        #if targetEnvironment(simulator)
        self.nfcScanner = MockNFCScanner()
        #else
        self.nfcScanner = CoreNFCScanner()
        #endif
        
        checkAuthorization()
        EmergencyUnblockManager.refillIfNeeded()
        ScheduleMonitor.sync(config.schedules)
        reconcile()
        
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-demo") {
            if Self.isDemoBlockedLaunch {
                startDemoBlocking()
            } else {
                state.active = nil
                saveState()
            }
        }
        #endif
    }
    
    #if DEBUG
    static var isDemoBlockedLaunch: Bool {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("-demo") else { return false }
        if let i = args.firstIndex(of: "-screen"), i + 1 < args.count {
            let screen = args[i + 1]
            if screen == "home-blocked" || screen == "blocking" || screen == "activity" {
                return true
            }
        }
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count {
            return args[i + 1] == "activity"
        }
        return false
    }
    #endif
    
    // MARK: - Authorization
    
    func checkAuthorization() {
        Task {
            isAuthorized = await AuthorizationCenter.shared.authorizationStatus == .approved
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            await MainActor.run {
                isAuthorized = true
            }
            return true
        } catch {
            await MainActor.run {
                isAuthorized = false
            }
            return false
        }
    }
    
    // MARK: - Reconcile
    
    func reconcile() {
        let wasBlocking = state.active != nil
        _ = Reconcile.reconcile()
        state = PolicyStore.loadState()
        history = PolicyStore.loadHistory()
        if wasBlocking && state.active == nil {
            SessionNotify.notifyEnded()
        }
        if let end = state.active?.scheduleEnd {
            SessionNotify.scheduleEnd(at: end)
        } else {
            SessionNotify.cancelScheduledEnd()
        }
        objectWillChange.send()
    }
    
    func reload() {
        config = PolicyStore.loadConfig()
        state = PolicyStore.loadState()
        history = PolicyStore.loadHistory()
        emergencyStatus = EmergencyUnblockManager.status()
        reconcile()
        print("[AppState] ✓ Reloaded: \(config.modes.count) modes, \(config.keys.count) keys, \(history.count) history entries")
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding() {
        hasSeenOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }
    
    // MARK: - Modes
    
    var modes: [BlockMode] {
        config.modes
    }
    
    var activeMode: BlockMode? {
        guard let id = config.activeModeID else { return nil }
        return config.mode(id)
    }
    
    func setActiveMode(_ mode: BlockMode) {
        config.activeModeID = mode.id
        saveConfig()
    }
    
    func addMode(_ mode: BlockMode) {
        config.modes.append(mode)
        saveConfig()
    }
    
    func updateMode(_ mode: BlockMode) {
        if let index = config.modes.firstIndex(where: { $0.id == mode.id }) {
            config.modes[index] = mode
            saveConfig()
            reconcile()
        }
    }
    
    func deleteMode(_ mode: BlockMode) {
        guard !isBlocking else { return }
        guard !mode.isDefault else { return }
        
        config.modes.removeAll { $0.id == mode.id }
        
        if config.activeModeID == mode.id, let firstMode = config.modes.first {
            config.activeModeID = firstMode.id
        }
        
        saveConfig()
    }
    
    // MARK: - Keys
    
    var keys: [BlockKey] {
        config.keys
    }
    
    func addKey(_ key: BlockKey) {
        config.keys.append(key)
        saveConfig()
    }
    
    func deleteKey(_ key: BlockKey) {
        guard !isBlocking else { return }
        config.keys.removeAll { $0.id == key.id }
        saveConfig()
    }
    
    func matchKey(_ scannedKey: ScannedKey) -> BlockKey? {
        config.keys.first { $0.matches(scannedKey) }
    }
    
    // MARK: - Schedules
    
    var schedules: [BlockSchedule] {
        config.schedules
    }
    
    func addSchedule(_ schedule: BlockSchedule) {
        config.schedules.append(schedule)
        saveConfig()
        reconcile()
    }
    
    func updateSchedule(_ schedule: BlockSchedule) {
        if let index = config.schedules.firstIndex(where: { $0.id == schedule.id }) {
            config.schedules[index] = schedule
            saveConfig()
            reconcile()
        }
    }
    
    func deleteSchedule(_ schedule: BlockSchedule) {
        config.schedules.removeAll { $0.id == schedule.id }
        saveConfig()
        reconcile()
    }
    
    // MARK: - Rules
    
    var rules: Rules {
        get { config.rules }
        set {
            config.rules = newValue
            saveConfig()
            reconcile()
        }
    }
    
    // MARK: - Blocking
    
    var isBlocking: Bool {
        state.active != nil
    }
    
    var currentSession: ActiveSession? {
        state.active
    }
    
    func startBlockingWithKey(keyId: UUID) {
        guard let mode = activeMode else { return }
        guard !isBlocking else { return }
        
        let session = ActiveSession(
            modeID: mode.id,
            source: .key(keyId),
            startedAt: Date()
        )
        
        state.active = session
        saveState()
        reconcile()
        NotificationCenter.default.post(name: .sessionStarted, object: nil)
    }
    
    func startBlockingWithHold() {
        guard let mode = activeMode else { return }
        guard !isBlocking else { return }
        guard !keys.isEmpty else { return }
        
        let session = ActiveSession(
            modeID: mode.id,
            source: .hold,
            startedAt: Date()
        )
        
        state.active = session
        saveState()
        reconcile()
        NotificationCenter.default.post(name: .sessionStarted, object: nil)
    }
    
    #if DEBUG
    func startDemoBlocking() {
        let mode = activeMode ?? modes.first
        guard let mode else {
            print("[AppState] startDemoBlocking: no mode")
            return
        }
        let keyID = keys.first?.id ?? UUID()
        
        let session = ActiveSession(
            modeID: mode.id,
            source: .key(keyID),
            startedAt: Date().addingTimeInterval(-1800)
        )
        
        state.active = session
        saveState()
        objectWillChange.send()
        print("[AppState] Started demo blocking: mode=\(mode.name) elapsed=30m")
    }
    #endif
    
    func stopBlockingWithKey(keyId: UUID) -> Bool {
        guard isBlocking else { return false }
        guard let session = state.active else { return false }
        
        let record = SessionRecord(
            modeID: session.modeID,
            source: session.source,
            start: session.startedAt,
            end: Date(),
            endedBy: .key
        )
        
        PolicyStore.appendToHistory(record)
        history = PolicyStore.loadHistory()
        
        state.active = nil
        state.lastEnd = Date()
        saveState()
        SessionNotify.notifyEnded()
        reconcile()
        
        return true
    }
    
    func emergencyUnblock() -> Bool {
        if state.active == nil {
            state = PolicyStore.loadState()
        }
        guard isBlocking else { return false }
        guard let session = state.active else { return false }
        guard EmergencyUnblockManager.useOne() else { return false }
        
        let record = SessionRecord(
            modeID: session.modeID,
            source: session.source,
            start: session.startedAt,
            end: Date(),
            endedBy: .emergency
        )
        
        PolicyStore.appendToHistory(record)
        history = PolicyStore.loadHistory()
        
        state.active = nil
        state.lastEnd = Date()
        saveState()
        SessionNotify.notifyEnded()
        reconcile()
        
        emergencyStatus = EmergencyUnblockManager.status()
        
        return true
    }
    
    // MARK: - Statistics
    
    func todayBlockedTime() -> TimeInterval {
        focusStats(on: Date()).duration
    }
    
    func focusIntervals(now: Date = Date()) -> [FocusInterval] {
        var intervals = history.map { FocusInterval(start: $0.start, end: $0.end) }
        if let session = currentSession {
            intervals.append(FocusInterval(start: session.startedAt, end: now))
        }
        return intervals
    }
    
    func focusStats(on day: Date, now: Date = Date()) -> (duration: TimeInterval, sessions: Int) {
        FocusStats.onDay(day, intervals: focusIntervals(now: now), now: now, calendar: .current)
    }
    
    func weeklyAggregation(weekStart: Date) -> WeeklySessionAggregation {
        let now = Date()
        let intervals = history.compactMap { record -> WeeklySessionInterval? in
            let end = min(record.end, now)
            guard record.start < end else { return nil }
            return WeeklySessionInterval(startTime: record.start, endTime: end)
        }
        
        var allIntervals = intervals
        if let session = currentSession, session.startedAt < now {
            allIntervals.append(WeeklySessionInterval(startTime: session.startedAt, endTime: now))
        }
        
        return WeeklySessionAggregator.aggregate(sessions: allIntervals, weekStart: weekStart)
    }
    
    // MARK: - Persistence
    
    private func saveConfig() {
        PolicyStore.save(config)
        config = PolicyStore.loadConfig()
        ScheduleMonitor.sync(config.schedules)
    }
    
    private func saveState() {
        PolicyStore.save(state)
        state = PolicyStore.loadState()
    }
}
