// Adapted from Foqos (MIT, (c) 2024 Ali Waseem): Foqos/Models/Shared.swift
// App Group storage for shared state between app and extensions

import Foundation

enum PolicyStore {
    static let appGroupID = "group.org.openblocker.OpenBlocker"
    
    // MARK: - File URLs
    
    private static var containerURL: URL {
        // Try App Group container first, fall back to Application Support for unsigned builds
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            print("[PolicyStore] Using App Group: \(groupURL.path)")
            return groupURL
        } else {
            let fallbackURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("OpenBlocker")
            try? FileManager.default.createDirectory(at: fallbackURL, withIntermediateDirectories: true)
            print("[PolicyStore] ⚠️ App Group unavailable, using fallback: \(fallbackURL.path)")
            return fallbackURL
        }
    }
    
    private static var configURL: URL {
        containerURL.appendingPathComponent("config.json")
    }
    
    private static var stateURL: URL {
        containerURL.appendingPathComponent("state.json")
    }
    
    private static var historyURL: URL {
        containerURL.appendingPathComponent("history.json")
    }
    
    // MARK: - Config (modes, keys, schedules, rules, activeModeID)
    
    struct Config: Codable {
        var modes: [BlockMode]
        var keys: [BlockKey]
        var schedules: [BlockSchedule]
        var rules: Rules
        var activeModeID: UUID?
        
        init(
            modes: [BlockMode] = [],
            keys: [BlockKey] = [],
            schedules: [BlockSchedule] = [],
            rules: Rules = Rules(),
            activeModeID: UUID? = nil
        ) {
            self.modes = modes
            self.keys = keys
            self.schedules = schedules
            self.rules = rules
            self.activeModeID = activeModeID
        }
        
        func mode(_ id: UUID) -> BlockMode? {
            modes.first { $0.id == id }
        }
    }
    
    static func loadConfig() -> Config {
        let url = configURL
        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(Config.self, from: data)
            print("[PolicyStore] ✓ Loaded config: \(config.modes.count) modes, \(config.keys.count) keys, \(config.schedules.count) schedules")
            return config
        } catch {
            print("[PolicyStore] No config found or decode error: \(error.localizedDescription)")
            return Config()
        }
    }
    
    static func save(_ config: Config) {
        let url = configURL
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: url, options: .atomic)
            print("[PolicyStore] ✓ Saved config: \(config.modes.count) modes, \(config.keys.count) keys, \(config.schedules.count) schedules")
        } catch {
            print("[PolicyStore] ❌ Failed to save config: \(error.localizedDescription)")
        }
    }
    
    // MARK: - State (active session, schedule override)
    
    struct State: Codable {
        var active: ActiveSession?
        var override: ScheduleOverride?
        var lastEnd: Date?
        
        init(
            active: ActiveSession? = nil,
            override: ScheduleOverride? = nil,
            lastEnd: Date? = nil
        ) {
            self.active = active
            self.override = override
            self.lastEnd = lastEnd
        }
    }
    
    static func loadState() -> State {
        let url = stateURL
        do {
            let data = try Data(contentsOf: url)
            let state = try JSONDecoder().decode(State.self, from: data)
            return state
        } catch {
            return State()
        }
    }
    
    static func save(_ state: State) {
        let url = stateURL
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[PolicyStore] ❌ Failed to save state: \(error.localizedDescription)")
        }
    }
    
    // MARK: - History (session records)
    
    static func loadHistory() -> [SessionRecord] {
        let url = historyURL
        do {
            let data = try Data(contentsOf: url)
            let history = try JSONDecoder().decode([SessionRecord].self, from: data)
            print("[PolicyStore] ✓ Loaded \(history.count) session records")
            return history
        } catch {
            return []
        }
    }
    
    static func saveHistory(_ history: [SessionRecord]) {
        let url = historyURL
        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: url, options: .atomic)
            print("[PolicyStore] ✓ Saved \(history.count) session records")
        } catch {
            print("[PolicyStore] ❌ Failed to save history: \(error.localizedDescription)")
        }
    }
    
    static func appendToHistory(_ record: SessionRecord) {
        var history = loadHistory()
        history.append(record)
        saveHistory(history)
    }
}

// MARK: - Models

struct ActiveSession: Codable, Equatable {
    var id: UUID
    var modeID: UUID
    var source: Source
    var startedAt: Date
    var scheduleEnd: Date?
    
    enum Source: Codable, Equatable {
        case key(UUID)
        case hold
        case schedule(UUID)
    }
    
    init(
        id: UUID = UUID(),
        modeID: UUID,
        source: Source,
        startedAt: Date,
        scheduleEnd: Date? = nil
    ) {
        self.id = id
        self.modeID = modeID
        self.source = source
        self.startedAt = startedAt
        self.scheduleEnd = scheduleEnd
    }
}

struct SessionRecord: Codable, Identifiable {
    var id: UUID
    var modeID: UUID
    var source: ActiveSession.Source
    var start: Date
    var end: Date
    var endedBy: EndReason
    
    enum EndReason: String, Codable {
        case key
        case emergency
        case scheduleEnd
        case passage
        case accessRevoked
    }
    
    init(
        id: UUID = UUID(),
        modeID: UUID,
        source: ActiveSession.Source,
        start: Date,
        end: Date,
        endedBy: EndReason
    ) {
        self.id = id
        self.modeID = modeID
        self.source = source
        self.start = start
        self.end = end
        self.endedBy = endedBy
    }
}

struct ScheduleOverride: Codable {
    var scheduleID: UUID
    var until: Date
}

struct Rules: Codable {
    var preventDelete: Bool = true
    var blockInstalls: Bool = false
    var blockPurchases: Bool = false
    var blockAdultWeb: Bool = false
}
