import SwiftUI

struct OnboardingView: View {
    @StateObject private var appState = AppState.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var screenTimeNote: String?
    @State private var requesting = false
    @State private var showingKeySetup = false
    
    private let pageCount = 4
    
    var body: some View {
        ZStack {
            ScreenCanvas()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardingPage(
                        title: "Open Blocker",
                        subtitle: "Lock distracting apps. Only something you can hold unlocks them again."
                    ) {
                        KeyView3D(progress: 0, yaw: 0, isDragging: false, reduceMotion: reduceMotion)
                            .frame(width: 260, height: 260)
                    }
                    .tag(0)
                    
                    OnboardingPage(
                        title: "Screen Time",
                        subtitle: "Apple requires this permission for any app that blocks apps. Open Blocker doesn't read or track your screen time.",
                        note: screenTimeNote
                    ) {
                        medallion("hourglass")
                    }
                    .tag(1)
                    
                    OnboardingPage(
                        title: "Block adult websites?",
                        subtitle: "Uses Apple's adult content filter while you're blocked.",
                        footer: AnyView(
                            SettingsGroup {
                                ToggleRow(
                                    title: "Block adult websites",
                                    isOn: Binding(
                                        get: { appState.rules.blockAdultWeb },
                                        set: { value in
                                            var rules = appState.rules
                                            rules.blockAdultWeb = value
                                            appState.rules = rules
                                        }
                                    ),
                                    accessibilityID: "onboarding-adult-toggle"
                                )
                            }
                            .padding(.horizontal, Space.xl)
                        )
                    ) {
                        medallion("hand.raised.fill")
                    }
                    .tag(2)
                    
                    OnboardingPage(
                        title: "Add your key",
                        subtitle: "Only your key unblocks.",
                        note: appState.keys.isEmpty ? nil : "Key added."
                    ) {
                        medallion("key.fill")
                    }
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                HStack(spacing: Space.xs) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? Color.ink : Color.inkTertiary.opacity(0.5))
                            .frame(width: index == page ? 20 : 8, height: 8)
                    }
                }
                .animation(Motion.standard, value: page)
                .padding(.bottom, Space.xl)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Page \(page + 1) of \(pageCount)")
                
                PrimaryButton(
                    title: buttonTitle,
                    emphasis: .ink,
                    isEnabled: !requesting,
                    accessibilityID: AccessibilityID.onboardingContinue,
                    action: advance
                )
                .padding(.horizontal, Space.xxxl)
                .padding(.bottom, isKeyStep ? Space.s : Space.xxxl)
                
                if isKeyStep {
                    Button("Skip for now") { appState.completeOnboarding() }
                        .textStyle(.subhead, weight: .semibold)
                        .foregroundColor(Color.inkSecondary)
                        .frame(minHeight: 44)
                        .padding(.bottom, Space.l)
                        .accessibilityIdentifier("onboarding-skip-key")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-root")
        .onAppear(perform: applyOnboardingDefaults)
        .sheet(isPresented: $showingKeySetup) {
            KeySetupScreen(onSaved: { appState.completeOnboarding() })
        }
    }
    
    /// Fresh installs start with "Block adult websites" on; the onboarding
    /// step (and My Rules) can turn it off. Applied once.
    private func applyOnboardingDefaults() {
        let key = "onboardingAdultWebDefaultApplied"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        var rules = appState.rules
        rules.blockAdultWeb = true
        appState.rules = rules
    }
    
    /// Last step: add a key (unless one already exists).
    private var isKeyStep: Bool {
        page == pageCount - 1 && appState.keys.isEmpty
    }
    
    private func medallion(_ systemName: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.surfaceRaised)
                .frame(width: 168, height: 168)
                .shadow(color: Color.floatShadow, radius: 30, y: 14)
            Image(systemName: systemName)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(Color.ink)
        }
        .frame(height: 260)
    }
    
    private var buttonTitle: String {
        if requesting { return "Asking..." }
        switch page {
        case 0: return "Continue"
        case 1: return screenTimeNote == nil ? "Allow Screen Time" : "Continue"
        case 2: return "Continue"
        default: return appState.keys.isEmpty ? "Add Key" : "Get Started"
        }
    }
    
    private func advance() {
        if page == 1 && screenTimeNote == nil {
            requesting = true
            Task {
                let ok = await appState.requestAuthorization()
                await MainActor.run {
                    requesting = false
                    if ok {
                        screenTimeNote = "Screen Time is on."
                    } else {
                        #if targetEnvironment(simulator)
                        screenTimeNote = "The simulator can't grant Screen Time. On iPhone, Apple's permission sheet appears here."
                        #else
                        screenTimeNote = "Screen Time wasn't allowed. Open Blocker will ask again before your first block."
                        #endif
                    }
                }
            }
            return
        }
        if page < pageCount - 1 {
            withAnimation(Motion.standard) { page += 1 }
        } else if appState.keys.isEmpty {
            showingKeySetup = true
        } else {
            appState.completeOnboarding()
        }
    }
}

private struct OnboardingPage<Hero: View>: View {
    let title: String
    let subtitle: String
    var note: String? = nil
    var footer: AnyView? = nil
    @ViewBuilder var hero: Hero
    
    var body: some View {
        VStack(spacing: Space.l) {
            Spacer()
            hero
            Text(title)
                .textStyle(.title)
                .foregroundColor(Color.ink)
                .multilineTextAlignment(.center)
                .padding(.top, Space.s)
            Text(subtitle)
                .textStyle(.body)
                .foregroundColor(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Space.xxxl)
            if let note {
                Label(note, systemImage: "info.circle")
                    .textStyle(.subhead)
                    .foregroundColor(Color.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Space.m)
                    .padding(.vertical, Space.s)
                    .background(Capsule(style: .continuous).fill(Color.fillQuiet))
                    .padding(.horizontal, Space.xl)
                    .accessibilityIdentifier(AccessibilityID.onboardingNote)
            }
            if let footer {
                footer.padding(.top, Space.xs)
            }
            Spacer()
        }
    }
}
