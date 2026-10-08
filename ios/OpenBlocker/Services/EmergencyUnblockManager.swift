// Emergency unblock counter stored in Keychain (survives reinstalls)
// Adapted from Foqos (MIT, (c) 2024 Ali Waseem): Foqos/Utils/StrategyManager.swift emergency unblock concept

import Foundation
import Security

enum EmergencyUnblockManager {
    private static let service = "org.openblocker.emergency"
    private static let countKey = "count"
    private static let lastRefillKey = "lastRefill"
    
    private static let maxCount = 5
    private static let refillDays = 30
    
    struct Status {
        let remaining: Int
        let nextRefillDate: Date?
    }
    
    /// Get the current emergency unblock status.
    static func status() -> Status {
        let count = getCount()
        let lastRefill = getLastRefillDate()
        
        let nextRefill: Date? = lastRefill.flatMap { Calendar.current.date(byAdding: .day, value: refillDays, to: $0) }
        
        return Status(remaining: count, nextRefillDate: nextRefill)
    }
    
    #if DEBUG
    /// Demo and UI tests start from a full set of 5.
    static func resetToFull() {
        _ = setCount(maxCount)
        setLastRefillDate(Date())
    }
    #endif
    
    /// Use one emergency unblock. Returns true if successful (had one to use).
    static func useOne() -> Bool {
        let count = getCount()
        guard count > 0 else { return false }
        guard setCount(count - 1) else { return false }
        return getCount() == count - 1
    }
    
    /// Check if a refill is due and apply it.
    static func refillIfNeeded() {
        let count = getCount()
        guard count < maxCount else { return }
        
        guard let lastRefill = getLastRefillDate() else {
            setCount(maxCount)
            setLastRefillDate(Date())
            return
        }
        
        let daysSince = Calendar.current.dateComponents([.day], from: lastRefill, to: Date()).day ?? 0
        if daysSince >= refillDays {
            setCount(min(count + 1, maxCount))
            setLastRefillDate(Date())
        }
    }
    
    // MARK: - Keychain Access
    
    private static func getCount() -> Int {
        guard let data = read(key: countKey),
              let string = String(data: data, encoding: .utf8),
              let count = Int(string) else {
            return maxCount
        }
        return count
    }
    
    @discardableResult
    private static func setCount(_ count: Int) -> Bool {
        let data = String(count).data(using: .utf8)!
        return write(key: countKey, data: data)
    }
    
    private static func getLastRefillDate() -> Date? {
        guard let data = read(key: lastRefillKey),
              let timestamp = String(data: data, encoding: .utf8),
              let interval = TimeInterval(timestamp) else {
            return nil
        }
        return Date(timeIntervalSince1970: interval)
    }
    
    private static func setLastRefillDate(_ date: Date) {
        let data = String(date.timeIntervalSince1970).data(using: .utf8)!
        write(key: lastRefillKey, data: data)
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
