// Adapted from research brief BRIEF.md section b.10: Hold-to-block button

import SwiftUI

struct BlockButton: View {
    @Binding var progress: CGFloat
    let isBlocking: Bool
    let onTap: () -> Void
    let onHoldComplete: () -> Void
    
    @State private var pressStart: Date?
    @State private var completed = false
    
    var body: some View {
        gestureContent
    }
    
    private var labelText: String {
        if isBlocking {
            return "Tap to unblock"
        } else if progress > 0 && progress < 1 {
            return "Keep holding"
        } else {
            return "Tap or hold to block"
        }
    }
    
    private var isPressed: Bool {
        pressStart != nil && !completed
    }
    
    @ViewBuilder
    private var gestureContent: some View {
        if isBlocking {
            content
                .onTapGesture {
                    onTap()
                }
        } else {
            content
                .gesture(
                    LongPressGesture(minimumDuration: 2.0, maximumDistance: 40)
                        .onEnded { _ in
                            completed = true
                            onHoldComplete()
                            
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                        .simultaneously(with: DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if pressStart == nil {
                                    pressStart = Date()
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    
                                    withAnimation(.linear(duration: 2.0)) {
                                        progress = 1
                                    }
                                }
                            }
                            .onEnded { _ in
                                if !completed {
                                    let held = Date().timeIntervalSince(pressStart ?? Date())
                                    
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        progress = 0
                                    }
                                    
                                    if held < 0.35 {
                                        onTap()
                                    }
                                }
                                
                                pressStart = nil
                                completed = false
                            }
                        )
                )
                .accessibilityIdentifier(AccessibilityID.blockButton)
                .accessibilityAddTraits(.isButton)
        }
    }
    
    private var content: some View {
        Text(labelText)
            .brickText(size: 15, weight: .medium, relativeTo: .callout)
            .foregroundColor(Color.brickInk)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: 51)
            .background(
                Capsule()
                    .fill(isPressed ? Color.brickButtonPressed : Color.brickButton)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.brickHighlight, .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                ),
                                lineWidth: 1
                            )
                            .mask(
                                VStack {
                                    Capsule().frame(height: 25)
                                    Spacer()
                                }
                            )
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            .padding(.horizontal, 40)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
            .accessibilityIdentifier(AccessibilityID.blockButton)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(labelText)
    }
}
