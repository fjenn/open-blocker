import Foundation

/// The two ways the app writes a length of time.
enum DurationText {
    /// "2h 5m". Used for totals (today, averages, day cards).
    static func hoursMinutes(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return "\(total / 3600)h \((total % 3600) / 60)m"
    }
    
    /// "2h 05m 09s", or "5m 09s" under an hour. Used for the live blocked timer.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%dh %02dm %02ds", h, m, s)
        }
        return String(format: "%dm %02ds", m, s)
    }
}
