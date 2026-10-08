// Rules settings screen

import SwiftUI

struct RulesScreen: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.brickCanvas
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 14) {
                    ruleToggle(
                        title: "Prevent deleting Open Blocker",
                        subtitle: "While blocked, you can't delete this app.",
                        isOn: Binding(
                            get: { appState.rules.preventDelete },
                            set: { newValue in
                                var rules = appState.rules
                                rules.preventDelete = newValue
                                appState.rules = rules
                            }
                        )
                    )
                    
                    ruleToggle(
                        title: "Block app installs",
                        subtitle: "While blocked, the App Store can't install apps.",
                        isOn: Binding(
                            get: { appState.rules.blockInstalls },
                            set: { newValue in
                                var rules = appState.rules
                                rules.blockInstalls = newValue
                                appState.rules = rules
                            }
                        )
                    )
                    
                    ruleToggle(
                        title: "Block in-app purchases",
                        subtitle: "Prevent purchases while blocked.",
                        isOn: Binding(
                            get: { appState.rules.blockPurchases },
                            set: { newValue in
                                var rules = appState.rules
                                rules.blockPurchases = newValue
                                appState.rules = rules
                            }
                        )
                    )
                    
                    ruleToggle(
                        title: "Block adult websites",
                        subtitle: "Uses Apple's adult content filter in Safari.",
                        isOn: Binding(
                            get: { appState.rules.blockAdultWeb },
                            set: { newValue in
                                var rules = appState.rules
                                rules.blockAdultWeb = newValue
                                appState.rules = rules
                            }
                        )
                    )
                }
                .padding(16)
                
                VStack(spacing: 12) {
                    Text("Rules only apply while you're blocked. For the strongest setup, ask someone you trust to set a Screen Time passcode.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.brickMuted)
                        .multilineTextAlignment(.leading)
                    
                    Button(action: {
                        UIApplication.shared.open(OpenBlockerLinks.screenTimePasscode)
                    }) {
                        Text("How to set a Screen Time passcode")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.brickInk)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationTitle("My Rules")
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
    }
    
    private func ruleToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.brickCard)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color.brickInk)
                        
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.brickMuted)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: isOn)
                        .labelsHidden()
                        .tint(Color.brickAccent)
                }
            }
            .padding(20)
        }
    }
}
