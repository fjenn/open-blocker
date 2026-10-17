import Foundation
import UserNotifications

/// Local notifications when a block or scheduled session ends.
enum SessionNotify {
    private static let enabledKey = "sessionNotifyEnabled"
    private static let scheduleEndID = "org.openblocker.notify.schedule-end"
    
    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey)
    }
    
    /// Saves the switch. Turning it on asks for permission first
    /// (Permissions.request), in NotificationsScreen.
    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: enabledKey)
        if !enabled { cancelScheduledEnd() }
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
}
