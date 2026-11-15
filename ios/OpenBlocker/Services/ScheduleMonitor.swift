import Foundation
#if !EXTENSION
import DeviceActivity
import FamilyControls

/// Registers one repeating DeviceActivity interval per enabled schedule so
/// the Monitor extension can reconcile at start and end. Overnight schedules
/// use hour/minute components that wrap midnight; we never pin both ends to
/// the same calendar Date.
enum ScheduleMonitor {
    static func sync(_ config: PolicyStore.Config) {
        #if targetEnvironment(simulator)
        return
        #else
        let center = DeviceActivityCenter()
        center.stopMonitoring()
        
        for schedule in config.schedules where schedule.isOn {
            let bounds = ScheduleInterval.deviceActivityBounds(
                startMinute: schedule.startMinute,
                endMinute: schedule.effectiveEndMinute
            )
            let activity = DeviceActivitySchedule(
                intervalStart: bounds.start,
                intervalEnd: bounds.end,
                repeats: true
            )
            do {
                try center.startMonitoring(
                    DeviceActivityName(schedule.id.uuidString),
                    during: activity,
                    events: limitEvents(for: schedule, config: config)
                )
            } catch {
                print("[ScheduleMonitor] startMonitoring failed: \(error)")
            }
        }
        #endif
    }
    
    /// One usage event for a daily-limit schedule. Block modes count the
    /// chosen apps and sites; allow-only modes count all use (empty sets).
    private static func limitEvents(
        for schedule: BlockSchedule,
        config: PolicyStore.Config
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        guard let limit = schedule.dailyLimitMinutes,
              let mode = schedule.modeID.flatMap({ config.mode($0) }) else { return [:] }
        let sel = mode.selection
        let counted = mode.kind == .block
        let apps = counted ? sel.applicationTokens : []
        let categories = counted ? sel.categoryTokens : []
        let sites = counted ? sel.webDomainTokens : []
        let threshold = DateComponents(hour: limit / 60, minute: limit % 60)
        let event: DeviceActivityEvent
        if #available(iOS 17.4, *) {
            event = DeviceActivityEvent(
                applications: apps, categories: categories, webDomains: sites,
                threshold: threshold, includesPastActivity: true
            )
        } else {
            // shortcut: before iOS 17.4 the count restarts whenever schedules re-sync; raise the minimum iOS to fix.
            event = DeviceActivityEvent(
                applications: apps, categories: categories, webDomains: sites, threshold: threshold
            )
        }
        return [DeviceActivityEvent.Name("limit"): event]
    }
}
#endif
