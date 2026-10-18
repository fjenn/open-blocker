import SwiftUI
import FamilyControls

/// Create or edit a mode. New modes start on a template step; choosing a
/// template pre-fills the name and behavior, and you can change both. A
/// template with a usual time also offers to schedule the new mode.
struct ModeEditScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appState = AppState.shared
    
    let mode: BlockMode?
    
    @State private var template: ModeTemplate?
    @State private var name: String
    @State private var kind: BlockMode.Kind
    @State private var selection: FamilyActivitySelection
    @State private var showingAppPicker = false
    @State private var deniedPermission: Permission?
    @State private var addsSchedule = false
    @FocusState private var nameFocused: Bool
    
    init(mode: BlockMode? = nil) {
        self.mode = mode
        _name = State(initialValue: mode?.name ?? "")
        _kind = State(initialValue: mode?.kind ?? .block)
        _selection = State(initialValue: mode?.selection ?? FamilyActivitySelection())
    }
    
    private var isChoosingTemplate: Bool {
        mode == nil && template == nil
    }
    
    private var pickedSummary: String {
        let apps = selection.applicationTokens.count
        let categories = selection.categoryTokens.count
        let sites = selection.webDomainTokens.count
        if apps + categories + sites == 0 { return "None" }
        var parts: [String] = []
        if apps > 0 { parts.append("\(apps) app\(apps == 1 ? "" : "s")") }
        if categories > 0 { parts.append("\(categories) categor\(categories == 1 ? "y" : "ies")") }
        if sites > 0 { parts.append("\(sites) site\(sites == 1 ? "" : "s")") }
        return parts.joined(separator: " · ")
    }
    
    var body: some View {
        Group {
            if isChoosingTemplate {
                templatePicker
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                form
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(Motion.standard, value: template)
        .familyActivityPicker(isPresented: $showingAppPicker, selection: $selection)
        .permissionSheet($deniedPermission)
    }
    
    /// Apple's app picker needs Screen Time, so ask for it first.
    private func openAppPicker() {
        Permissions.whenGranted(.screenTime, denied: $deniedPermission) {
            showingAppPicker = true
        }
    }
    
    private var closeAction: SheetAction {
        SheetAction(systemImage: "xmark", accessibilityLabel: "Cancel") { dismiss() }
    }
    
    // MARK: Template step
    
    private var templatePicker: some View {
        SheetScaffold(title: "New mode", trailing: closeAction) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s) {
                    Text("Start from a template. You can rename it and change everything later.")
                        .textStyle(.footnote, weight: .regular)
                        .foregroundColor(Color.inkSecondary)
                        .padding(.horizontal, Space.xxs)
                        .padding(.bottom, Space.xxs)
                    ForEach(ModeTemplate.allCases) { option in
                        Button { choose(option) } label: {
                            TemplateCard(template: option)
                        }
                        .buttonStyle(PressScaleStyle())
                        .accessibilityIdentifier("mode-template-\(option.rawValue)")
                    }
                }
                .padding(.horizontal, Space.margin)
                .padding(.top, Space.xxs)
                .padding(.bottom, Space.l)
            }
        }
        .accessibilityIdentifier(AccessibilityID.modeTemplates)
    }
    
    private func choose(_ option: ModeTemplate) {
        name = option.name
        kind = option.kind
        selection = FamilyActivitySelection()
        addsSchedule = false
        template = option
        if option.opensAppPicker {
            // Screen Time only lets you pick apps yourself, so open the picker.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { openAppPicker() }
        } else if option.name.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { nameFocused = true }
        }
    }
    
    // MARK: Form step
    
    private var form: some View {
        SheetScaffold(
            title: mode == nil ? "New mode" : "Edit mode",
            leading: mode == nil
                ? SheetAction(systemImage: "chevron.left", accessibilityLabel: "Templates") { template = nil }
                : nil,
            trailing: closeAction,
            primary: SheetAction(title: "Save mode", isEnabled: ModeName.validated(name) != nil) { save() }
        ) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s) {
                    SettingsGroup {
                        FormTextField(label: "Name", placeholder: ModeName.placeholder, text: $name)
                            .focused($nameFocused)
                            .accessibilityIdentifier(AccessibilityID.modeName)
                    }
                    
                    SettingsGroup {
                        VStack(alignment: .leading, spacing: Space.s) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Behavior")
                                    .textStyle(.subhead, weight: .semibold)
                                    .foregroundColor(Color.ink)
                                Text("Choose what this mode limits while you're blocked.")
                                    .textStyle(.footnote, weight: .regular)
                                    .foregroundColor(Color.inkSecondary)
                            }
                            SegmentedPill(
                                options: [("Block selected", BlockMode.Kind.block), ("Allow only selected", BlockMode.Kind.allowOnly)],
                                selection: $kind
                            )
                        }
                        .padding(Space.m)
                        
                        HairlineDivider()
                        
                        Button { openAppPicker() } label: {
                            VStack(alignment: .leading, spacing: Space.xs) {
                                SettingsRow(
                                    icon: "square.grid.2x2",
                                    title: kind == .block ? "Blocked apps and sites" : "Allowed apps",
                                    detail: pickedSummary
                                )
                                let tokens = Array(selection.applicationTokens.prefix(6))
                                if !tokens.isEmpty {
                                    StackedAppIcons(tokens: tokens)
                                        .padding(.leading, Space.m + 22 + Space.s)
                                        .padding(.bottom, Space.m)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        
                        InfoNote(text: kind == .block
                                 ? "Only what you pick is blocked. Everything else works as usual."
                                 : "Everything is blocked except the apps you pick.")
                            .padding([.horizontal, .bottom], Space.m)
                    }
                    
                    if mode == nil, let summary = template?.scheduleSummary {
                        SettingsGroup {
                            SettingsToggleRow(
                                icon: "calendar",
                                title: "Schedule it",
                                subtitle: "\(summary). Change it any time in Schedule.",
                                isOn: Binding(get: { addsSchedule }, set: setAddsSchedule),
                                accessibilityID: AccessibilityID.modeSchedule
                            )
                        }
                    }
                }
                .padding(.horizontal, Space.margin)
                .padding(.top, Space.xxs)
                .padding(.bottom, Space.l)
            }
        }
    }
    
    /// Schedules block through Screen Time, so turning one on asks for it.
    private func setAddsSchedule(_ on: Bool) {
        guard on else { return addsSchedule = false }
        Permissions.whenGranted(.screenTime, denied: $deniedPermission) { addsSchedule = true }
    }
    
    private func save() {
        guard let validName = ModeName.validated(name) else { return }
        if var updated = mode {
            updated.name = validName
            updated.kind = kind
            updated.selection = selection
            appState.updateMode(updated)
        } else {
            let created = BlockMode(name: validName, kind: kind, selection: selection)
            appState.addMode(created)
            if addsSchedule, let schedule = template?.suggestedSchedule(for: created) {
                appState.addSchedule(schedule)
            }
        }
        dismiss()
    }
}

/// One template choice: icon, name, what it does.
private struct TemplateCard: View {
    let template: ModeTemplate
    
    var body: some View {
        HStack(spacing: Space.s) {
            IconTile(systemName: template.symbol, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(template.title)
                    .textStyle(.body, weight: .semibold)
                    .foregroundColor(Color.ink)
                Text(template.summary)
                    .textStyle(.footnote, weight: .regular)
                    .foregroundColor(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Space.xs)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.inkTertiary)
        }
        .padding(Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackground())
        .contentShape(Rectangle())
    }
}
