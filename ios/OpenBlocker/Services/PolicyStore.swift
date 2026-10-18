// Adapted from Foqos (MIT, (c) 2024 Ali Waseem): Foqos/Models/Shared.swift
// App Group storage for shared state between app and extensions

import Foundation

enum PolicyStore {
    static let appGroupID = "group.org.openblocker.OpenBlocker"
    
    // MARK: - File URLs
    
    /// Resolved once per process: the lookup is an IPC call and used to run
    /// (and log) several times during launch.
    private static let containerURL: URL = {
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
    }()
    
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
    
    /// The last error from `loadConfig`, if the file existed but could not be decoded.
    static private(set) var lastConfigLoadError: Error?
    
    static func loadConfig() -> Config {
        loadConfig(from: configURL)
    }
    
    /// Loads a config. A missing file gives an empty Config. A file that exists
    /// but fails to decode is never thrown away silently: the raw bytes are
    /// copied to `config.corrupt-<timestamp>.json` next to it and the error is
    /// logged, before an empty Config is returned.
    static func loadConfig(from url: URL) -> Config {
        lastConfigLoadError = nil
        guard let data = try? Data(contentsOf: url) else {
            print("[PolicyStore] No config file yet at \(url.lastPathComponent)")
            return Config()
        }
        do {
            let config = try decodeConfig(data)
            print("[PolicyStore] ✓ Loaded config: \(config.modes.count) modes, \(config.keys.count) keys, \(config.schedules.count) schedules")
            return config
        } catch {
            lastConfigLoadError = error
            let stamp = Int(Date().timeIntervalSince1970)
            let backup = url.deletingLastPathComponent()
                .appendingPathComponent("config.corrupt-\(stamp).json")
            do {
                try data.write(to: backup, options: .atomic)
                print("[PolicyStore] ❌ Config decode failed: \(error). Raw file backed up to \(backup.path)")
            } catch let backupError {
                print("[PolicyStore] ❌ Config decode failed: \(error). Backup also failed: \(backupError)")
            }
            return Config()
        }
    }
    
    static func decodeConfig(_ data: Data) throws -> Config {
        try JSONDecoder().decode(Config.self, from: data)
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
    var blockAddingKeys: Bool = true
}

extension Rules {
    // Tolerant: configs from older builds lack newer keys.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        preventDelete = try c.decodeIfPresent(Bool.self, forKey: .preventDelete) ?? true
        blockInstalls = try c.decodeIfPresent(Bool.self, forKey: .blockInstalls) ?? false
        blockPurchases = try c.decodeIfPresent(Bool.self, forKey: .blockPurchases) ?? false
        blockAdultWeb = try c.decodeIfPresent(Bool.self, forKey: .blockAdultWeb) ?? false
        blockAddingKeys = try c.decodeIfPresent(Bool.self, forKey: .blockAddingKeys) ?? true
    }
}

extension PolicyStore.Config {
    // Tolerant: any missing top-level key falls back to its default.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            modes: try c.decodeIfPresent([BlockMode].self, forKey: .modes) ?? [],
            keys: try c.decodeIfPresent([BlockKey].self, forKey: .keys) ?? [],
            schedules: try c.decodeIfPresent([BlockSchedule].self, forKey: .schedules) ?? [],
            rules: try c.decodeIfPresent(Rules.self, forKey: .rules) ?? Rules(),
            activeModeID: try c.decodeIfPresent(UUID.self, forKey: .activeModeID)
        )
    }
}
