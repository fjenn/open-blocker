import Foundation
import DeviceActivity
import ManagedSettings

/// DeviceActivity callbacks. Apply/clear goes through Reconcile so the
/// extension and the app share one decision path.
@objc(MonitorExtension)
final class MonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        Reconcile.reconcile()
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        Reconcile.reconcile()
    }
}
