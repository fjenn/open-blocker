import SwiftUI

struct HelpScreen: View {
    var body: some View {
        BrickPushedScreen(title: "Help") {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    faq(
                        title: "How keys work",
                        body: "A physical key (NFC tag, card, or printed QR) starts and stops a block. Open the app and tap it. Honesty, not a lock you cannot break."
                    )
                    faq(
                        title: "Emergency unblocks",
                        body: "If you cannot tap your key, use an emergency unblock to end a session. You get five. One returns every 30 days."
                    )
                    faq(
                        title: "Why some cards fail",
                        body: KeyRegistration.rotatingCardMessage
                    )
                    faq(
                        title: "Screen Time passcode",
                        body: "Apple's shields are stronger if someone you trust sets a Screen Time passcode."
                    )
                    
                    Button(action: {
                        UIApplication.shared.open(OpenBlockerLinks.screenTimePasscode)
                    }) {
                        Text("How to set a Screen Time passcode")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.brickInk)
                            .frame(maxWidth: .infinity, minHeight: 51)
                            .background(Capsule().fill(Color.brickButton))
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func faq(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color.brickInk)
            Text(body)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color.brickSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.brickCard)
        )
    }
}

struct AboutScreen: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        BrickPushedScreen(title: "About") {
            VStack(spacing: 20) {
                Spacer(minLength: 24)
                
                Text("Open Blocker")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(Color.brickInk)
                
                Text("Version \(version) (\(build))")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.brickSecondaryLabel)
                
                Text("MIT License")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.brickSecondaryLabel)
                
                Text("A physical key starts and stops a block. Free, open, and honest.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.brickMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    UIApplication.shared.open(OpenBlockerLinks.projectPage)
                }) {
                    Text("Project page")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.brickInk)
                        .frame(maxWidth: .infinity, minHeight: 51)
                        .background(Capsule().fill(Color.brickButton))
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
}

struct ContactScreen: View {
    var body: some View {
        BrickPushedScreen(title: "Contact") {
            VStack(spacing: 20) {
                Spacer(minLength: 24)
                
                Text("Bugs, questions, and ideas.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color.brickInk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Text("The project page is the public home for Open Blocker.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.brickSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    UIApplication.shared.open(OpenBlockerLinks.projectPage)
                }) {
                    Text("Open the project page")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.brickInk)
                        .frame(maxWidth: .infinity, minHeight: 51)
                        .background(Capsule().fill(Color.brickButton))
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
}

struct NotificationsScreen: View {
    @State private var enabled = SessionNotify.isEnabled
    @State private var busy = false
    @State private var deniedNote: String?
    
    var body: some View {
        BrickPushedScreen(title: "Notifications") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("When a block ends")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color.brickInk)
                        Text("A local notification when you unlock, use an emergency unblock, or a schedule window ends.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.brickSecondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 12)
                    Toggle("", isOn: Binding(
                        get: { enabled },
                        set: { newValue in
                            busy = true
                            Task {
                                let on = await SessionNotify.setEnabled(newValue)
                                await MainActor.run {
                                    enabled = on
                                    busy = false
                                    if newValue && !on {
                                        deniedNote = "Notifications were not allowed. You can enable them in iPhone Settings."
                                    } else {
                                        deniedNote = nil
                                    }
                                }
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(Color.brickAccent)
                    .disabled(busy)
                    .accessibilityIdentifier(AccessibilityID.notificationsToggle)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.brickCard)
                )
                
                if let deniedNote {
                    Text(deniedNote)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.brickMuted)
                    
                    Button("Open iPhone Settings") {
                        SessionNotify.openSystemSettings()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.brickInk)
                }
                
                Spacer()
            }
            .padding(20)
            .task {
                enabled = SessionNotify.isEnabled
            }
        }
    }
}
