// Every iOS permission Open Blocker asks for, in one place.
// Each one is asked for at the moment it's needed. iOS only shows its prompt
// once; when a permission was turned off earlier, the app explains why it
// needs it and offers a button to its page in Settings (PermissionSheet).
// NFC needs no permission: its system sheet appears with each scan.

import AVFoundation
import FamilyControls
import SwiftUI
import UserNotifications

enum Permission: String, Identifiable, CaseIterable {
    case camera
    case notifications
    case screenTime
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .camera: return "camera"
        case .notifications: return "bell"
        case .screenTime: return "hourglass"
        }
    }
    
    /// Shown when the permission was turned off and iOS won't ask again.
    var deniedTitle: String {
        switch self {
        case .camera: return "Camera is off"
        case .notifications: return "Notifications are off"
        case .screenTime: return "Screen Time is off"
        }
    }
    
    var deniedMessage: String {
        switch self {
        case .camera:
            return "Open Blocker uses the camera only to scan your QR key. Turn on Camera in Settings."
        case .notifications:
            return "Open Blocker can let you know when a block ends. Turn on Notifications in Settings."
        case .screenTime:
            return "Apple requires it for any app to block apps. We don't read your usage. Turn it on in Settings, under Screen Time."
        }
    }
}

enum PermissionStatus: Equatable {
    case granted
    /// iOS will still show its prompt.
    case notDetermined
    /// Turned off earlier. Only Settings can turn it back on.
    case denied
    
    init(_ status: AVAuthorizationStatus) {
        switch status {
        case .authorized: self = .granted
        case .notDetermined: self = .notDetermined
        default: self = .denied
        }
    }
    
    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .authorized, .provisional, .ephemeral: self = .granted
        case .notDetermined: self = .notDetermined
        default: self = .denied
        }
    }
    
    init(_ status: AuthorizationStatus) {
        switch status {
        case .approved: self = .granted
        case .notDetermined: self = .notDetermined
        default: self = .denied
        }
    }
}

@MainActor
enum Permissions {
    /// What happened when the app asked.
    enum Outcome: Equatable {
        case granted
        /// The person said no to the prompt just now.
        case declined
        /// Turned off earlier, so iOS showed nothing.
        case blocked
    }
    
    /// Builds without the Family Controls entitlement (the simulator, and
    /// free personal-team builds that set NO_FAMILY_CONTROLS) can't get
    /// Screen Time, so it never gates anything there.
    static var screenTimeUnavailable: Bool {
        #if targetEnvironment(simulator) || NO_FAMILY_CONTROLS
        return true
        #else
        return false
        #endif
    }
    
    static func status(_ permission: Permission) async -> PermissionStatus {
        switch permission {
        case .camera:
            return PermissionStatus(AVCaptureDevice.authorizationStatus(for: .video))
        case .notifications:
            return PermissionStatus(await UNUserNotificationCenter.current().notificationSettings().authorizationStatus)
        case .screenTime:
            return screenTimeStatus
        }
    }
    
    /// Screen Time can be read right away, so the home screen never flickers.
    static var screenTimeStatus: PermissionStatus {
        screenTimeUnavailable ? .granted : PermissionStatus(AuthorizationCenter.shared.authorizationStatus)
    }
    
    /// Shows the iOS prompt when it still can.
    static func request(_ permission: Permission) async -> Outcome {
        let before = await status(permission)
        if before == .granted { return .granted }
        let granted: Bool
        switch permission {
        case .camera:
            guard before == .notDetermined else { return .blocked }
            granted = await AVCaptureDevice.requestAccess(for: .video)
        case .notifications:
            guard before == .notDetermined else { return .blocked }
            granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
        case .screenTime:
            // Screen Time shows its sheet again after a no, so always ask.
            granted = (try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)) != nil
        }
        let outcome: Outcome = granted ? .granted : (before == .denied ? .blocked : .declined)
        #if DEBUG
        print("[Permissions] \(permission.rawValue): \(before) -> \(outcome)")
        #endif
        return outcome
    }
    
    #if DEBUG
    /// One line per permission in the console, for checking a device.
    static func logStatuses() async {
        for permission in Permission.allCases {
            print("[Permissions] \(permission.rawValue) is \(await status(permission))")
        }
    }
    #endif
    
    /// Runs `action` once the permission is granted. When iOS won't ask,
    /// sets `denied` so the view can show PermissionSheet.
    static func whenGranted(
        _ permission: Permission,
        denied: Binding<Permission?>,
        perform action: @escaping @MainActor () -> Void
    ) {
        Task { @MainActor in
            switch await request(permission) {
            case .granted: action()
            case .blocked: denied.wrappedValue = permission
            case .declined: break
            }
        }
    }
    
    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
