import SwiftUI

struct SettingsTab: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var countManager = CountManager.shared
    @State private var notifyOn = SessionNotify.isEnabled
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.standard
    
    private var activeRulesCount: Int {
        let rules = appState.rules
        return [rules.preventDelete, rules.blockInstalls, rules.blockPurchases, rules.blockAdultWeb]
            .filter { $0 }
            .count
    }
    
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var body: some View {
        NavigationStack {
            TabScreen(title: "Settings") {
                VStack(alignment: .leading, spacing: Space.m) {
                    section {
                        link(
                            KeysManagementScreen(),
                            icon: "key",
                            title: "My Keys",
                            detail: "\(appState.keys.count)",
                            id: AccessibilityID.settingsKeys
                        )
                        HairlineDivider()
                        link(
                            RulesScreen(),
                            icon: "pencil.and.list.clipboard",
                            title: "My Rules",
                            detail: "\(activeRulesCount) on",
                            id: AccessibilityID.settingsRules
                        )
                        HairlineDivider()
                        link(
                            EmergencyUnblockScreen(),
                            icon: "lifepreserver",
                            title: "Emergency Unblock",
                            detail: "\(appState.emergencyStatus.remaining) left",
                            id: AccessibilityID.settingsEmergency
                        )
                        HairlineDivider()
                        link(
                            NotificationsScreen(),
                            icon: "bell",
                            title: "Notifications",
                            detail: notifyOn ? "On" : "Off",
                            id: AccessibilityID.settingsNotifications
                        )
                    }
                    
                    section {
                        VStack(alignment: .leading, spacing: Space.s) {
                            HStack(spacing: Space.s) {
                                RowGlyph(systemName: "circle.lefthalf.filled")
                                Text("Appearance")
                                    .textStyle(.body, weight: .medium)
                                    .foregroundColor(Color.ink)
                            }
                            SegmentedPill(
                                options: AppAppearance.allCases.map { ($0.title, $0) },
                                selection: $appearance
                            )
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Appearance")
                            .accessibilityIdentifier(AccessibilityID.appearancePicker)
                        }
                        .padding(Space.m)
                    }
                    
                    section {
                        link(HelpScreen(), icon: "questionmark.circle", title: "Help", id: AccessibilityID.settingsHelp)
                        HairlineDivider()
                        externalLink(
                            OpenBlockerLinks.feedback,
                            icon: "envelope",
                            title: "Contact & feedback",
                            id: AccessibilityID.settingsContact
                        )
                        HairlineDivider()
                        link(AboutScreen(), icon: "info.circle", title: "About", id: AccessibilityID.settingsAbout)
                        HairlineDivider()
                        link(PrivacyScreen(), icon: "hand.raised", title: "Privacy", id: AccessibilityID.settingsPrivacy)
                    }
                    
                    section {
                        SettingsToggleRow(
                            icon: "person.2",
                            title: "Share anonymous count",
                            subtitle: CountManager.summary,
                            isOn: Binding(
                                get: { countManager.isEnabled },
                                set: { countManager.setEnabled($0) }
                            ),
                            accessibilityID: AccessibilityID.countToggle
                        )
                    }
                    
                    VStack(spacing: Space.xxs) {
                        BrandMark(size: 30)
                            .padding(.bottom, Space.xxs)
                        Text("Open Blocker")
                            .textStyle(.headline)
                            .foregroundColor(Color.ink)
                        Text("Version \(version) · MIT License")
                            .textStyle(.footnote, weight: .regular)
                            .foregroundColor(Color.inkTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Space.l)
                }
            }
            .navigationBarHidden(true)
            .onAppear { notifyOn = SessionNotify.isEnabled }
        }
    }
    
    private func section<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        SettingsGroup { content() }
    }
    
    private func link<Destination: View>(
        _ destination: Destination,
        icon: String,
        title: String,
        detail: String? = nil,
        id: String
    ) -> some View {
        NavigationLink(destination: destination) {
            SettingsRow(icon: icon, title: title, detail: detail)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
    
    private func externalLink(_ url: URL, icon: String, title: String, id: String) -> some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            SettingsRow(icon: icon, title: title)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
        .accessibilityHint("Opens in Safari")
    }
}
