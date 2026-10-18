// Open Blocker design tokens. Every colour, type style, radius, spacing and
// motion value used by the UI lives here. See design-refs/BRIEF.md.

import SwiftUI
import UIKit

// MARK: - Colour

extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: opacity
        )
    }
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha
        )
    }
    
    /// A colour that follows light and dark appearance.
    static func adaptive(light: Int, dark: Int, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkAlpha)
                : UIColor(hex: light, alpha: lightAlpha)
        }
    }
}

/// Semantic palette: warm stone and ink, as light/dark pairs. The app is dark
/// by default; Settings > Appearance picks light, dark or the system look
/// (see `AppAppearance`). Brand blue is only for switches and the mark.
enum Palette {
    static let canvas = UIColor.adaptive(light: 0xE8E5E1, dark: 0x181818)
    static let chrome = UIColor.adaptive(light: 0xDCD8D3, dark: 0x0D0D0D)
    static let sheet = UIColor.adaptive(light: 0xEFEDEA, dark: 0x1E1E1E)
    static let surface = UIColor.adaptive(light: 0xF6F5F2, dark: 0x232323)
    static let surfaceRaised = UIColor.adaptive(light: 0xFFFFFF, dark: 0x2D2D2D)
    static let fill = UIColor.adaptive(light: 0xDFDBD6, dark: 0x2E2E2E)
    static let hairline = UIColor.adaptive(light: 0x1B1B1B, dark: 0xFFFFFF, lightAlpha: 0.07, darkAlpha: 0.08)
    // Dark-mode text is brightened for readability (Finn's feedback).
    static let ink = UIColor.adaptive(light: 0x1B1B1B, dark: 0xFAF8F5)
    static let inkSecondary = UIColor.adaptive(light: 0x76716B, dark: 0xC9C5BF)
    static let inkTertiary = UIColor.adaptive(light: 0xA7A29C, dark: 0x9A968F)
    static let inkInverse = UIColor.adaptive(light: 0xFFFFFF, dark: 0x161616)
    static let accent = UIColor.adaptive(light: 0x4450F2, dark: 0x7480FF)
    static let success = UIColor.adaptive(light: 0x3E6A4C, dark: 0x7FB08E)
    static let danger = UIColor.adaptive(light: 0xB8432F, dark: 0xFF7A63)
    static let shadow = UIColor.adaptive(light: 0x3A3128, dark: 0x000000, lightAlpha: 0.10, darkAlpha: 0.5)
}

/// The 3D key: one warm mid gray in both themes, so it reads on black and on
/// stone alike. Holding fills it with a deeper tone of the same gray; a full
/// key is the locked look.
enum KeyPalette {
    static let body = UIColor(hex: 0x9A9690)
    static let fill = UIColor(hex: 0x7A7671)
    /// Studio light strength, shared so the gray renders the same in both themes.
    static let environmentIntensity: CGFloat = 0.7
}

extension Color {
    static let canvas = Color(uiColor: Palette.canvas)
    static let chrome = Color(uiColor: Palette.chrome)
    static let sheet = Color(uiColor: Palette.sheet)
    static let surface = Color(uiColor: Palette.surface)
    static let surfaceRaised = Color(uiColor: Palette.surfaceRaised)
    static let fillQuiet = Color(uiColor: Palette.fill)
    static let hairline = Color(uiColor: Palette.hairline)
    static let ink = Color(uiColor: Palette.ink)
    static let inkSecondary = Color(uiColor: Palette.inkSecondary)
    static let inkTertiary = Color(uiColor: Palette.inkTertiary)
    static let inkInverse = Color(uiColor: Palette.inkInverse)
    static let accent = Color(uiColor: Palette.accent)
    static let success = Color(uiColor: Palette.success)
    static let danger = Color(uiColor: Palette.danger)
    static let floatShadow = Color(uiColor: Palette.shadow)
    static let keyBody = Color(uiColor: KeyPalette.body)
}

// MARK: - Type

enum TextStyle {
    case timer
    case largeTitle
    case title
    case headline
    case body
    case button
    case subhead
    case footnote
    case caption
    
    fileprivate var spec: (size: CGFloat, weight: Font.Weight, tracking: CGFloat, relativeTo: Font.TextStyle) {
        switch self {
        case .timer: return (44, .semibold, -1.0, .largeTitle)
        case .largeTitle: return (40, .semibold, -1.0, .largeTitle)
        case .title: return (24, .semibold, -0.4, .title2)
        case .headline: return (16, .semibold, -0.1, .headline)
        case .body: return (15, .regular, 0, .body)
        case .button: return (15, .semibold, 0, .body)
        case .subhead: return (13, .regular, 0, .subheadline)
        case .footnote: return (12, .medium, 0, .footnote)
        case .caption: return (11, .semibold, 0.6, .caption)
        }
    }
}

private struct TextStyleModifier: ViewModifier {
    let style: TextStyle
    let weight: Font.Weight?
    @ScaledMetric private var size: CGFloat
    
    init(style: TextStyle, weight: Font.Weight?) {
        self.style = style
        self.weight = weight
        _size = ScaledMetric(wrappedValue: style.spec.size, relativeTo: style.spec.relativeTo)
    }
    
    func body(content: Content) -> some View {
        let spec = style.spec
        let font = Font.system(size: size, weight: weight ?? spec.weight, design: .rounded)
        return content
            .font(style == .timer ? font.monospacedDigit() : font)
            .tracking(spec.tracking)
            .textCase(style == .caption ? .uppercase : nil)
    }
}

extension View {
    /// Applies one of the design-system text styles (scales with Dynamic Type).
    func textStyle(_ style: TextStyle, weight: Font.Weight? = nil) -> some View {
        modifier(TextStyleModifier(style: style, weight: weight))
    }
}

// MARK: - Metrics

enum Radius {
    /// The rounded bottom of the main content card above the tab labels.
    static let screen: CGFloat = 44
    static let card: CGFloat = 24
    static let group: CGFloat = 24
    static let input: CGFloat = 18
    static let chip: CGFloat = 12
    static let tile: CGFloat = 10
}

enum Space {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
    /// Side margin for screen content.
    static let margin: CGFloat = 20
    /// Bottom inset so scrolling content clears the card's rounded corners.
    static let tabBarClearance: CGFloat = 28
}

enum Metrics {
    static let buttonHeight: CGFloat = 56
    static let compactButtonHeight: CGFloat = 44
    static let iconTile: CGFloat = 32
    static let headerButton: CGFloat = 40
    static let tabBarHeight: CGFloat = 58
}

// MARK: - Motion

enum Motion {
    static let standard = Animation.spring(response: 0.45, dampingFraction: 1.0)
    static let quick = Animation.easeOut(duration: 0.25)
    static let pop = Animation.spring(response: 0.35, dampingFraction: 0.55)
    static let fade = Animation.easeInOut(duration: 0.2)
    
    /// Standard animation, or none when Reduce Motion is on.
    static func standard(reduced: Bool) -> Animation? {
        reduced ? nil : standard
    }
}

extension View {
    /// Rolls digits on iOS 17+, plain change before.
    @ViewBuilder
    func numericTransition() -> some View {
        if #available(iOS 17.0, *) {
            contentTransition(.numericText())
        } else {
            self
        }
    }
}

// MARK: - Appearance

/// The app's colour scheme, chosen in Settings and stored in user defaults.
/// The default, Auto, is dark while you're blocked and light when you're not.
enum AppAppearance: String, CaseIterable, Identifiable {
    case auto
    case light
    case dark
    case system
    
    static let storageKey = "appearance"
    static let standard: AppAppearance = .auto
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .auto: return "Auto"
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    /// Nil follows the system setting. Auto follows the blocking state.
    func colorScheme(isBlocking: Bool) -> ColorScheme? {
        self == .auto ? (isBlocking ? .dark : .light) : colorScheme
    }
    
    func interfaceStyle(isBlocking: Bool) -> UIUserInterfaceStyle {
        self == .auto ? (isBlocking ? .dark : .light) : interfaceStyle
    }
    
    /// Nil follows the system setting (Auto counts as not blocked here).
    var colorScheme: ColorScheme? {
        switch self {
        case .auto: return .light
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .auto: return .light
        case .light: return .light
        case .dark: return .dark
        case .system: return .unspecified
        }
    }
}

/// Applies the stored appearance to SwiftUI and to the app's windows, so
/// sheets, system pickers and the SceneKit key all follow it.
private struct AppAppearanceModifier: ViewModifier {
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.standard
    @ObservedObject private var appState = AppState.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(appearance.colorScheme(isBlocking: appState.isBlocking))
            .animation(.easeInOut(duration: 0.3), value: appState.isBlocking)
            .onAppear { applyToWindows() }
            .onChange(of: appearance) { _ in applyToWindows() }
            .onChange(of: appState.isBlocking) { _ in applyToWindows() }
    }
    
    private func applyToWindows() {
        let style = appearance.interfaceStyle(isBlocking: appState.isBlocking)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { $0.overrideUserInterfaceStyle = style }
    }
}

extension View {
    /// Applies the app-wide colour scheme. Use once, at the root view.
    func appAppearance() -> some View {
        modifier(AppAppearanceModifier())
    }
}
