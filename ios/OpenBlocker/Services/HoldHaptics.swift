// Haptics for hold-to-block: a build-up that rises with the fill, then a
// climax when the key locks. Core Haptics where the phone has it; simple
// impact taps everywhere else.

import CoreHaptics
import UIKit

/// The shape of the build-up, as pure numbers so it is unit tested. Progress
/// runs 0...1 over `HoldFill.fillDuration`; everything rises with it.
enum HoldHapticCurve {
    /// Overall strength of the hum and taps: soft at first, strong at the end.
    static func intensity(at progress: Double) -> Double {
        0.2 + 0.8 * ease(progress)
    }
    
    /// Added crispness (-1...1): dull at first, sharper near the end.
    static func sharpness(at progress: Double) -> Double {
        -0.25 + 0.6 * ease(progress)
    }
    
    /// Seconds to the next tap: sparse at first, a fast patter at the end.
    static func tapInterval(at progress: Double) -> Double {
        0.42 - 0.35 * ease(progress)
    }
    
    /// Progress values (0...1) of every tap in a full hold.
    static let tapProgress: [Double] = {
        var taps: [Double] = []
        var time = 0.12
        let duration = HoldFill.fillDuration
        while time < duration {
            taps.append(time / duration)
            time += tapInterval(at: time / duration)
        }
        return taps
    }()
    
    /// Slow start, steady climb.
    private static func ease(_ progress: Double) -> Double {
        let p = min(max(progress, 0), 1)
        return p * p * (1.6 - 0.6 * p)
    }
}

/// The one place that plays hold-to-block haptics.
final class HoldHaptics {
    private var engine: CHHapticEngine?
    private var buildUp: CHHapticAdvancedPatternPlayer?
    private let tapFallback = UIImpactFeedbackGenerator(style: .rigid)
    private let lockFallback = UIImpactFeedbackGenerator(style: .heavy)
    private let failFallback = UINotificationFeedbackGenerator()
    
    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = try? CHHapticEngine() else { return }
        engine.playsHapticsOnly = true
        engine.isAutoShutdownEnabled = true
        engine.resetHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.buildUp = nil
                try? self?.engine?.start()
            }
        }
        engine.stoppedHandler = { [weak self] _ in
            DispatchQueue.main.async { self?.buildUp = nil }
        }
        self.engine = engine
    }
    
    /// Warms up the engine so the first pulse is instant.
    func prepare() {
        if let engine {
            engine.start(completionHandler: nil)
        } else {
            tapFallback.prepare()
            lockFallback.prepare()
        }
    }
    
    /// Starts the build-up from `progress`, so a hold that resumes a partly
    /// filled key picks up where it left off.
    func beginBuildUp(at progress: Double) {
        stopBuildUp()
        guard let engine else {
            tapFallback.impactOccurred(intensity: CGFloat(HoldHapticCurve.intensity(at: progress)))
            return
        }
        do {
            try engine.start()
            let player = try engine.makeAdvancedPlayer(with: Self.buildUpPattern(from: progress))
            try player.start(atTime: CHHapticTimeImmediate)
            buildUp = player
        } catch {
            buildUp = nil
        }
    }
    
    /// A fill step on phones without Core Haptics (the pattern covers it otherwise).
    func step(_ tick: Int) {
        guard engine == nil else { return }
        let progress = Double(tick) / Double(HoldFill.tickCount)
        tapFallback.impactOccurred(intensity: CGFloat(HoldHapticCurve.intensity(at: progress)))
    }
    
    /// Ends the build-up at once (released early, or the key is full).
    func stopBuildUp() {
        try? buildUp?.stop(atTime: CHHapticTimeImmediate)
        buildUp = nil
    }
    
    /// The lock: a sharp burst and a heavy rumble that fades out.
    func climax() {
        stopBuildUp()
        if let engine, let pattern = Self.climaxPattern, Self.play(pattern, on: engine) { return }
        lockFallback.impactOccurred(intensity: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) { [lockFallback] in
            lockFallback.impactOccurred(intensity: 0.6)
        }
    }
    
    /// The key filled but no session started.
    func fail() {
        stopBuildUp()
        failFallback.notificationOccurred(.warning)
    }
    
    // MARK: Patterns
    
    private static func play(_ pattern: CHHapticPattern, on engine: CHHapticEngine) -> Bool {
        do {
            try engine.start()
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
            return true
        } catch {
            return false
        }
    }
    
    /// A hum and accelerating taps for the rest of the hold, with intensity
    /// and sharpness rising along `HoldHapticCurve`.
    private static func buildUpPattern(from start: Double) throws -> CHHapticPattern {
        let duration = HoldFill.fillDuration
        let startTime = min(max(start, 0), 1) * duration
        let remaining = max(duration - startTime, 0.05)
        let time = { (progress: Double) in progress * duration - startTime }
        
        var events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0,
                duration: remaining
            )
        ]
        for progress in HoldHapticCurve.tapProgress where time(progress) >= 0 {
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.6 + 0.4 * progress)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(0.4 + 0.5 * progress))
                ],
                relativeTime: time(progress)
            ))
        }
        
        // Curves allow 16 points; 12 samples keep the rise smooth.
        let samples = (0...11).map { startTime / duration + (1 - startTime / duration) * Double($0) / 11 }
        let curves = [
            CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: samples.map { point(time($0), HoldHapticCurve.intensity(at: $0)) },
                relativeTime: 0
            ),
            CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl,
                controlPoints: samples.map { point(time($0), HoldHapticCurve.sharpness(at: $0)) },
                relativeTime: 0
            )
        ]
        return try CHHapticPattern(events: events, parameterCurves: curves)
    }
    
    private static func point(_ time: TimeInterval, _ value: Double) -> CHHapticParameterCurve.ControlPoint {
        CHHapticParameterCurve.ControlPoint(relativeTime: time, value: Float(value))
    }
    
    /// Three hard hits on top of each other, then a deep rumble decaying over half a second.
    private static let climaxPattern: CHHapticPattern? = {
        func hit(_ intensity: Float, _ sharpness: Float, at time: TimeInterval) -> CHHapticEvent {
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: time
            )
        }
        let rumble = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.12)
            ],
            relativeTime: 0.02,
            duration: 0.55
        )
        let decay = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [point(0, 1), point(0.08, 0.85), point(0.22, 0.45), point(0.4, 0.15), point(0.57, 0)],
            relativeTime: 0
        )
        let events = [hit(1, 1, at: 0), hit(1, 0.55, at: 0.012), hit(0.85, 0.9, at: 0.045), rumble]
        return try? CHHapticPattern(events: events, parameterCurves: [decay])
    }()
}
