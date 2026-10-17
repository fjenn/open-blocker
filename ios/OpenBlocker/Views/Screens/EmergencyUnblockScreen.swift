import SwiftUI

struct EmergencyUnblockScreen: View {
    @ObservedObject var appState = AppState.shared
    @State private var confirming = false
    @State private var notice: String?
    
    private var remaining: Int { appState.emergencyStatus.remaining }
    private let maximum = EmergencyAllowance.maxCount
    
    var body: some View {
        PushedScreen(title: "Emergency Unblock") {
            VStack(spacing: Space.m) {
                Spacer()
                
                HStack(spacing: Space.xs) {
                    ForEach(0..<maximum, id: \.self) { index in
                        Capsule(style: .continuous)
                            .fill(index < remaining ? Color.ink : Color.fillQuiet)
                            .frame(width: 28, height: 8)
                    }
                }
                .animation(Motion.standard, value: remaining)
                .accessibilityHidden(true)
                
                Text("\(remaining) left")
                    .textStyle(.timer)
                    .foregroundColor(Color.ink)
                    .numericTransition()
                    .accessibilityIdentifier(AccessibilityID.emergencyCount)
                    .accessibilityLabel("\(remaining) left")
                
                Text("End a block without your key. Honesty, not a lock you cannot break.")
                    .textStyle(.body)
                    .foregroundColor(Color.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Space.xxxl)
                
                VStack(spacing: 2) {
                    Text("You get \(maximum) every \(EmergencyAllowance.periodMonths) months.")
                        .foregroundColor(Color.inkTertiary)
                    Text("Resets on \(resetDate)")
                        .foregroundColor(Color.inkSecondary)
                        .accessibilityIdentifier(AccessibilityID.emergencyReset)
                }
                .textStyle(.subhead)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Space.xxxl)
                
                Spacer()
                
                if confirming {
                    confirmPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    PrimaryButton(
                        title: "Use an emergency unblock",
                        emphasis: .ink,
                        isEnabled: remaining > 0,
                        accessibilityID: AccessibilityID.emergencyUse,
                        action: useTapped
                    )
                    .padding(.horizontal, Space.xxxl)
                }
                
                if let notice {
                    Text(notice)
                        .textStyle(.subhead)
                        .foregroundColor(Color.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Space.xxxl)
                }
                
                Spacer().frame(height: Space.xl)
            }
            .animation(Motion.standard, value: confirming)
        }
    }
    
    private var resetDate: String {
        appState.emergencyStatus.resetDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    private var confirmPanel: some View {
        VStack(spacing: Space.m) {
            Text("Unblock without your key?")
                .textStyle(.headline)
                .foregroundColor(Color.ink)
            Text("You'll have \(max(remaining - 1, 0)) left.")
                .textStyle(.subhead)
                .foregroundColor(Color.inkSecondary)
            HStack(spacing: Space.s) {
                PrimaryButton(title: "Cancel") { confirming = false }
                PrimaryButton(title: "Use", emphasis: .ink, accessibilityID: AccessibilityID.emergencyConfirm) {
                    notice = appState.emergencyUnblock() ? "Unblocked." : "Could not use one right now."
                    confirming = false
                }
            }
        }
        .padding(Space.l)
        .background(CardBackground(raised: true))
        .padding(.horizontal, Space.margin)
    }
    
    private func useTapped() {
        guard remaining > 0 else { return }
        if appState.isBlocking {
            notice = nil
            confirming = true
        } else {
            notice = "You're not blocked right now. This only works during a block."
        }
    }
}
