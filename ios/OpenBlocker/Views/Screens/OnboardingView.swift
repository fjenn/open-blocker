import SwiftUI

struct OnboardingView: View {
    @StateObject private var appState = AppState.shared
    @State private var page = 0
    @State private var screenTimeNote: String?
    @State private var requesting = false
    @State private var selectedKeyType: BlockKey.Kind = .qr
    @State private var registeredKeyId: String = ""
    @State private var showingQRScanner = false
    @State private var isScanning = false
    @State private var scanStatus = ""
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                OnboardingPage(
                    title: "Open Blocker",
                    subtitle: "A physical key starts and stops a block. Honesty, not a lock you cannot break.",
                    systemImage: "lock.shield"
                )
                .tag(0)
                
                OnboardingPage(
                    title: "Screen Time",
                    subtitle: "Apple's Screen Time permission is what actually hides apps while you are blocked.",
                    systemImage: "hourglass",
                    note: screenTimeNote
                )
                .tag(1)
                
                OnboardingPage(
                    title: "Your key",
                    subtitle: "Choose what kind of key you want to use.",
                    systemImage: "key.fill"
                )
                .tag(2)
                
                OnboardingKeySetup(
                    selectedType: $selectedKeyType,
                    registeredKeyId: $registeredKeyId,
                    isScanning: $isScanning,
                    scanStatus: $scanStatus,
                    onScan: { handleKeyScan() },
                    onQRGenerate: { handleQRGenerate() }
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color.brickInk : Color.brickMuted)
                        .frame(width: index == page ? 18 : 8, height: 8)
                }
            }
            .padding(.bottom, 20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(page + 1) of 4")
            
            Button(action: advance) {
                Text(buttonTitle)
                    .brickText(size: 17, weight: .medium, relativeTo: .body)
                    .foregroundColor(Color.brickInk)
                    .frame(maxWidth: .infinity, minHeight: 51)
                    .background(
                        Capsule()
                            .fill(Color.brickButton)
                    )
                    .shadow(color: .black.opacity(requesting ? 0 : 0.12), radius: 8, y: 4)
            }
            .disabled(requesting)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .accessibilityIdentifier(AccessibilityID.onboardingContinue)
        }
        .background(Color.brickCanvas.ignoresSafeArea())
        .sheet(isPresented: $showingQRScanner) {
            QRScannerView(
                onCode: { payload in
                    showingQRScanner = false
                    registeredKeyId = payload
                    let key = BlockKey(name: "My Barcode", kind: .barcode, secret: payload)
                    appState.addKey(key)
                    scanStatus = "Barcode registered successfully"
                },
                onCancel: { showingQRScanner = false }
            )
        }
    }
    
    private var buttonTitle: String {
        if requesting { return "Asking..." }
        if isScanning { return "Scanning..." }
        switch page {
        case 0:
            return "Continue"
        case 1:
            return screenTimeNote == nil ? "Allow Screen Time" : "Continue"
        case 2:
            return "Continue"
        case 3:
            return registeredKeyId.isEmpty ? "Add Key" : "Finish"
        default:
            return "Continue"
        }
    }
    
    private func advance() {
        if page == 1 && screenTimeNote == nil {
            requesting = true
            Task {
                let ok = await appState.requestAuthorization()
                await MainActor.run {
                    requesting = false
                    if ok {
                        screenTimeNote = "Screen Time is on. Blocking can use Apple's shields."
                    } else {
                        #if targetEnvironment(simulator)
                        screenTimeNote = "The simulator cannot grant Screen Time. On your iPhone, Apple's permission sheet will appear here."
                        #else
                        screenTimeNote = "Screen Time was not granted. You can try again later from iPhone Settings."
                        #endif
                    }
                }
            }
            return
        }
        
        if page == 3 {
            if registeredKeyId.isEmpty {
                // Trigger key registration based on selected type
                if selectedKeyType == .qr {
                    handleQRGenerate()
                } else if selectedKeyType == .barcode {
                    showingQRScanner = true
                } else {
                    handleKeyScan()
                }
                return
            } else {
                // Key registered, finish onboarding
                appState.completeOnboarding()
                return
            }
        }
        
        if page < 3 {
            withAnimation { page += 1 }
        }
    }
    
    private func handleQRGenerate() {
        let data = OpenBlockerFormat.TagData(tagId: OpenBlockerFormat.generateTagId())
        let payload = OpenBlockerFormat.encodeForQR(data)
        registeredKeyId = payload
        let key = BlockKey(name: "My QR Key", kind: .qr, secret: payload)
        appState.addKey(key)
        scanStatus = "QR code generated and saved"
    }
    
    private func handleKeyScan() {
        isScanning = true
        scanStatus = ""
        Task {
            defer { isScanning = false }
            do {
                let scannedKey = try await appState.nfcScanner.scan(keyMatcher: nil)
                guard let uid = KeyRegistration.nfcUIDHex(from: scannedKey) else {
                    scanStatus = "Could not read tag"
                    return
                }
                registeredKeyId = uid
                let kind: BlockKey.Kind = selectedKeyType == .openBlockerTag ? .openBlockerTag : .card
                let name = selectedKeyType == .openBlockerTag ? "My NFC Tag" : "My Card"
                let key = BlockKey(name: name, kind: kind, secret: uid)
                appState.addKey(key)
                scanStatus = "Key registered successfully"
            } catch NFCScanError.userCancelled {
                scanStatus = ""
            } catch {
                scanStatus = error.localizedDescription
            }
        }
    }
}

struct OnboardingKeySetup: View {
    @Binding var selectedType: BlockKey.Kind
    @Binding var registeredKeyId: String
    @Binding var isScanning: Bool
    @Binding var scanStatus: String
    var onScan: () -> Void
    var onQRGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Add your first key")
                .brickText(size: 28, weight: .medium, relativeTo: .title)
                .foregroundColor(Color.brickInk)
            
            Text("Pick a type and register it now")
                .brickText(size: 16, relativeTo: .body)
                .foregroundColor(Color.brickMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    keyTypeButton(kind: .qr, icon: "qrcode", label: "QR")
                    keyTypeButton(kind: .barcode, icon: "barcode", label: "Barcode")
                }
                HStack(spacing: 12) {
                    keyTypeButton(kind: .openBlockerTag, icon: "wave.3.right", label: "NFC Tag")
                    keyTypeButton(kind: .card, icon: "creditcard", label: "Card")
                }
            }
            .padding(.horizontal, 40)
            
            if !scanStatus.isEmpty {
                Text(scanStatus)
                    .brickText(size: 14, relativeTo: .callout)
                    .foregroundColor(registeredKeyId.isEmpty ? Color.brickMuted : Color.brickAccent)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if !registeredKeyId.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.brickAccent)
                    Text("Key registered")
                        .brickText(size: 15, weight: .medium, relativeTo: .body)
                        .foregroundColor(Color.brickInk)
                }
            }
            
            Spacer()
        }
    }
    
    private func keyTypeButton(kind: BlockKey.Kind, icon: String, label: String) -> some View {
        Button(action: { selectedType = kind }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(selectedType == kind ? Color.brickInk : Color.brickMuted)
                Text(label)
                    .brickText(size: 13, weight: .medium, relativeTo: .caption)
                    .foregroundColor(selectedType == kind ? Color.brickInk : Color.brickMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selectedType == kind ? Color.brickCard : Color.brickPanel)
            )
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var note: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: systemImage)
                .font(.system(size: 64, weight: .regular))
                .foregroundColor(Color.brickInk)
            
            Text(title)
                .brickText(size: 28, weight: .medium, relativeTo: .title)
                .foregroundColor(Color.brickInk)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .brickText(size: 16, relativeTo: .body)
                .foregroundColor(Color.brickMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            
            if let note {
                Text(note)
                    .brickText(size: 15, relativeTo: .callout)
                    .foregroundColor(Color.brickInk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 4)
                    .accessibilityIdentifier(AccessibilityID.onboardingNote)
            }
            
            Spacer()
        }
    }
}
