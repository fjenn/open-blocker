// Rules settings screen

import SwiftUI

struct RulesScreen: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        let isBlocked = appState.isBlocking
        
        ZStack {
            Color.brickCanvas
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 14) {
                    if isBlocked {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.brickCard)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.brickMuted)
                                
                                Text("Rules can't be changed while you're blocked.")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Color.brickMuted)
                                
                                Spacer()
                            }
                            .padding(20)
                        }
                    }
                    
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
                    
                    ruleToggle(
                        title: "Don't allow adding new keys while blocked",
                        subtitle: "Prevents adding keys during a block.",
                        isOn: Binding(
                            get: { appState.rules.blockAddingKeys },
                            set: { newValue in
                                var rules = appState.rules
                                rules.blockAddingKeys = newValue
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
        let isBlocked = appState.isBlocking
        
        return ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.brickCard)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(isBlocked ? Color.brickMuted : Color.brickInk)
                        
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.brickMuted)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: isOn)
                        .labelsHidden()
                        .tint(Color.brickAccent)
                        .disabled(isBlocked)
                }
            }
            .padding(20)
        }
    }
}
