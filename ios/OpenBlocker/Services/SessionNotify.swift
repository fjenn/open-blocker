import Foundation
import UserNotifications
import UIKit

/// Local notifications when a block or scheduled session ends.
enum SessionNotify {
    private static let enabledKey = "sessionNotifyEnabled"
    private static let scheduleEndID = "org.openblocker.notify.schedule-end"
    
    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey)
    }
    
    static func setEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            let granted = await requestPermission()
            UserDefaults.standard.set(granted, forKey: enabledKey)
            if !granted {
                await openSystemSettings()
            }
            return granted
        } else {
            UserDefaults.standard.set(false, forKey: enabledKey)
            cancelScheduledEnd()
            return false
        }
    }
    
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }
    
    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
    
    static func notifyEnded() {
        guard isEnabled else { return }
        cancelScheduledEnd()
        let content = UNMutableNotificationContent()
        content.title = "Block ended"
        content.body = "Your Open Blocker session is over."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    static func scheduleEnd(at date: Date) {
        guard isEnabled, date > Date() else { return }
        cancelScheduledEnd()
        let content = UNMutableNotificationContent()
        content.title = "Block ended"
        content.body = "Your scheduled Open Blocker session is over."
        content.sound = .default
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: scheduleEndID,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    static func cancelScheduledEnd() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [scheduleEndID])
    }
    
    @MainActor
    static func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
