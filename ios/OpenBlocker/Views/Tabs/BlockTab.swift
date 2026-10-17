// Home: today pill, the key, the active mode, one capsule.
// Tap the key (or capsule) to scan a key. Hold either to fill and block.
// Unblocking always needs a registered key or an emergency unblock.

import SwiftUI

struct BlockTab: View {
    @ObservedObject var appState = AppState.shared
    @StateObject private var hold = HoldToLockController()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var showingModes = false
    @State private var showingKeySetup = false
    @State private var showingKeyChooser = false
    @State private var showingQRScanner = false
    @State private var deniedPermission: Permission?
    @State private var toast: String?
    
    private enum Readiness {
        case needsScreenTime
        case needsKey
        case needsApps
        case ready
    }
    
    private var readiness: Readiness {
        if !appState.isAuthorized { return .needsScreenTime }
        if appState.keys.isEmpty { return .needsKey }
        guard let mode = appState.activeMode else { return .needsApps }
        if mode.kind == .block && mode.blockedAppCount == 0 && mode.websiteCount == 0 {
            return .needsApps
        }
        return .ready
    }
    
    var body: some View {
        ZStack {
            ScreenCanvas()
            
            VStack(spacing: 0) {
                header
                    .frame(height: 96, alignment: .top)
                    .padding(.top, Space.xs)
                
                Spacer(minLength: 0)
                
                KeyStage(
                    hold: hold,
                    isLocked: appState.isBlocking,
                    isEnabled: readiness == .ready || appState.isBlocking,
                    onTap: handleTap,
                    onHoldWhileLocked: { toast = "Unblocking needs your key." }
                )
                .frame(maxWidth: 300, maxHeight: 300)
                .padding(.horizontal, Space.margin)
                .layoutPriority(1)
                
                modeInfo
                
                Spacer(minLength: Space.l)
                
                primaryAction
                    .padding(.horizontal, Space.xl)
                
                Text(hint)
                    .textStyle(.footnote, weight: .regular)
                    .foregroundColor(Color.inkTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Space.xxxl)
                    .padding(.top, Space.s)
                    .frame(minHeight: 36, alignment: .top)
                    .animation(nil, value: hint)
                    .accessibilityIdentifier("home-hint")
                
                Spacer().frame(height: Space.s)
            }
        }
        .toast($toast)
        .onAppear {
            hold.reduceMotion = reduceMotion
            hold.onComplete = { appState.startBlockingWithHold() }
            hold.setLocked(appState.isBlocking, animated: false)
        }
        .onChange(of: appState.isBlocking) { blocking in
            hold.setLocked(blocking)
        }
        .onChange(of: reduceMotion) { hold.reduceMotion = $0 }
        .sheet(isPresented: $showingModes) { ModesScreen() }
        .sheet(isPresented: $showingKeySetup) { KeySetupScreen() }
        .sheet(isPresented: $showingKeyChooser) {
            KeyScanChooserSheet(
                onNFC: {
                    showingKeyChooser = false
                    Task { await scanNFC() }
                },
                onQR: {
                    showingKeyChooser = false
                    openQRScanner()
                },
                onCancel: { showingKeyChooser = false }
            )
            .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showingQRScanner) {
            QRScannerView(
                onCode: { payload in
                    showingQRScanner = false
                    applyScannedKey(KeyScanner.scannedKey(fromCode: payload))
                },
                onCancel: { showingQRScanner = false }
            )
        }
        .permissionSheet($deniedPermission)
    }
    
    // MARK: Sections
    
    /// Idle: today's total. Blocked: a live "Blocked for" counter.
    @ViewBuilder
    private var header: some View {
        if let session = appState.currentSession {
            VStack(spacing: Space.xxs) {
                Text("Blocked for")
                    .textStyle(.footnote)
                    .foregroundColor(Color.inkSecondary)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(DurationText.clock(context.date.timeIntervalSince(session.startedAt)))
                        .textStyle(.timer)
                        .foregroundColor(Color.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .padding(.top, Space.s)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(AccessibilityID.blockedTimer)
        } else {
            TimelineView(.periodic(from: .now, by: 30)) { _ in
                TodayPill(seconds: appState.todayBlockedTime())
            }
            .padding(.top, Space.s)
        }
    }
    
    private var modeInfo: some View {
        VStack(spacing: Space.xxs) {
            Text(appState.activeMode?.name ?? "No mode")
                .textStyle(.title, weight: .medium)
                .foregroundColor(Color.ink)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(appState.activeMode?.subtitle ?? "Pick a mode to choose what gets blocked.")
                .textStyle(.subhead)
                .foregroundColor(Color.inkSecondary)
                .multilineTextAlignment(.center)
            Button(action: { showingModes = true }) {
                HStack(spacing: 4) {
                    Text(appState.isBlocking ? "View modes" : "Manage modes")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .textStyle(.footnote, weight: .semibold)
                .foregroundColor(Color.ink)
                .frame(minHeight: 40)
                .padding(.horizontal, Space.m)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressScaleStyle())
            .padding(.top, Space.xxs)
            .accessibilityIdentifier(AccessibilityID.manageModes)
        }
        .padding(.horizontal, Space.margin)
        .padding(.top, Space.xs)
    }
    
    @ViewBuilder
    private var primaryAction: some View {
        switch readiness {
        case .needsScreenTime where !appState.isBlocking:
            PrimaryButton(title: "Allow Screen Time", accessibilityID: AccessibilityID.homeAllowScreenTime) {
                allowScreenTime()
            }
        case .needsKey where !appState.isBlocking:
            PrimaryButton(title: "Add a key", accessibilityID: AccessibilityID.homeAddKey) {
                showingKeySetup = true
            }
        case .needsApps where !appState.isBlocking:
            PrimaryButton(title: "Choose apps to block") { showingModes = true }
        default:
            let title = buttonTitle
            CapsuleFace(
                title: title,
                progress: appState.isBlocking ? 0 : hold.progress
            )
            .scaleEffect(hold.isHolding && !reduceMotion ? 0.97 : 1)
            .animation(Motion.standard, value: hold.isHolding)
            .holdToBlock(
                hold,
                isLocked: appState.isBlocking,
                onTap: handleTap,
                onHoldWhileLocked: { toast = "Unblocking needs your key." }
            )
            .accessibilityElement()
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(AccessibilityID.blockButton)
            .accessibilityAction { handleTap() }
            .accessibilityAction(named: "Block now") {
                if !appState.isBlocking { hold.completeNow() }
            }
        }
    }
    
    private var buttonTitle: String {
        if appState.isBlocking { return "Scan your key to unblock" }
        if hold.isHolding { return "Keep holding" }
        return "Tap your key or hold to block"
    }
    
    private var hint: String {
        if appState.isBlocking {
            return "Lost your key? Settings has emergency unblocks."
        }
        switch readiness {
        case .needsScreenTime: return "Apple requires this to block apps. We don't read your usage."
        case .needsKey: return "Add a key to start. It is what unblocks you."
        case .needsApps: return "This mode has nothing to block yet."
        case .ready: return hold.isHolding ? "Let go to cancel." : "Unblocking needs your key."
        }
    }
    
    // MARK: Actions
    
    private func handleTap() {
        switch readiness {
        case .needsScreenTime where !appState.isBlocking:
            allowScreenTime()
            return
        case .needsKey where !appState.isBlocking:
            showingKeySetup = true
            return
        case .needsApps where !appState.isBlocking:
            showingModes = true
            return
        default:
            break
        }
        switch KeyScanner.route(for: appState.keys) {
        case .none:
            showingKeySetup = true
        case .nfc:
            Task { await scanNFC() }
        case .qr:
            openQRScanner()
        case .choose:
            showingKeyChooser = true
        }
    }
    
    private func allowScreenTime() {
        Permissions.whenGranted(.screenTime, denied: $deniedPermission) {
            appState.isAuthorized = true
        }
    }
    
    private func openQRScanner() {
        Permissions.whenGranted(.camera, denied: $deniedPermission) {
            showingQRScanner = true
        }
    }
    
    private func scanNFC() async {
        do {
            // Only a registered key ends the NFC session; any other tag keeps
            // the system sheet on "Ready to scan" (no checkmark).
            let scannedKey = try await appState.nfcScanner.scan(keyMatcher: { scanned in
                appState.matchKey(scanned) != nil
            })
            applyScannedKey(scannedKey)
        } catch NFCScanError.userCancelled {
            return
        } catch {
            toast = error.localizedDescription
        }
    }
    
    private func applyScannedKey(_ scannedKey: ScannedKey) {
        guard let matchedKey = appState.matchKey(scannedKey) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            toast = appState.isBlocking
                ? "That's not one of your keys."
                : "This key isn't set up yet. Add it in Settings."
            return
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if appState.isBlocking {
            _ = appState.stopBlockingWithKey(keyId: matchedKey.id)
        } else {
            appState.startBlockingWithKey(keyId: matchedKey.id)
        }
    }
}

private struct KeyScanChooserSheet: View {
    var onNFC: () -> Void
    var onQR: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        SheetScaffold(
            title: "Scan your key",
            trailing: SheetAction(systemImage: "xmark", accessibilityLabel: "Cancel", action: onCancel)
        ) {
            VStack(spacing: Space.s) {
                Button(action: onNFC) {
                    OptionRow(icon: "wave.3.right", title: "Tap NFC key", subtitle: "Tag or card at the top of your iPhone")
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityIdentifier(AccessibilityID.tapNFC)
                
                Button(action: onQR) {
                    OptionRow(icon: "qrcode.viewfinder", title: "Scan QR or barcode", subtitle: "Point the camera at your printed key or barcode")
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityIdentifier(AccessibilityID.scanQR)
            }
            .padding(.horizontal, Space.margin)
            .padding(.top, Space.xs)
            Spacer(minLength: 0)
        }
    }
}
