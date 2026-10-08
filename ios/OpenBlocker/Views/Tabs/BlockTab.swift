// Home / Block tab - updated for new AppState architecture

import SwiftUI

struct BlockTab: View {
    @ObservedObject var appState = AppState.shared
    @State private var showingModesSheet = false
    @State private var showingKeySetup = false
    @State private var showingKeyChooser = false
    @State private var showingQRScanner = false
    @State private var holdProgress: CGFloat = 0
    @State private var isScanning = false
    @State private var scanMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            panelContent
                .frame(maxHeight: .infinity)
        }
        .background(Color.brickCanvas)
        .clipped()
        .sheet(isPresented: $showingModesSheet) {
            ModesScreen()
        }
        .sheet(isPresented: $showingKeySetup) {
            KeySetupScreen()
        }
        .sheet(isPresented: $showingKeyChooser) {
            KeyScanChooserSheet(
                onNFC: {
                    showingKeyChooser = false
                    Task { await scanNFC() }
                },
                onQR: {
                    showingKeyChooser = false
                    showingQRScanner = true
                },
                onCancel: { showingKeyChooser = false }
            )
            .presentationDetents([.height(260)])
        }
        .sheet(isPresented: $showingQRScanner) {
            QRScannerView(
                onCode: { payload in
                    showingQRScanner = false
                    applyScannedKey(KeyScanner.scannedKey(fromQR: payload))
                },
                onCancel: { showingQRScanner = false }
            )
        }
        .alert("Key", isPresented: Binding(
            get: { scanMessage != nil },
            set: { if !$0 { scanMessage = nil } }
        )) {
            Button("OK", role: .cancel) { scanMessage = nil }
        } message: {
            Text(scanMessage ?? "")
        }
    }
    
    private var panelContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 56, style: .continuous)
                .fill(Color.brickPanel)
                .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
                .offset(y: -56)
            
            VStack(spacing: 0) {
                TodayTimePill()
                    .padding(.top, 72)
                
                GeometryReader { geo in
                    let side = min(geo.size.width * 0.70, geo.size.height * 0.95)
                    KeyArt(progress: appState.isBlocking ? 0.5 : holdProgress)
                        .animation(.easeInOut(duration: 0.75), value: appState.isBlocking)
                        .frame(width: side, height: side)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                
                VStack(spacing: 4) {
                    if let mode = appState.activeMode {
                        Text(mode.name)
                            .brickText(size: 24, relativeTo: .title2)
                            .foregroundColor(Color.brickInk)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        Text(mode.subtitle)
                            .brickText(size: 14, relativeTo: .subheadline)
                            .foregroundColor(Color.brickMuted)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Button(action: { showingModesSheet = true }) {
                            HStack(spacing: 4) {
                                Text("Manage modes")
                                Image(systemName: "chevron.right")
                                    .brickText(size: 11, weight: .medium, relativeTo: .caption)
                            }
                            .brickText(size: 15, weight: .medium, relativeTo: .callout)
                            .foregroundColor(Color.brickInk)
                        }
                        .accessibilityIdentifier(AccessibilityID.manageModes)
                        .padding(.top, 8)
                    } else {
                        Text("Open Blocker")
                            .brickText(size: 24, relativeTo: .title2)
                            .foregroundColor(Color.brickInk)
                        Text("Add a key, then pick a mode.")
                            .brickText(size: 14, relativeTo: .subheadline)
                            .foregroundColor(Color.brickMuted)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 24)
                
                if appState.keys.isEmpty {
                    noKeyPrompt
                } else if appState.activeMode == nil || (appState.activeMode?.selection.applicationTokens.isEmpty ?? true && appState.activeMode?.kind == .block) {
                    emptyModePrompt
                } else {
                    BlockButton(
                        progress: $holdProgress,
                        isBlocking: appState.isBlocking,
                        onTap: handleTap,
                        onHoldComplete: handleHoldComplete
                    )
                }
                
                Spacer()
                    .frame(height: 28)
            }
        }
    }
    
    private var noKeyPrompt: some View {
        Button(action: { showingKeySetup = true }) {
            Text("Add a key")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.brickInk)
                .frame(maxWidth: .infinity, minHeight: 51)
                .background(
                    Capsule()
                        .fill(Color.brickButton)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.horizontal, 40)
        }
        .accessibilityIdentifier(AccessibilityID.homeAddKey)
    }
    
    private var emptyModePrompt: some View {
        Button(action: { showingModesSheet = true }) {
            Text("Choose apps to block")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.brickInk)
                .frame(maxWidth: .infinity, minHeight: 51)
                .background(
                    Capsule()
                        .fill(Color.brickButton)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.horizontal, 40)
        }
    }
    
    private func handleTap() {
        switch KeyScanner.route(for: appState.keys) {
        case .none:
            showingKeySetup = true
        case .nfc:
            Task { await scanNFC() }
        case .qr:
            showingQRScanner = true
        case .choose:
            showingKeyChooser = true
        }
    }
    
    private func handleHoldComplete() {
        appState.startBlockingWithHold()
    }
    
    private func scanNFC() async {
        isScanning = true
        defer { isScanning = false }
        do {
            let scannedKey = try await appState.nfcScanner.scan()
            applyScannedKey(scannedKey)
        } catch NFCScanError.userCancelled {
            return
        } catch {
            scanMessage = error.localizedDescription
        }
    }
    
    private func applyScannedKey(_ scannedKey: ScannedKey) {
        guard let matchedKey = appState.matchKey(scannedKey) else {
            scanMessage = appState.isBlocking ? "Wrong key" : "Unknown key"
            return
        }
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
        VStack(spacing: 12) {
            Text("Scan a key")
                .font(.system(size: 20, weight: .semibold))
                .padding(.top, 20)
            
            Button("Tap NFC key", action: onNFC)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.brickInk)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.brickCard))
                .accessibilityIdentifier(AccessibilityID.tapNFC)
            
            Button("Scan QR code", action: onQR)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.brickInk)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.brickCard))
                .accessibilityIdentifier(AccessibilityID.scanQR)
            
            Button("Cancel", action: onCancel)
                .font(.system(size: 15))
                .foregroundColor(Color.brickMuted)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .background(Color.brickCanvas)
    }
}

struct TodayTimePill: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        let time = appState.todayBlockedTime()
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        HStack(spacing: 6) {
            Text("\(hours)h \(minutes)m")
                .brickText(size: 19, weight: .medium, relativeTo: .title3)
                .foregroundColor(Color.brickInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text("today")
                .brickText(size: 14, relativeTo: .subheadline)
                .foregroundColor(Color.brickMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.brickCard)
        )
    }
}
