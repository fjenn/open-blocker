// Emergency unblock allowance stored in Keychain (survives reinstalls)
// Adapted from Foqos (MIT, (c) 2024 Ali Waseem): Foqos/Utils/StrategyManager.swift emergency unblock concept

import Foundation
import Security

/// Five emergency unblocks per six-month period. When the period runs out
/// the allowance goes back to five and a new period starts.
struct EmergencyAllowance: Equatable {
    static let maxCount = 5
    static let periodMonths = 6
    
    var remaining: Int
    var periodStart: Date
    
    static func full(startingAt start: Date) -> EmergencyAllowance {
        EmergencyAllowance(remaining: maxCount, periodStart: start)
    }
    
    /// When the allowance goes back to five.
    func resetDate(calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: Self.periodMonths, to: periodStart)
            ?? periodStart.addingTimeInterval(TimeInterval(Self.periodMonths) * 30.5 * 86_400)
    }
    
    /// Full again, with a new period from `now`, once the reset date has passed.
    func renewed(at now: Date, calendar: Calendar = .current) -> EmergencyAllowance {
        now >= resetDate(calendar: calendar) ? .full(startingAt: now) : self
    }
    
    /// One fewer, or nil when none are left.
    func usingOne() -> EmergencyAllowance? {
        remaining > 0 ? EmergencyAllowance(remaining: remaining - 1, periodStart: periodStart) : nil
    }
}

enum EmergencyUnblockManager {
    private static let service = "org.openblocker.emergency"
    private static let countKey = "count"
    private static let periodStartKey = "periodStart"
    
    struct Status: Equatable {
        let remaining: Int
        let resetDate: Date
    }
    
    /// The current allowance and when it resets.
    static func status() -> Status {
        let allowance = load()
        return Status(remaining: allowance.remaining, resetDate: allowance.resetDate())
    }
    
    #if DEBUG
    /// Demo and UI tests start from a full set of 5.
    static func resetToFull() {
        save(.full(startingAt: Date()))
    }
    #endif
    
    /// Use one emergency unblock. Returns true if there was one to use.
    static func useOne(now: Date = Date()) -> Bool {
        guard let next = load(now: now).renewed(at: now).usingOne() else { return false }
        save(next)
        return load(now: now) == next
    }
    
    /// Call on launch and when the app comes back: starts the first period,
    /// and resets to five once six months have passed.
    static func renewIfDue(now: Date = Date()) {
        let stored = load(now: now)
        let renewed = stored.renewed(at: now)
        if renewed != stored || readPeriodStart() == nil {
            save(renewed)
        }
    }
    
    // MARK: - Storage
    
    /// The stored allowance. Without a stored period (first launch, or an
    /// install from before periods), the period starts `now` and the count is kept.
    private static func load(now: Date = Date()) -> EmergencyAllowance {
        let count = readInt(countKey) ?? EmergencyAllowance.maxCount
        return EmergencyAllowance(
            remaining: min(max(count, 0), EmergencyAllowance.maxCount),
            periodStart: readPeriodStart() ?? now
        )
    }
    
    private static func save(_ allowance: EmergencyAllowance) {
        write(key: countKey, data: Data(String(allowance.remaining).utf8))
        write(key: periodStartKey, data: Data(String(allowance.periodStart.timeIntervalSince1970).utf8))
    }
    
    private static func readInt(_ key: String) -> Int? {
        read(key: key).flatMap { String(data: $0, encoding: .utf8) }.flatMap { Int($0) }
    }
    
    private static func readPeriodStart() -> Date? {
        read(key: periodStartKey)
            .flatMap { String(data: $0, encoding: .utf8) }
            .flatMap { TimeInterval($0) }
            .map { Date(timeIntervalSince1970: $0) }
    }
    
    private static let defaultsPrefix = "org.openblocker.emergency."
    
    private static func read(key: String) -> Data? {
        if let data = keychainRead(key: key) {
            return data
        }
        return UserDefaults.standard.data(forKey: defaultsPrefix + key)
    }
    
    @discardableResult
    private static func write(key: String, data: Data) -> Bool {
        if keychainWrite(key: key, data: data) {
            UserDefaults.standard.removeObject(forKey: defaultsPrefix + key)
            return true
        }
        UserDefaults.standard.set(data, forKey: defaultsPrefix + key)
        return true
    }
    
    private static func keychainRead(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    @discardableResult
    private static func keychainWrite(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let update: [String: Any] = [kSecValueData as String: data]
        if SecItemUpdate(query as CFDictionary, update as CFDictionary) == errSecSuccess {
            return true
        }
        
        SecItemDelete(query as CFDictionary)
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }
}
