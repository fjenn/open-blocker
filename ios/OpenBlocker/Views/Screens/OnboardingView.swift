import SwiftUI

struct OnboardingView: View {
    @StateObject private var appState = AppState.shared
    @State private var page = 0
    @State private var screenTimeNote: String?
    @State private var requesting = false
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                OnboardingPage(
                    title: "Open Blocker",
                    subtitle: "A physical key starts and stops a block. Honesty, not a lock you cannot break.",
                    systemImage: "lock.shield"
                )
                .tag(0)
                
                OnboardingPage(
                    title: "Screen Time",
                    subtitle: "Apple's Screen Time permission is what actually hides apps while you are blocked.",
                    systemImage: "hourglass",
                    note: screenTimeNote
                )
                .tag(1)
                
                OnboardingPage(
                    title: "Your key",
                    subtitle: "Add an NFC tag, a card, or a printed QR on the next screen. You will tap it to block and unblock.",
                    systemImage: "key.fill"
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color.brickInk : Color.brickMuted)
                        .frame(width: index == page ? 18 : 8, height: 8)
                }
            }
            .padding(.bottom, 20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(page + 1) of 3")
            
            Button(action: advance) {
                Text(buttonTitle)
                    .brickText(size: 17, weight: .medium, relativeTo: .body)
                    .foregroundColor(Color.brickInk)
                    .frame(maxWidth: .infinity, minHeight: 51)
                    .background(
                        Capsule()
                            .fill(Color.brickButton)
                    )
                    .shadow(color: .black.opacity(requesting ? 0 : 0.12), radius: 8, y: 4)
            }
            .disabled(requesting)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .accessibilityIdentifier(AccessibilityID.onboardingContinue)
        }
        .background(Color.brickCanvas.ignoresSafeArea())
    }
    
    private var buttonTitle: String {
        if requesting { return "Asking..." }
        switch page {
        case 0:
            return "Continue"
        case 1:
            return screenTimeNote == nil ? "Allow Screen Time" : "Continue"
        default:
            return "Get Started"
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
                        screenTimeNote = "Screen Time is on. Blocking can use Apple's shields."
                    } else {
                        #if targetEnvironment(simulator)
                        screenTimeNote = "The simulator cannot grant Screen Time. On your iPhone, Apple's permission sheet will appear here."
                        #else
                        screenTimeNote = "Screen Time was not granted. You can try again later from iPhone Settings."
                        #endif
                    }
                }
            }
            return
        }
        if page < 2 {
            withAnimation { page += 1 }
        } else {
            appState.completeOnboarding()
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var note: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: systemImage)
                .font(.system(size: 64, weight: .regular))
                .foregroundColor(Color.brickInk)
            
            Text(title)
                .brickText(size: 28, weight: .medium, relativeTo: .title)
                .foregroundColor(Color.brickInk)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .brickText(size: 16, relativeTo: .body)
                .foregroundColor(Color.brickMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            
            if let note {
                Text(note)
                    .brickText(size: 15, relativeTo: .callout)
                    .foregroundColor(Color.brickInk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 4)
                    .accessibilityIdentifier(AccessibilityID.onboardingNote)
            }
            
            Spacer()
        }
    }
}
