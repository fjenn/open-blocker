import CoreGraphics
import Foundation

/// Shared hold-to-block press rules for the 3D key and the home capsule.
/// Movement inside the pressed view (plus slack) must not reset the fill.
enum HoldPressTracking {
    /// Extra space around the view so a finger can drift without cancelling.
    static let exitTolerance: CGFloat = 36
    /// Short presses that travel farther than this are a spin, not a tap.
    static let tapMoveLimit: CGFloat = 16
    static let tapLimit: TimeInterval = 0.25
    
    static func isInsideHoldArea(
        location: CGPoint,
        bounds: CGSize,
        tolerance: CGFloat = exitTolerance
    ) -> Bool {
        guard bounds.width > 0, bounds.height > 0 else { return true }
        let area = CGRect(origin: .zero, size: bounds).insetBy(dx: -tolerance, dy: -tolerance)
        return area.contains(location)
    }
    
    static func movement(_ translation: CGSize) -> CGFloat {
        hypot(translation.width, translation.height)
    }
    
    static func isShortTap(held: TimeInterval, moved: CGFloat) -> Bool {
        held < tapLimit && moved < tapMoveLimit
    }
}
