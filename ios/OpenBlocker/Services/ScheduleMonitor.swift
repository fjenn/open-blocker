import Foundation
#if !EXTENSION
import DeviceActivity

/// Registers one repeating DeviceActivity interval per enabled schedule so
/// the Monitor extension can reconcile at start and end. Overnight schedules
/// use hour/minute components that wrap midnight; we never pin both ends to
/// the same calendar Date.
enum ScheduleMonitor {
    static func sync(_ schedules: [BlockSchedule]) {
        #if targetEnvironment(simulator)
        return
        #else
        let center = DeviceActivityCenter()
        center.stopMonitoring()
        
        for schedule in schedules where schedule.isOn {
            let bounds = ScheduleInterval.deviceActivityBounds(
                startMinute: schedule.startMinute,
                endMinute: schedule.endMinute
            )
            let activity = DeviceActivitySchedule(
                intervalStart: bounds.start,
                intervalEnd: bounds.end,
                repeats: true
            )
            do {
                try center.startMonitoring(
                    DeviceActivityName(schedule.id.uuidString),
                    during: activity
                )
            } catch {
                print("[ScheduleMonitor] startMonitoring failed: \(error)")
            }
        }
        #endif
    }
}
#endif
