import SwiftUI
import FamilyControls

struct ModesScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var appState = AppState.shared
    @State private var showingModeEditor = false
    @State private var editingMode: BlockMode?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.brickCanvas
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(appState.modes) { mode in
                            ModeCard(mode: mode, onEdit: {
                                editingMode = mode
                                showingModeEditor = true
                            })
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Modes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                    .accessibilityIdentifier(AccessibilityID.modesBack)
                    .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingMode = nil
                        showingModeEditor = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingModeEditor) {
                ModeEditScreen(mode: editingMode)
            }
        }
    }
}

struct ModeCard: View {
    let mode: BlockMode
    let onEdit: () -> Void
    @StateObject private var appState = AppState.shared
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(mode.name)
                    .font(.system(size: 19, weight: .semibold))
                
                Text(mode.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    let selection = mode.selection
                    ForEach(Array(selection.applicationTokens.prefix(3)), id: \.self) { token in
                        Label(token)
                            .labelStyle(.iconOnly)
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                    }
                    if selection.applicationTokens.count > 3 {
                        Text("+\(selection.applicationTokens.count - 3)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if appState.activeMode?.id == mode.id {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            } else {
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
            }
            
            Button(action: onEdit) {
                Text("Edit")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.brickPanel)
                    )
            }
            .accessibilityIdentifier(AccessibilityID.modeEdit)
            
            Menu {
                Button(action: {
                    duplicateMode()
                }) {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                
                if !mode.isDefault {
                    Button(role: .destructive, action: {
                        showingDeleteConfirm = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.brickPanel)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.brickCard)
        )
        .onTapGesture {
            appState.setActiveMode(mode)
        }
        .confirmationDialog(
            "Delete \"\(mode.name)\"?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                appState.deleteMode(mode)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func duplicateMode() {
        let copy = BlockMode(
            name: "\(mode.name) Copy",
            kind: mode.kind,
            selection: mode.selection
        )
        appState.addMode(copy)
    }
}
