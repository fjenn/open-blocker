// Emergency Unblock screen

import SwiftUI

struct EmergencyUnblockScreen: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.dismiss) var dismiss
    @State private var step: Step = .ready
    @State private var notice: String?
    
    private enum Step {
        case ready
        case confirm
    }
    
    private var remaining: Int {
        appState.emergencyStatus.remaining
    }
    
    var body: some View {
        ZStack {
            Color.brickCanvas
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer(minLength: 8)
                
                Text("\(remaining) left")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(Color.brickInk)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(AccessibilityID.emergencyCount)
                    .accessibilityLabel("\(remaining) left")
                
                Text("End a block without your key. Honesty, not a lock you cannot break.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.brickSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                
                Text("One returns every 30 days, up to 5.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.brickMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if remaining == 5 {
                    Text("Using one starts the 30-day return.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.brickMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                } else if let nextRefill = appState.emergencyStatus.nextRefillDate {
                    Text("Next one on \(nextRefill, style: .date)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.brickMuted)
                }
                
                if step == .confirm {
                    confirmPanel
                } else {
                    Button(action: handleUseTap) {
                        Text("Use an emergency unblock")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(remaining > 0 ? Color.brickCanvas : Color.brickMuted)
                            .frame(maxWidth: .infinity, minHeight: 51)
                            .background(
                                Capsule()
                                    .fill(remaining > 0 ? Color.brickInk : Color.brickButton)
                            )
                    }
                    .disabled(remaining == 0)
                    .padding(.horizontal, 40)
                    .accessibilityIdentifier(AccessibilityID.emergencyUse)
                }
                
                if let notice {
                    Text(notice)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.brickMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Emergency Unblocks")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.brickInk)
                }
                .accessibilityIdentifier(AccessibilityID.navBack)
                .accessibilityLabel("Back")
            }
        }
    }
    
    private var confirmPanel: some View {
        VStack(spacing: 12) {
            Text("Unblock without your key?")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.brickInk)
            
            Text("You get one back every 30 days.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.brickMuted)
            
            HStack(spacing: 10) {
                Button("Cancel") {
                    step = .ready
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.brickMuted)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    Capsule().fill(Color.brickCard)
                )
                
                Button("Use") {
                    if appState.emergencyUnblock() {
                        notice = nil
                    } else {
                        notice = "Could not use one right now."
                    }
                    step = .ready
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.brickCanvas)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    Capsule().fill(Color.brickInk)
                )
                .accessibilityIdentifier(AccessibilityID.emergencyConfirm)
            }
        }
        .padding(20)
        .padding(.horizontal, 24)
    }
    
    private func handleUseTap() {
        guard remaining > 0 else { return }
        notice = nil
        if appState.isBlocking {
            step = .confirm
        } else {
            notice = "Start a block first, then you can use one of these."
        }
    }
}
