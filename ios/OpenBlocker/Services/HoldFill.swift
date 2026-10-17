// Hold-to-block fill logic. Pure value type so it is unit tested; the
// controller below only adds a display link and haptics.

import Foundation

struct HoldFill: Equatable {
    /// Seconds of holding to go from empty to full. The one place to tune it:
    /// long enough to be a deliberate choice, short enough not to annoy.
    static let fillDuration: TimeInterval = 5.0
    /// Seconds for a full key to drain back to empty.
    static let drainDuration: TimeInterval = 0.6
    /// Seconds for the key to settle to full after a session starts some other way.
    static let settleDuration: TimeInterval = 0.6
    /// Haptic ticks per fill (one every 10 percent, the last one is the success haptic).
    static let tickCount = 10
    
    enum Event: Equatable {
        case tick(Int)
        case completed
    }
    
    private(set) var progress: Double = 0
    private(set) var isHolding = false
    private(set) var isLocked = false
    private(set) var ticksFired = 0
    /// With Reduce Motion, settling and draining jump instead of animating.
    var snapsWhenIdle = false
    
    /// The resting value the fill moves toward when nobody is holding.
    var restingProgress: Double { isLocked ? 1 : 0 }
    
    /// True when nothing is moving, so a display link can stop.
    var isSettled: Bool { !isHolding && progress == restingProgress }
    
    /// Starts a hold. Returns false when a session is already running
    /// (holding never ends a session; that needs the physical key).
    @discardableResult
    mutating func press() -> Bool {
        guard !isLocked else { return false }
        isHolding = true
        return true
    }
    
    mutating func release() {
        isHolding = false
    }
    
    mutating func setLocked(_ locked: Bool) {
        isLocked = locked
        if locked { isHolding = false }
    }
    
    /// Jumps straight to the resting value (first appearance, Reduce Motion).
    mutating func snapToRest() {
        isHolding = false
        progress = restingProgress
        ticksFired = isLocked ? Self.tickCount : 0
    }
    
    mutating func step(by dt: TimeInterval) -> [Event] {
        guard dt > 0 else { return [] }
        if isHolding {
            return fill(by: dt)
        }
        let target = restingProgress
        if snapsWhenIdle {
            progress = target
        } else if progress < target {
            progress = min(target, progress + dt / Self.settleDuration)
        } else if progress > target {
            progress = max(target, progress - dt / Self.drainDuration)
        }
        ticksFired = min(ticksFired, Int(progress * Double(Self.tickCount)))
        return []
    }
    
    private mutating func fill(by dt: TimeInterval) -> [Event] {
        var events: [Event] = []
        progress = min(1, progress + dt / Self.fillDuration)
        let reached = Int(progress * Double(Self.tickCount))
        while ticksFired < min(reached, Self.tickCount - 1) {
            ticksFired += 1
            events.append(.tick(ticksFired))
        }
        if progress >= 1 {
            isHolding = false
            ticksFired = Self.tickCount
            events.append(.completed)
        }
        return events
    }
}

/// Maps the 0...1 hold progress to the shader's fill line. Empty hides the
/// fill completely; full overshoots a little so no sliver stays dry.
enum FillLevel {
    static let hidden: Float = -1
    
    static func shaderLevel(for progress: Double) -> Float {
        guard progress > 0.001 else { return hidden }
        return Float(-0.02 + min(progress, 1) * 1.04)
    }
}
