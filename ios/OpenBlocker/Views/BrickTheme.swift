import SwiftUI

extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xff) / 255
        let green = Double((hex >> 8) & 0xff) / 255
        let blue = Double((hex >> 0) & 0xff) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
    
    /// Warm Brick greige that follows light and dark.
    static func brick(light: Int, dark: Int, opacity: Double = 1.0) -> Color {
        Color(uiColor: UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? dark : light
            let red = CGFloat((hex >> 16) & 0xff) / 255
            let green = CGFloat((hex >> 8) & 0xff) / 255
            let blue = CGFloat(hex & 0xff) / 255
            return UIColor(red: red, green: green, blue: blue, alpha: opacity)
        })
    }
    
    static let brickCanvas = Color.brick(light: 0xCECAC9, dark: 0x2C2A29)
    static let brickPanel = Color.brick(light: 0xD8D4D3, dark: 0x3A3736)
    static let brickCard = Color.brick(light: 0xE3E0E0, dark: 0x484544)
    static let brickInk = Color.brick(light: 0x282828, dark: 0xF0ECEA)
    static let brickMuted = Color.brick(light: 0x797374, dark: 0xA8A09C)
    /// Secondary labels (chart ticks, settings details) with enough contrast in dark mode.
    static let brickSecondaryLabel = Color.brick(light: 0x5C5756, dark: 0xD4CDC8)
    static let brickButton = Color.brick(light: 0xD9D6D5, dark: 0x5A5553)
    static let brickButtonPressed = Color.brick(light: 0xD2CECD, dark: 0x4A4543)
    static let brickHighlight = Color.brick(light: 0xE9E7E7, dark: 0x6A6563)
    static let brickAccent = Color.brick(light: 0x4D5F50, dark: 0x8FA392)
    static let brickChart = Color.brick(light: 0x464F5B, dark: 0xB8C0C8)
    static let brickTabBar = Color.brick(light: 0xF7F7F7, dark: 0x252322)
    static let brickKey = Color.brick(light: 0xCBC6C3, dark: 0x5C5754)
    static let brickKeyFill = Color.brick(light: 0xBCB7B5, dark: 0x8A837E)
}

private struct BrickFontModifier: ViewModifier {
    let weight: Font.Weight
    @ScaledMetric var size: CGFloat
    
    init(size: CGFloat, weight: Font.Weight, relativeTo style: Font.TextStyle) {
        self.weight = weight
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
    }
    
    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight))
    }
}

enum BrickLayout {
    /// Keeps the last scrolling row fully above the custom tab bar.
    static let tabScrollInset: CGFloat = 40
}

extension View {
    func brickText(
        size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo style: Font.TextStyle = .body
    ) -> some View {
        modifier(BrickFontModifier(size: size, weight: weight, relativeTo: style))
    }
}
