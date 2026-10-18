import SwiftUI

struct RulesScreen: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        PushedScreen(title: "My Rules") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s) {
                    if appState.isBlocking {
                        Label("Rules are locked while you're blocked.", systemImage: "lock.fill")
                            .textStyle(.subhead, weight: .semibold)
                            .foregroundColor(Color.inkSecondary)
                            .padding(.horizontal, Space.xxs)
                            .accessibilityIdentifier("rules.lockedNotice")
                    }
                    rule("Prevent deleting Open Blocker", "While blocked, you can't delete this app.", \.preventDelete)
                    rule("Block app installs", "While blocked, the App Store can't install apps.", \.blockInstalls)
                    rule("Block in-app purchases", "No purchases while blocked.", \.blockPurchases)
                    rule("Block adult websites", "Uses Apple's adult content filter in Safari.", \.blockAdultWeb)
                    rule("Don't allow adding new keys while blocked", "New keys can only be added when you're not blocked.", \.blockAddingKeys)
                    
                    Text("Rules only apply while you're blocked. For the strongest setup, ask someone you trust to set a Screen Time passcode.")
                        .textStyle(.subhead)
                        .foregroundColor(Color.inkSecondary)
                        .padding(.horizontal, Space.xxs)
                        .padding(.top, Space.s)
                    
                    Button {
                        UIApplication.shared.open(OpenBlockerLinks.screenTimePasscode)
                    } label: {
                        Label("How to set a Screen Time passcode", systemImage: "arrow.up.right")
                            .labelStyle(TrailingIconLabelStyle())
                            .textStyle(.subhead, weight: .semibold)
                            .foregroundColor(Color.ink)
                    }
                    .padding(.horizontal, Space.xxs)
                }
                .padding(.horizontal, Space.margin)
                .padding(.top, Space.xs)
                .padding(.bottom, Space.xxxl)
            }
        }
    }
    
    /// One rule per card.
    private func rule(_ title: String, _ subtitle: String, _ keyPath: WritableKeyPath<Rules, Bool>) -> some View {
        SettingsGroup {
            ToggleRow(
            title: title,
            subtitle: subtitle,
            isOn: Binding(
                get: { appState.rules[keyPath: keyPath] },
                set: { newValue in
                    var rules = appState.rules
                    rules[keyPath: keyPath] = newValue
                    appState.rules = rules
                }
            )
            )
            .disabled(appState.isBlocking)
            .opacity(appState.isBlocking ? 0.5 : 1)
        }
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon.font(.system(size: 11, weight: .bold))
        }
    }
}
