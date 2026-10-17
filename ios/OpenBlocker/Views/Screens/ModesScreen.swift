import SwiftUI
import FamilyControls
import ManagedSettings

struct ModesScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appState = AppState.shared
    @State private var editor: EditorTarget?
    
    /// Which editor sheet is open. An item (not a flag) so the sheet always
    /// gets the mode that was tapped.
    private enum EditorTarget: Identifiable {
        case new
        case edit(BlockMode)
        
        var id: String {
            switch self {
            case .new: return "new"
            case .edit(let mode): return mode.id.uuidString
            }
        }
        
        var mode: BlockMode? {
            if case .edit(let mode) = self { return mode }
            return nil
        }
    }
    
    var body: some View {
        SheetScaffold(
            title: "Select mode",
            leading: SheetAction(
                systemImage: "plus",
                accessibilityLabel: "New mode"
            ) {
                editor = .new
            },
            trailing: SheetAction(
                systemImage: "xmark",
                accessibilityLabel: "Close",
                accessibilityID: AccessibilityID.modesBack
            ) { dismiss() },
            primary: SheetAction(title: "Done") { dismiss() }
        ) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Space.s) {
                    ForEach(appState.modes) { mode in
                        ModeCard(mode: mode, isActive: appState.activeMode?.id == mode.id) {
                            editor = .edit(mode)
                        }
                    }
                }
                .padding(.horizontal, Space.margin)
                .padding(.top, Space.xs)
                .padding(.bottom, Space.l)
            }
        }
        .sheet(item: $editor) { target in
            ModeEditScreen(mode: target.mode)
        }
    }
}

struct ModeCard: View {
    let mode: BlockMode
    let isActive: Bool
    let onEdit: () -> Void
    @StateObject private var appState = AppState.shared
    @State private var confirmingDelete = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            HStack(alignment: .top, spacing: Space.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.name)
                        .textStyle(.body, weight: .semibold)
                        .foregroundColor(Color.ink)
                    Text(mode.subtitle)
                        .textStyle(.subhead)
                        .foregroundColor(Color.inkSecondary)
                }
                Spacer()
                RadioMark(isOn: isActive)
            }
            
            HStack(spacing: Space.xs) {
                appIcons
                Spacer()
                Button(action: onEdit) {
                    Text("Edit")
                        .textStyle(.footnote, weight: .semibold)
                        .foregroundColor(Color.ink)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 32)
                        .background(Capsule(style: .continuous).fill(Color.fillQuiet))
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityIdentifier(AccessibilityID.modeEdit)
                
                Menu {
                    Button(action: onEdit) { Label("Rename", systemImage: "pencil") }
                    Button { duplicate() } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                    if !mode.isDefault {
                        Button(role: .destructive) { confirmingDelete = true } label: { Label("Delete", systemImage: "trash") }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.ink)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.fillQuiet))
                }
                .accessibilityLabel("More")
            }
        }
        .padding(Space.m)
        .background(CardBackground(raised: isActive))
        .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .onTapGesture {
            withAnimation(Motion.standard) { appState.setActiveMode(mode) }
            UISelectionFeedbackGenerator().selectionChanged()
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .confirmationDialog("Delete \"\(mode.name)\"?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { appState.deleteMode(mode) }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    @ViewBuilder
    private var appIcons: some View {
        let tokens = Array(mode.selection.applicationTokens.prefix(4))
        if tokens.isEmpty {
            Text(mode.kind == .allowOnly ? "Allow only selected" : "Block selected")
                .textStyle(.footnote)
                .foregroundColor(Color.inkTertiary)
        } else {
            HStack(spacing: 6) {
                StackedAppIcons(tokens: tokens)
                let extra = mode.selection.applicationTokens.count - tokens.count
                if extra > 0 {
                    Text("+\(extra)")
                        .textStyle(.footnote)
                        .foregroundColor(Color.inkSecondary)
                }
            }
        }
    }
    
    private func duplicate() {
        appState.addMode(BlockMode(name: "\(mode.name) Copy", kind: mode.kind, selection: mode.selection))
    }
}

struct RadioMark: View {
    let isOn: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(isOn ? Color.clear : Color.inkTertiary, lineWidth: 1.2)
            if isOn {
                Circle().fill(Color.ink)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.inkInverse)
            }
        }
        .frame(width: 22, height: 22)
        .animation(Motion.pop, value: isOn)
        .accessibilityHidden(true)
    }
}

/// Overlapping app icons from Screen Time tokens.
struct StackedAppIcons: View {
    let tokens: [ApplicationToken]
    
    var body: some View {
        HStack(spacing: -7) {
            ForEach(tokens, id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.surface, lineWidth: 1.5)
                    )
            }
        }
    }
}
