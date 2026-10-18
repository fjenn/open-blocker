import SwiftUI

struct KeysManagementScreen: View {
    @StateObject private var appState = AppState.shared
    @State private var showingKeySetup = false
    
    var body: some View {
        PushedScreen(title: "My Keys") {
            ZStack(alignment: .bottom) {
                if appState.keys.isEmpty {
                    EmptyStateView(
                        systemImage: "key.fill",
                        title: "No keys yet",
                        message: "A key is the thing you hold: an NFC tag, a card, a printed QR, or a barcode. It is what unblocks you."
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Space.s) {
                            ForEach(appState.keys) { key in
                                KeyCard(key: key, canDelete: !appState.isBlocking)
                            }
                            if appState.isBlocking {
                                Text(addingLocked
                                     ? "Keys can't be added or removed while you're blocked."
                                     : "Keys can't be removed while you're blocked.")
                                    .textStyle(.footnote, weight: .regular)
                                    .foregroundColor(Color.inkTertiary)
                                    .padding(.top, Space.xs)
                            }
                        }
                        .padding(.horizontal, Space.margin)
                        .padding(.top, Space.xs)
                        .padding(.bottom, 120)
                    }
                }
                
                PrimaryButton(title: "Add Key", emphasis: .ink, accessibilityID: AccessibilityID.addKey) {
                    guard !addingLocked else { return }
                    showingKeySetup = true
                }
                .disabled(addingLocked)
                .opacity(addingLocked ? 0.4 : 1)
                .padding(.horizontal, Space.xxxl)
                .padding(.bottom, Space.l)
            }
        }
        .sheet(isPresented: $showingKeySetup) {
            KeySetupScreen()
        }
    }
    
    /// Rule "Don't allow adding new keys while blocked".
    private var addingLocked: Bool {
        !appState.canAddKeys
    }
}

extension BlockKey.Kind {
    var title: String {
        switch self {
        case .openBlockerTag: return "NFC tag"
        case .card: return "NFC card"
        case .qr: return "QR code"
        case .barcode: return "Barcode"
        }
    }
}

struct KeyCard: View {
    let key: BlockKey
    let canDelete: Bool
    @StateObject private var appState = AppState.shared
    @State private var confirmingDelete = false
    
    var body: some View {
        HStack(spacing: Space.m) {
            IconTile(systemName: key.icon, size: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text(key.name)
                    .textStyle(.headline)
                    .foregroundColor(Color.ink)
                Text("\(key.kind.title) · added \(addedText)")
                    .textStyle(.subhead)
                    .foregroundColor(Color.inkSecondary)
            }
            Spacer()
            Menu {
                Button(role: .destructive) { confirmingDelete = true } label: {
                    Label("Remove key", systemImage: "trash")
                }
                .disabled(!canDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.inkSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.fillQuiet))
            }
            .accessibilityLabel("Options for \(key.name)")
        }
        .padding(Space.m)
        .background(CardBackground())
        .confirmationDialog("Remove \"\(key.name)\"?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Remove", role: .destructive) { appState.deleteKey(key) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It won't unblock this phone anymore.")
        }
    }
    
    private var addedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: key.addedAt, relativeTo: Date())
    }
}
