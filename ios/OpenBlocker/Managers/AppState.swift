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
    @Published var history: [SessionRecord] {
        didSet { reportCompletedBlocks() }
    }
    
    @Published var isAuthorized: Bool = false
    @Published var hasSeenOnboarding: Bool = false
    
    @Published var emergencyStatus: EmergencyUnblockManager.Status
    
    /// Persistent successful NFC/QR key-unblock count for the StoreKit prompt.
    @Published private(set) var keyUnblockCount: Int = ReviewPrompt.keyUnblockCount()
    
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
        
        var config = PolicyStore.loadConfig()
        if let seeded = ModeDefaults.seeded(config) {
            config = seeded
            PolicyStore.save(config)
        }
        self.config = config
        self.state = PolicyStore.loadState()
        self.history = PolicyStore.loadHistory()
        EmergencyUnblockManager.renewIfDue()
        self.emergencyStatus = EmergencyUnblockManager.status()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetOnboarding") {
            UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
            UserDefaults.standard.removeObject(forKey: "onboardingAdultWebDefaultApplied")
        }
        #endif
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        #if targetEnvironment(simulator)
        self.nfcScanner = MockNFCScanner()
        #else
        self.nfcScanner = CoreNFCScanner()
        #endif
        
        checkAuthorization()
        // DeviceActivity registration is IPC; keep it off the launch path.
        let schedules = config.schedules
        Task.detached(priority: .utility) { ScheduleMonitor.sync(schedules) }
        reconcile()
        reportCompletedBlocks() // retries events that failed last time
        
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
    
    // MARK: - Anonymous count
    
    /// One anonymous event per completed block (see CountManager). Never in demo.
    private func reportCompletedBlocks() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-demo") { return }
        #endif
        #if targetEnvironment(simulator)
        // Simulator runs share demo history and test hosts; never send real
        // counts from them unless explicitly asked to.
        guard ProcessInfo.processInfo.environment["OB_SEND_COUNTS"] == "1" else { return }
        #endif
        let history = history
        Task { await CountManager.shared.reportCompletedBlocks(in: history) }
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() {
        isAuthorized = Permissions.screenTimeStatus == .granted
    }
    
    /// Asks for Screen Time. Returns whether iOS granted it (onboarding
    /// explains a no); builds that can't get it still count as authorized.
    func requestAuthorization() async -> Bool {
        let granted = (try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)) != nil
        isAuthorized = granted || Permissions.screenTimeUnavailable
        return granted
    }
    
    /// Launch and every return to the app: renew the emergency allowance
    /// when its period is over, and pick up permission changes from Settings.
    func appDidBecomeActive() {
        EmergencyUnblockManager.renewIfDue()
        emergencyStatus = EmergencyUnblockManager.status()
        checkAuthorization()
        reportCompletedBlocks()
        #if DEBUG
        Task { await Permissions.logStatuses() }
        #endif
    }
    
    // MARK: - Reconcile
    
    func reconcile() {
        let wasBlocking = state.active != nil
        let previousSessionID = state.active?.id
        _ = Reconcile.reconcile(config: config)
        state = PolicyStore.loadState()
        // History only changes when a session ended.
        if previousSessionID != nil && state.active?.id != previousSessionID {
            history = PolicyStore.loadHistory()
        }
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
    
    /// Rule "Don't allow adding new keys while blocked" (on by default).
    var canAddKeys: Bool {
        !(isBlocking && config.rules.blockAddingKeys)
    }
    
    func addKey(_ key: BlockKey) {
        guard canAddKeys else { return }
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
    
    /// Starts a session after a registered key was scanned.
    @discardableResult
    func startBlockingWithKey(keyId: UUID) -> Bool {
        startSession(source: .key(keyId))
    }
    
    /// Starts a session from a full hold on the key. Needs at least one
    /// registered key, because only a key (or an emergency unblock) ends it.
    @discardableResult
    func startBlockingWithHold() -> Bool {
        guard !keys.isEmpty else { return false }
        return startSession(source: .hold)
    }
    
    /// The one code path that starts every manual session.
    private func startSession(source: ActiveSession.Source) -> Bool {
        guard let mode = activeMode, !isBlocking else { return false }
        state.active = ActiveSession(modeID: mode.id, source: source, startedAt: Date())
        saveState()
        reconcile()
        return isBlocking
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
        // NFC and QR both unblock through this path; emergency does not.
        keyUnblockCount = ReviewPrompt.recordKeyUnblock()
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
        ScheduleMonitor.sync(config.schedules)
    }
    
    private func saveState() {
        PolicyStore.save(state)
        state = PolicyStore.loadState()
    }
}
