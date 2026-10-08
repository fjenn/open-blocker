import SwiftUI

struct SettingsTab: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var countManager = CountManager.shared
    @State private var notifyOn = SessionNotify.isEnabled
    
    private var activeRulesCount: Int {
        var count = 0
        if appState.rules.preventDelete { count += 1 }
        if appState.rules.blockInstalls { count += 1 }
        if appState.rules.blockPurchases { count += 1 }
        if appState.rules.blockAdultWeb { count += 1 }
        return count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brickCanvas
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Settings")
                            .brickText(size: 20, weight: .medium, relativeTo: .title3)
                            .foregroundColor(Color.brickInk)
                            .padding(.top, 40)
                    
                    VStack(spacing: 12) {
                        NavigationLink(destination: KeysManagementScreen().hidesTabBar()) {
                            SettingsRowView(
                                icon: "key.fill",
                                title: "My Keys",
                                detail: "\(appState.keys.count)"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier(AccessibilityID.settingsKeys)
                        
                        NavigationLink(destination: EmergencyUnblockScreen().hidesTabBar()) {
                            SettingsRowView(
                                icon: "lock.open.fill",
                                title: "Emergency Unblock",
                                detail: "\(appState.emergencyStatus.remaining)"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier(AccessibilityID.settingsEmergency)
                        
                        NavigationLink(destination: RulesScreen().hidesTabBar()) {
                            SettingsRowView(
                                icon: "shield.fill",
                                title: "My Rules",
                                detail: "\(activeRulesCount)"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier(AccessibilityID.settingsRules)
                        
                        NavigationLink(destination: NotificationsScreen()) {
                            SettingsRowView(
                                icon: "bell.fill",
                                title: "Notifications",
                                detail: notifyOn ? "On" : "Off"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier(AccessibilityID.settingsNotifications)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        NavigationLink(destination: HelpScreen()) {
                            SettingsRowView(
                                icon: "questionmark.circle.fill",
                                title: "Help",
                                detail: nil
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier(AccessibilityID.settingsHelp)
                        
                        NavigationLink(destination: ContactScreen()) {
                            SettingsRowView(
                                icon: "envelope.fill",
                                title: "Contact",
                                detail: nil
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier(AccessibilityID.settingsContact)
                        
                        NavigationLink(destination: AboutScreen()) {
                            SettingsRowView(
                                icon: "info.circle.fill",
                                title: "About",
                                detail: nil
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier(AccessibilityID.settingsAbout)
                        
                        Button(action: {
                            UIApplication.shared.open(OpenBlockerLinks.privacy)
                        }) {
                            SettingsRowView(
                                icon: "hand.raised.fill",
                                title: "Privacy",
                                detail: nil
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color.brickInk)
                                .frame(width: 24)
                            Text("Opt-in Count")
                                .brickText(size: 17, relativeTo: .body)
                                .foregroundColor(Color.brickInk)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                            Spacer(minLength: 12)
                            Toggle("", isOn: Binding(
                                get: { countManager.isEnabled },
                                set: { countManager.setEnabled($0) }
                            ))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.brickCard)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, BrickLayout.tabScrollInset)
                    }
                }
            }
            .onAppear { notifyOn = SessionNotify.isEnabled }
        }
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let detail: String?
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color.brickInk)
                .frame(width: 24)
            Text(title)
                .brickText(size: 17, relativeTo: .body)
                .foregroundColor(Color.brickInk)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            if let detail = detail {
                Text(detail)
                    .brickText(size: 17, relativeTo: .callout)
                    .foregroundColor(Color.brickSecondaryLabel)
                    .fixedSize()
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.brickSecondaryLabel)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.brickCard)
        )
    }
}
