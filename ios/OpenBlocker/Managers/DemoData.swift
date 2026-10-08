// Realistic demo data following the research brief

import Foundation
import FamilyControls

#if DEBUG
struct DemoData {
    static func setupDemo() {
        var config = PolicyStore.loadConfig()
        
        // Create demo modes with demo counts
        var almostNone = BlockMode(
            name: "Almost None",
            kind: .allowOnly,
            isDefault: true
        )
        almostNone.demoAppCount = 8
        almostNone.demoWebsiteCount = 1
        
        var workFocus = BlockMode(
            name: "Work Focus",
            kind: .block,
            isDefault: true
        )
        workFocus.demoAppCount = 12
        workFocus.demoWebsiteCount = 2
        
        var deepFocus = BlockMode(
            name: "Deep Focus",
            kind: .block,
            isDefault: true
        )
        deepFocus.demoAppCount = 20
        
        config.modes = [almostNone, workFocus, deepFocus]
        config.activeModeID = almostNone.id
        
        EmergencyUnblockManager.resetToFull()
        
        // Desk Key secret is the mock NFC UID so a simulator tap matches.
        config.keys = [
            BlockKey(
                name: "Desk Key",
                kind: .openBlockerTag,
                secret: MockNFCScanner.defaultUID.hexString,
                addedAt: Date().addingTimeInterval(-86400 * 7)
            ),
            BlockKey(
                name: "Keychain Card",
                kind: .card,
                secret: "demo-card-456",
                addedAt: Date().addingTimeInterval(-86400 * 3)
            ),
            BlockKey(
                name: "Gym QR",
                kind: .qr,
                secret: "demo-qr-789",
                addedAt: Date().addingTimeInterval(-86400 * 14)
            )
        ]
        
        // Create demo schedules
        config.schedules = [
            BlockSchedule(
                name: "Work Hours",
                weekdays: [2, 3, 4, 5, 6],
                startMinute: 9 * 60,
                endMinute: 17 * 60,
                modeID: workFocus.id,
                isOn: true
            ),
            BlockSchedule(
                name: "Evening Focus",
                weekdays: [1, 2, 3, 4, 5, 6, 7],
                startMinute: 21 * 60,
                endMinute: 23 * 60,
                modeID: deepFocus.id,
                isOn: false
            )
        ]
        
        // Set default rules
        config.rules = Rules(
            preventDelete: true,
            blockInstalls: false,
            blockPurchases: false,
            blockAdultWeb: false
        )
        
        PolicyStore.save(config)
        
        PolicyStore.saveHistory(Self.history(
            modes: [almostNone, workFocus, deepFocus],
            keyID: config.keys[0].id,
            now: Date(),
            calendar: Calendar.current
        ))
        
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        
        // DEBUG: Verify data was seeded
        let verifyConfig = PolicyStore.loadConfig()
        let verifyHistory = PolicyStore.loadHistory()
        print("✅ [DemoData] Seeded: \(verifyConfig.modes.count) modes, \(verifyConfig.keys.count) keys, \(verifyConfig.schedules.count) schedules, \(verifyHistory.count) sessions")
        
        assert(verifyConfig.modes.count == 3, "Expected 3 modes, got \(verifyConfig.modes.count)")
        assert(verifyConfig.keys.count == 3, "Expected 3 keys, got \(verifyConfig.keys.count)")
        assert(verifyConfig.schedules.count == 2, "Expected 2 schedules, got \(verifyConfig.schedules.count)")
        assert(verifyHistory.count > 0, "Expected session history, got \(verifyHistory.count)")
    }
    
    /// Fixed weekday sessions. Wednesday is always 2h 43m (100 + 63).
    /// Today gets a finished morning session so Activity is not empty.
    static let sessionsByWeekday: [Int: [(hour: Int, minute: Int, durationMinutes: Int)]] = [
        1: [(10, 0, 28)],
        2: [(9, 0, 50), (14, 0, 25)],
        3: [(9, 0, 70), (15, 0, 40)],
        4: [(9, 0, 100), (14, 0, 63)],
        5: [(10, 0, 45)],
        6: [(9, 0, 80), (16, 0, 20)],
        7: [(11, 0, 35)]
    ]
    
    static func history(
        modes: [BlockMode],
        keyID: UUID,
        now: Date,
        calendar: Calendar
    ) -> [SessionRecord] {
        var history: [SessionRecord] = []
        let modeIDs = modes.map(\.id)
        
        appendTodaySession(to: &history, modes: modes, keyID: keyID, now: now, calendar: calendar)
        
        for dayOffset in 1...14 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            if calendar.isDate(day, inSameDayAs: now) { continue }
            
            let weekday = calendar.component(.weekday, from: day)
            let sessions = sessionsByWeekday[weekday] ?? [(12, 0, 30)]
            let modeID = modeIDs[(dayOffset - 1) % max(modeIDs.count, 1)]
            
            for session in sessions {
                guard let startDate = calendar.date(
                    bySettingHour: session.hour,
                    minute: session.minute,
                    second: 0,
                    of: day
                ),
                let endDate = calendar.date(
                    byAdding: .minute,
                    value: session.durationMinutes,
                    to: startDate
                ) else {
                    continue
                }
                
                history.append(SessionRecord(
                    modeID: modeID,
                    source: .key(keyID),
                    start: startDate,
                    end: endDate,
                    endedBy: .key
                ))
            }
        }
        
        return history
    }
    
    /// A completed session that ended 20 minutes before `now`, 32 minutes long.
    private static func appendTodaySession(
        to history: inout [SessionRecord],
        modes: [BlockMode],
        keyID: UUID,
        now: Date,
        calendar: Calendar
    ) {
        let end = now.addingTimeInterval(-20 * 60)
        let start = end.addingTimeInterval(-32 * 60)
        guard calendar.isDate(start, inSameDayAs: now), start < end, end <= now else { return }
        history.append(SessionRecord(
            modeID: modes.first?.id ?? UUID(),
            source: .key(keyID),
            start: start,
            end: end,
            endedBy: .key
        ))
    }
}
#endif
