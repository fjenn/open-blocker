import SwiftUI
import CoreImage.CIFilterBuiltins

struct KeySetupScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appState = AppState.shared
    @State private var kind: BlockKey.Kind = .qr
    @State private var keyName = ""
    @State private var secret = ""
    @State private var nameNeedsAttention = false
    @State private var nameShake = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Called after a key is saved (onboarding uses it to move on).
    var onSaved: (() -> Void)? = nil
    
    private var trimmedName: String {
        keyName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var hasSecret: Bool {
        !secret.isEmpty
    }
    
    var body: some View {
        SheetScaffold(
            title: "Add Key",
            trailing: SheetAction(systemImage: "xmark", accessibilityLabel: "Cancel") { dismiss() },
            primary: SheetAction(title: "Save Key", isEnabled: hasSecret, accessibilityID: AccessibilityID.saveKey) { save() }
        ) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s) {
                    SegmentedPill(
                        options: [
                            ("QR", BlockKey.Kind.qr),
                            ("Barcode", BlockKey.Kind.barcode),
                            ("NFC tag", BlockKey.Kind.openBlockerTag),
                            ("Card", BlockKey.Kind.card)
                        ],
                        selection: $kind
                    )
                    .onChange(of: kind) { _ in secret = "" }
                    
                    SettingsGroup {
                        FormTextField(
                            label: "Key Name",
                            placeholder: placeholder,
                            text: $keyName,
                            accessibilityID: AccessibilityID.keyName
                        )
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.group, style: .continuous)
                            .stroke(nameNeedsAttention ? Color.danger : Color.clear, lineWidth: 1.5)
                    )
                    .shake(trigger: nameShake, reducedMotion: reduceMotion)
                    .onChange(of: keyName) { _ in
                        if nameNeedsAttention { nameNeedsAttention = false }
                    }
                    
                    if nameNeedsAttention {
                        Text(KeySetupScreen.missingNameHint)
                            .textStyle(.footnote)
                            .foregroundColor(Color.danger)
                            .padding(.leading, Space.xxs)
                            .accessibilityIdentifier(AccessibilityID.keyNameHint)
                    }
                    
                    Group {
                        switch kind {
                        case .qr: QRKeySetupView(secret: $secret)
                        case .barcode: BarcodeKeySetupView(secret: $secret)
                        case .openBlockerTag: NFCTagSetupView(secret: $secret)
                        case .card: NFCCardSetupView(secret: $secret)
                        }
                    }
                    .id(kind)
                    .padding(.top, Space.xs)
                }
                .padding(.horizontal, Space.margin)
                .padding(.top, Space.xxs)
                .padding(.bottom, Space.l)
            }
        }
        .accessibilityIdentifier(AccessibilityID.keySetupRoot)
    }
    
    private var placeholder: String {
        switch kind {
        case .qr: return "Fridge QR"
        case .barcode: return "Cereal box"
        case .openBlockerTag: return "Desk tag"
        case .card: return "Gym card"
        }
    }
    
    private func save() {
        guard hasSecret else { return }
        guard !trimmedName.isEmpty else {
            promptForName()
            return
        }
        guard appState.canAddKeys else { dismiss(); return }
        appState.addKey(BlockKey(name: trimmedName, kind: kind, secret: secret))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSaved?()
        dismiss()
    }
    
    private func promptForName() {
        nameNeedsAttention = true
        nameShake += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIAccessibility.post(notification: .announcement, argument: Self.missingNameHint)
    }
    
    static let missingNameHint = "Add a name"
}

/// Shared card for the three key types: medallion, copy, status, action.
private struct SetupPanel<Accessory: View>: View {
    let icon: String
    let title: String
    let message: String
    var status: String? = nil
    var statusIsGood = false
    var actionTitle: String? = nil
    var actionBusy = false
    var action: (() -> Void)? = nil
    @ViewBuilder var accessory: Accessory
    
    var body: some View {
        VStack(spacing: Space.m) {
            accessory
            ZStack {
                Circle().fill(Color.fillQuiet).frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundColor(Color.ink)
            }
            Text(title)
                .textStyle(.headline)
                .foregroundColor(Color.ink)
            Text(message)
                .textStyle(.subhead)
                .foregroundColor(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let status {
                Label(status, systemImage: statusIsGood ? "checkmark.circle.fill" : "info.circle")
                    .textStyle(.footnote)
                    .foregroundColor(statusIsGood ? Color.success : Color.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                PrimaryButton(title: actionBusy ? "Hold it near the top of your iPhone" : actionTitle, isEnabled: !actionBusy, action: action)
                    .padding(.top, Space.xxs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Space.l)
        .background(CardBackground())
    }
}

extension SetupPanel where Accessory == EmptyView {
    init(icon: String, title: String, message: String, status: String? = nil, statusIsGood: Bool = false,
         actionTitle: String? = nil, actionBusy: Bool = false, action: (() -> Void)? = nil) {
        self.init(icon: icon, title: title, message: message, status: status, statusIsGood: statusIsGood,
                  actionTitle: actionTitle, actionBusy: actionBusy, action: action, accessory: { EmptyView() })
    }
}

struct QRKeySetupView: View {
    @Binding var secret: String
    @State private var qrImage: UIImage?
    
    var body: some View {
        if let image = qrImage {
            VStack(spacing: Space.m) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(Space.l)
                    .frame(width: 240, height: 240)
                    .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.white))
                    .shadow(color: Color.floatShadow, radius: 20, y: 8)
                Text("Print it or save it somewhere you have to walk to. Scan it to unblock.")
                    .textStyle(.subhead)
                    .foregroundColor(Color.inkSecondary)
                    .multilineTextAlignment(.center)
                ShareLink(item: Image(uiImage: image), preview: SharePreview("Open Blocker key", image: Image(uiImage: image))) {
                    Label("Share or print", systemImage: "square.and.arrow.up")
                        .textStyle(.footnote, weight: .semibold)
                        .foregroundColor(Color.ink)
                        .padding(.horizontal, Space.m)
                        .frame(minHeight: 36)
                        .background(Capsule(style: .continuous).fill(Color.fillQuiet))
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            SetupPanel(
                icon: "qrcode",
                title: "A printed QR key",
                message: "Make a code, print it, and keep it away from your phone.",
                actionTitle: "Make QR code",
                action: generate
            )
        }
    }
    
    private func generate() {
        let payload = OpenBlockerFormat.encodeForQR(OpenBlockerFormat.TagData(tagId: OpenBlockerFormat.generateTagId()))
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cgImage = CIContext().createCGImage(output, from: output.extent) else {
            return
        }
        withAnimation(Motion.standard) {
            qrImage = UIImage(cgImage: cgImage)
        }
        secret = payload
    }
}

/// Any barcode you own (a product, a library card) as a key. The raw
/// barcode value is the secret; scanning it later must give the same value.
struct BarcodeKeySetupView: View {
    @Binding var secret: String
    @State private var showingScanner = false
    @State private var deniedPermission: Permission?
    
    var body: some View {
        SetupPanel(
            icon: "barcode",
            title: "A barcode or QR code you own",
            message: "Scan one on something you keep away from your phone.",
            status: secret.isEmpty ? nil : "Barcode ready.",
            statusIsGood: !secret.isEmpty,
            actionTitle: secret.isEmpty ? "Scan barcode" : "Scan again",
            action: {
                Permissions.whenGranted(.camera, denied: $deniedPermission) {
                    showingScanner = true
                }
            }
        )
        .sheet(isPresented: $showingScanner) {
            QRScannerView(
                onCode: { payload in
                    showingScanner = false
                    if case .barcode(let value) = KeyScanner.scannedKey(fromCode: payload) {
                        secret = value
                    }
                },
                onCancel: { showingScanner = false }
            )
        }
        .permissionSheet($deniedPermission)
    }
}

struct NFCTagSetupView: View {
    @Binding var secret: String
    @ObservedObject var appState = AppState.shared
    @State private var isScanning = false
    @State private var status: String?
    
    var body: some View {
        SetupPanel(
            icon: "wave.3.right",
            title: "An NFC sticker",
            message: "Use a blank NTAG213, 215 or 216. Open Blocker writes its own record onto it.",
            status: status,
            statusIsGood: !secret.isEmpty,
            actionTitle: secret.isEmpty ? "Scan tag" : "Scan again",
            actionBusy: isScanning,
            action: register
        )
    }
    
    private func register() {
        isScanning = true
        Task {
            defer { isScanning = false }
            do {
                let scanned = try await appState.nfcScanner.scan()
                guard let uid = KeyRegistration.nfcUIDHex(from: scanned) else {
                    status = "That was not an NFC tag."
                    return
                }
                do {
                    try await appState.nfcScanner.writeOpenBlockerRecord(tagId: OpenBlockerFormat.generateTagId())
                    status = "Tag ready."
                } catch {
                    status = "Tag ready. It works by its chip ID."
                }
                secret = uid
            } catch NFCScanError.userCancelled {
                status = nil
            } catch {
                status = error.localizedDescription
            }
        }
    }
}

struct NFCCardSetupView: View {
    @Binding var secret: String
    @ObservedObject var appState = AppState.shared
    @State private var firstScan: String?
    @State private var isScanning = false
    @State private var status: String?
    
    var body: some View {
        SetupPanel(
            icon: "creditcard",
            title: "A card you own",
            message: "Transit cards, hotel keys and work badges often work. Not every card works. Test yours. Scan it twice so we know its ID is stable.",
            status: status,
            statusIsGood: !secret.isEmpty,
            actionTitle: secret.isEmpty ? (firstScan == nil ? "Scan card" : "Scan it again") : "Start over",
            actionBusy: isScanning,
            action: scan
        )
    }
    
    private func scan() {
        if !secret.isEmpty {
            secret = ""
            firstScan = nil
            status = nil
            return
        }
        isScanning = true
        Task {
            defer { isScanning = false }
            do {
                let scanned = try await appState.nfcScanner.scan()
                guard let uid = KeyRegistration.nfcUIDHex(from: scanned) else {
                    status = "That was not an NFC card."
                    return
                }
                guard let first = firstScan else {
                    firstScan = uid
                    status = "Got it. Scan the same card once more."
                    return
                }
                switch KeyRegistration.confirmCard(firstUID: first, secondUID: uid) {
                case .match(let confirmed):
                    secret = confirmed
                    status = "Card ready."
                case .rotating:
                    firstScan = nil
                    status = KeyRegistration.rotatingCardMessage
                }
            } catch NFCScanError.userCancelled {
                return
            } catch {
                status = error.localizedDescription
            }
        }
    }
}
