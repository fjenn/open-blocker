import SwiftUI

struct KeysManagementScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var appState = AppState.shared
    @State private var showingKeySetup = false
    
    var body: some View {
        ZStack {
            Color.brickCanvas
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    if appState.keys.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Color.brickInk)
                            
                            Text("No keys yet")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color.brickInk)
                            
                            Text("Keys are used for honesty, not security. Set up a physical key to block and unblock.")
                                .font(.system(size: 15))
                                .foregroundColor(Color.brickMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 80)
                    } else {
                        ForEach(appState.keys) { key in
                            KeyCard(key: key)
                        }
                    }
                }
                .padding()
                .padding(.bottom, 100)
            }
            
            VStack {
                Spacer()
                Button(action: { showingKeySetup = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Key")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.brickCard)
                            .shadow(radius: 10)
                    )
                }
                .accessibilityIdentifier(AccessibilityID.addKey)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("My Keys")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                .accessibilityIdentifier(AccessibilityID.navBack)
                .accessibilityLabel("Back")
            }
        }
        .sheet(isPresented: $showingKeySetup) {
            KeySetupScreen()
        }
    }
}

struct KeyCard: View {
    let key: BlockKey
    @StateObject private var appState = AppState.shared
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: key.icon)
                .font(.system(size: 28))
                .foregroundColor(.primary)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.brickPanel)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(key.name)
                    .font(.system(size: 17, weight: .semibold))
                
                Text(key.kind == .qr ? "QR Code" : key.kind == .openBlockerTag ? "NFC Tag" : "NFC Card")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("Added \(formattedDate)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(role: .destructive, action: { showingDeleteConfirm = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.brickCard)
        )
        .confirmationDialog(
            "Delete \"\(key.name)\"?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                appState.deleteKey(key)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You won't be able to use this key anymore.")
        }
    }
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: key.addedAt, relativeTo: Date())
    }
}
