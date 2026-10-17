import SwiftUI

struct HelpScreen: View {
    private let faqs: [(String, String)] = [
        ("How keys work", "A physical key (an NFC tag, a card, or a printed QR) unblocks your phone. You can start a block by holding the key on screen, or by scanning your key. Honesty, not a lock you cannot break."),
        ("Emergency unblocks", "If your key is out of reach, an emergency unblock ends the session. You get five every six months. The Emergency Unblock page shows when they reset."),
        ("Why some cards fail", KeyRegistration.rotatingCardMessage),
        ("Does it track my screen time?", "No. Apple requires Screen Time permission for any app that blocks apps. Open Blocker can't see your usage. Time blocked only counts your own blocks."),
        ("Screen Time passcode", "Apple's shields are stronger if someone you trust sets a Screen Time passcode.")
    ]
    
    var body: some View {
        PushedScreen(title: "Help") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s) {
                    ForEach(faqs, id: \.0) { faq in
                        VStack(alignment: .leading, spacing: Space.xs) {
                            Text(faq.0)
                                .textStyle(.headline)
                                .foregroundColor(Color.ink)
                            Text(faq.1)
                                .textStyle(.body)
                                .foregroundColor(Color.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Space.l)
                        .background(CardBackground())
                    }
                    
                    PrimaryButton(title: "How to set a Screen Time passcode") {
                        UIApplication.shared.open(OpenBlockerLinks.screenTimePasscode)
                    }
                    .padding(.top, Space.s)
                }
                .padding(.horizontal, Space.margin)
                .padding(.bottom, Space.xxxl)
            }
        }
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
        PushedScreen(title: "About") {
            VStack(spacing: Space.m) {
                Spacer(minLength: Space.xl)
                BrandMark(size: 96)
                    .shadow(color: Color.accent.opacity(0.3), radius: 24, y: 12)
                Text("Open Blocker")
                    .textStyle(.largeTitle)
                    .foregroundColor(Color.ink)
                    .padding(.top, Space.xs)
                Text("Version \(version) (\(build))")
                    .textStyle(.subhead)
                    .foregroundColor(Color.inkSecondary)
                Text("MIT License")
                    .textStyle(.subhead)
                    .foregroundColor(Color.inkSecondary)
                Text("A physical key unblocks your phone. Free, open, and honest.")
                    .textStyle(.body)
                    .foregroundColor(Color.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Space.xxxl)
                    .padding(.top, Space.xs)
                Spacer()
                PrimaryButton(title: "Project page") {
                    UIApplication.shared.open(OpenBlockerLinks.projectPage)
                }
                .padding(.horizontal, Space.xxxl)
                PrimaryButton(title: "See the code", accessibilityID: "about-see-code", leadingImage: "mark-github") {
                    UIApplication.shared.open(OpenBlockerLinks.sourceCode)
                }
                .padding(.horizontal, Space.xxxl)
                .padding(.bottom, Space.xxxl)
            }
        }
    }
}

struct ContactScreen: View {
    var body: some View {
        PushedScreen(title: "Contact") {
            VStack(spacing: Space.m) {
                Spacer()
                ZStack {
                    Circle().fill(Color.fillQuiet).frame(width: 88, height: 88)
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color.inkSecondary)
                }
                Text("Bugs, questions, and ideas.")
                    .textStyle(.title)
                    .foregroundColor(Color.ink)
                    .multilineTextAlignment(.center)
                Text("Tell us on the feedback page.")
                    .textStyle(.body)
                    .foregroundColor(Color.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Space.xxxl)
                Spacer()
                PrimaryButton(title: "Send feedback") {
                    UIApplication.shared.open(OpenBlockerLinks.feedback)
                }
                .padding(.horizontal, Space.xxxl)
                .padding(.bottom, Space.xxxl)
            }
        }
    }
}

/// What leaves the phone (one anonymous event per finished block) and why each permission is asked for.
struct PrivacyScreen: View {
    private let permissions: [(icon: String, title: String, reason: String)] = [
        ("hourglass", "Screen Time", "Apple requires this so we can block apps. We don't read or track your usage. Time blocked is our own count."),
        ("wave.3.right", "NFC", "Reads your key tag or card, and sets up new tags."),
        ("camera", "Camera", "Scans your QR or barcode key. Nothing is recorded."),
        ("bell", "Notifications", "Tells you when a block ends, if you turn it on.")
    ]
    
    var body: some View {
        PushedScreen(title: "Privacy") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s) {
                    card(
                        title: "Stays on your iPhone",
                        text: "Your modes, keys, schedules and history stay on your phone. Open Blocker has no accounts and no ads."
                    )
                    card(title: "Anonymous count", text: CountManager.disclosure + " Turn it off in Settings any time.")
                    
                    Text("Permissions")
                        .textStyle(.subhead, weight: .semibold)
                        .foregroundColor(Color.inkSecondary)
                        .padding(.horizontal, Space.xxs)
                        .padding(.top, Space.s)
                    SettingsGroup {
                        ForEach(permissions.indices, id: \.self) { index in
                            if index > 0 { HairlineDivider() }
                            let item = permissions[index]
                            SettingsRow(icon: item.icon, title: item.title, subtitle: item.reason, showsChevron: false)
                        }
                    }
                    
                    PrimaryButton(title: "Full privacy policy") {
                        UIApplication.shared.open(OpenBlockerLinks.privacy)
                    }
                    .padding(.top, Space.s)
                }
                .padding(.horizontal, Space.margin)
                .padding(.top, Space.xs)
                .padding(.bottom, Space.xxl)
            }
        }
    }
    
    private func card(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(title)
                .textStyle(.headline)
                .foregroundColor(Color.ink)
            Text(text)
                .textStyle(.body)
                .foregroundColor(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.l)
        .background(CardBackground())
    }
}

struct NotificationsScreen: View {
    @State private var enabled = SessionNotify.isEnabled
    @State private var deniedPermission: Permission?
    
    var body: some View {
        PushedScreen(title: "Notifications") {
            VStack(alignment: .leading, spacing: Space.m) {
                SettingsGroup {
                    ToggleRow(
                        title: "When a block ends",
                        subtitle: "A quiet notification when you unblock, use an emergency unblock, or a schedule ends.",
                        isOn: Binding(get: { enabled }, set: setEnabled),
                        accessibilityID: AccessibilityID.notificationsToggle
                    )
                }
                Spacer()
            }
            .padding(.horizontal, Space.margin)
            .padding(.top, Space.xs)
            .task { enabled = SessionNotify.isEnabled }
        }
        .permissionSheet($deniedPermission)
    }
    
    private func setEnabled(_ newValue: Bool) {
        guard newValue else {
            SessionNotify.setEnabled(false)
            enabled = false
            return
        }
        Permissions.whenGranted(.notifications, denied: $deniedPermission) {
            SessionNotify.setEnabled(true)
            enabled = true
        }
    }
}
