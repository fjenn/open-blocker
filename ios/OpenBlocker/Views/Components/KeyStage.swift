// The interactive key: tap to scan, press and hold to fill and block,
// drag sideways to spin it. A small finger drift stays a hold; leaving
// the key or capsule (plus slack) cancels. The button shares this gesture.

import SwiftUI

/// One touch handler for "tap to scan, hold to fill". Optional drag spins the key.
struct HoldTapGesture: ViewModifier {
    @ObservedObject var hold: HoldToLockController
    let isLocked: Bool
    let onTap: () -> Void
    var onHoldWhileLocked: () -> Void = {}
    var onDrag: ((CGFloat) -> Void)? = nil
    var onDragEnd: ((CGFloat) -> Void)? = nil
    
    @State private var pressBegan: Date?
    @State private var beganLocked = false
    @State private var leftArea = false
    @State private var bounds: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: HoldBoundsKey.self, value: geo.size)
                }
            )
            .onPreferenceChange(HoldBoundsKey.self) { bounds = $0 }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged(changed)
                    .onEnded(ended)
            )
    }
    
    private func changed(_ value: DragGesture.Value) {
        if pressBegan == nil {
            pressBegan = Date()
            beganLocked = isLocked
            leftArea = false
            if !isLocked { hold.press() }
        }
        if !leftArea && !HoldPressTracking.isInsideHoldArea(location: value.location, bounds: bounds) {
            leftArea = true
            hold.release()
        }
        let moved = HoldPressTracking.movement(value.translation)
        if onDrag != nil && moved > HoldPressTracking.tapMoveLimit {
            onDrag?(value.translation.width)
        }
    }
    
    private func ended(_ value: DragGesture.Value) {
        defer {
            pressBegan = nil
            leftArea = false
        }
        let moved = HoldPressTracking.movement(value.translation)
        let held = Date().timeIntervalSince(pressBegan ?? Date())
        if leftArea {
            onDragEnd?(value.predictedEndTranslation.width)
            return
        }
        hold.release()
        if HoldPressTracking.isShortTap(held: held, moved: moved) {
            onTap()
        } else if held < HoldPressTracking.tapLimit {
            onDragEnd?(value.predictedEndTranslation.width)
        } else if beganLocked {
            onHoldWhileLocked()
        }
    }
}

private struct HoldBoundsKey: PreferenceKey {
    static var defaultValue = CGSize.zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    func holdToBlock(
        _ hold: HoldToLockController,
        isLocked: Bool,
        onTap: @escaping () -> Void,
        onHoldWhileLocked: @escaping () -> Void = {},
        onDrag: ((CGFloat) -> Void)? = nil,
        onDragEnd: ((CGFloat) -> Void)? = nil
    ) -> some View {
        modifier(HoldTapGesture(
            hold: hold,
            isLocked: isLocked,
            onTap: onTap,
            onHoldWhileLocked: onHoldWhileLocked,
            onDrag: onDrag,
            onDragEnd: onDragEnd
        ))
    }
}

struct KeyStage: View {
    @ObservedObject var hold: HoldToLockController
    let isLocked: Bool
    let isEnabled: Bool
    let onTap: () -> Void
    let onHoldWhileLocked: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var yaw: Float = 0
    @State private var dragBase: Float?
    @State private var popScale: CGFloat = 1
    
    private static let yawPerPoint: Float = 0.012
    private static let pressedScale: CGFloat = 0.92
    
    var body: some View {
        KeyView3D(
            progress: hold.progress,
            yaw: yaw,
            isDragging: dragBase != nil,
            reduceMotion: reduceMotion
        )
        // Pressing sinks the key a little, like pushing a real button.
        .scaleEffect(hold.isHolding && !reduceMotion ? Self.pressedScale : 1)
        .scaleEffect(popScale)
        .background(LockBurst(trigger: hold.lockBursts, reduceMotion: reduceMotion))
        .animation(reduceMotion ? nil : Motion.standard, value: hold.isHolding)
        .opacity(isEnabled ? 1 : 0.7)
        .contentShape(Circle().scale(0.82))
        .holdToBlock(
            hold,
            isLocked: isLocked || !isEnabled,
            onTap: onTap,
            onHoldWhileLocked: onHoldWhileLocked,
            onDrag: { dx in
                let base = dragBase ?? yaw
                dragBase = base
                yaw = base + Float(dx) * Self.yawPerPoint
            },
            onDragEnd: { predicted in
                let base = dragBase ?? yaw
                dragBase = nil
                yaw = base + Float(predicted) * Self.yawPerPoint
            }
        )
        .onChange(of: isLocked) { locked in
            guard locked, !reduceMotion else { return }
            popScale = 1.05
            withAnimation(Motion.pop) { popScale = 1 }
        }
        .accessibilityElement()
        .accessibilityIdentifier(AccessibilityID.keyStage)
        .accessibilityLabel("Your key")
        .accessibilityValue(isLocked ? "Blocked" : "\(Int((hold.progress * 100).rounded())) percent")
        .accessibilityHint(isLocked ? "Double tap, then scan your key to unblock." : "Hold to block. Double tap to scan your key.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
        .accessibilityAction(named: "Block now") {
            if isEnabled && !isLocked { hold.completeNow() }
        }
    }
}

/// The flash when a hold locks the key: a soft glow and a thin ring burst
/// out from behind it and fade, in step with the haptic climax.
private struct LockBurst: View {
    let trigger: Int
    let reduceMotion: Bool
    
    /// 0 at the moment of the lock, 1 when the burst has faded.
    @State private var phase: CGFloat = 1
    
    private static let duration: TimeInterval = 0.7
    
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let grow = reduceMotion ? 0 : phase
            ZStack {
                // A halo that hugs the rim; the key covers its centre.
                Circle()
                    .fill(RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.keyBody.opacity(0.55), location: 0.55),
                            .init(color: Color.keyBody.opacity(0), location: 1)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: side * 0.5
                    ))
                    .scaleEffect(0.8 + 0.4 * grow)
                Circle()
                    .stroke(Color.keyBody.opacity(0.8), lineWidth: 1.5)
                    .scaleEffect(0.62 + 0.5 * grow)
            }
            .frame(width: side, height: side)
            .frame(width: geo.size.width, height: geo.size.height)
            .opacity(Double(1 - phase))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _ in
            phase = 0
            // Next runloop, so the reset lands before the fade animates.
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: Self.duration)) { phase = 1 }
            }
        }
    }
}
