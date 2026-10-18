// Drives HoldFill with a display link and plays the haptics (HoldHaptics).

import SwiftUI
import UIKit

@MainActor
final class HoldToLockController: ObservableObject {
    @Published private(set) var progress: Double = 0
    @Published private(set) var isHolding = false
    /// Goes up by one each time a hold locks the key; the key flashes on it.
    @Published private(set) var lockBursts = 0
    
    /// Called when the key is full. Return true if a session started.
    var onComplete: (@MainActor () -> Bool)?
    
    var reduceMotion = false {
        didSet { fill.snapsWhenIdle = reduceMotion; run() }
    }
    
    private static let maxFrameStep: CFTimeInterval = 0.25
    private var fill = HoldFill()
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private let haptics = HoldHaptics()
    
    func press() {
        guard fill.press() else { return }
        haptics.prepare()
        haptics.beginBuildUp(at: fill.progress)
        run()
    }
    
    func release() {
        guard fill.isHolding else { return }
        fill.release()
        haptics.stopBuildUp()
        run()
    }
    
    /// Keeps the key full while a session runs, however it started.
    func setLocked(_ locked: Bool, animated: Bool = true) {
        guard fill.isLocked != locked || !animated else {
            return
        }
        fill.setLocked(locked)
        if animated {
            run()
        } else {
            fill.snapToRest()
            publish()
        }
    }
    
    /// Accessibility path: block at once, same completion as a full hold.
    func completeNow() {
        guard fill.press() else { return }
        fill.release()
        handle(.completed)
        run()
    }
    
    private func run() {
        publish()
        guard !fill.isSettled, displayLink == nil else { return }
        let link = CADisplayLink(target: DisplayLinkProxy(self), selector: #selector(DisplayLinkProxy.tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
        lastTimestamp = nil
    }
    
    fileprivate func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        // Track real held time even when frames drop; only cap long stalls
        // (like returning from the background) so the key never jumps.
        let dt = lastTimestamp.map { min(now - $0, Self.maxFrameStep) } ?? 0
        lastTimestamp = now
        for event in fill.step(by: dt) {
            handle(event)
        }
        publish()
        if fill.isSettled {
            link.invalidate()
            displayLink = nil
        }
    }
    
    private func handle(_ event: HoldFill.Event) {
        switch event {
        case .tick(let n):
            haptics.step(n)
        case .completed:
            let started = onComplete?() ?? false
            fill.setLocked(started)
            if started {
                haptics.climax()
                lockBursts += 1
            } else {
                haptics.fail()
            }
        }
    }
    
    private func publish() {
        if progress != fill.progress { progress = fill.progress }
        if isHolding != fill.isHolding { isHolding = fill.isHolding }
    }
}

/// CADisplayLink retains its target; the proxy keeps that from leaking the controller.
private final class DisplayLinkProxy: NSObject {
    weak var owner: HoldToLockController?
    
    init(_ owner: HoldToLockController) {
        self.owner = owner
    }
    
    @objc func tick(_ link: CADisplayLink) {
        guard let owner else {
            link.invalidate()
            return
        }
        MainActor.assumeIsolated {
            owner.tick(link)
        }
    }
}
