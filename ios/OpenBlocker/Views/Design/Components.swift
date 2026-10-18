// Shared UI primitives. Keep screens DRY: cards, buttons, headers, empty states.

import SwiftUI

// MARK: - Screen chrome

/// Full-screen canvas colour behind a screen's content.
struct ScreenCanvas: View {
    var body: some View {
        Color.canvas.ignoresSafeArea()
    }
}

/// A soft, theme-colored edge behind the status bar, like iOS's own scroll
/// edge: content scrolling up fades out before it reaches the clock or the
/// Dynamic Island. Invisible at rest, when nothing is under it.
struct StatusBarScrim: View {
    var color: Color = .canvas
    private let fade: CGFloat = 14
    
    var body: some View {
        VStack(spacing: 0) {
            // Zero height at the top of the safe area; its background grows
            // up to fill the status bar.
            Color.clear
                .frame(height: 0)
                .background(color.ignoresSafeArea(edges: .top))
            LinearGradient(colors: [color, color.opacity(0)], startPoint: .top, endPoint: .bottom)
                .frame(height: fade)
            Spacer(minLength: 0)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The main content card: square top (under the status bar), deep rounded
/// bottom corners that sit above the tab labels. The path runs far above its
/// frame so content that ignores the top safe area is not clipped.
struct ScreenCardShape: Shape {
    var radius: CGFloat = Radius.screen
    
    func path(in rect: CGRect) -> Path {
        let tall = CGRect(x: rect.minX, y: rect.minY - 2000, width: rect.width, height: rect.height + 2000)
        let bezier = UIBezierPath(
            roundedRect: tall,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(bezier.cgPath)
    }
}

/// Text-only tab labels; the selected one is bold with a dot under it.
struct TextTabBar: View {
    @Binding var selectedTab: AppTab
    /// Tapping the tab that's already selected (pop to its root).
    var onReselect: ((AppTab) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                Button {
                    guard !isSelected else { onReselect?(tab); return }
                    UISelectionFeedbackGenerator().selectionChanged()
                    selectedTab = tab
                } label: {
                    VStack(spacing: 5) {
                        Text(tab.rawValue)
                            .textStyle(.subhead, weight: isSelected ? .semibold : .medium)
                            .foregroundColor(isSelected ? Color.ink : Color.inkSecondary)
                        Circle()
                            .fill(Color.ink)
                            .frame(width: 4, height: 4)
                            .opacity(isSelected ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: Metrics.tabBarHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(tab.accessibilityID)
                .accessibilityLabel(tab.rawValue)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, Space.xs)
        .animation(Motion.quick, value: selectedTab)
    }
}

/// Round 40 pt back button used on pushed screens.
struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        RoundIconButton(
            systemName: "chevron.left",
            accessibilityLabel: "Back",
            accessibilityID: AccessibilityID.navBack,
            action: action
        )
    }
}

/// Shared shell for pushed Settings / detail screens.
struct PushedScreen<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            ScreenCanvas()
            VStack(spacing: 0) {
                ZStack {
                    Text(title)
                        .textStyle(.headline, weight: .medium)
                        .foregroundColor(Color.ink)
                        .accessibilityAddTraits(.isHeader)
                    HStack {
                        BackButton { dismiss() }
                        Spacer()
                    }
                }
                .padding(.horizontal, Space.margin)
                .padding(.top, Space.xs)
                .padding(.bottom, Space.s)
                
                content
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Surfaces

/// Cards separate by tone and a soft shadow, never by borders.
struct CardBackground: View {
    var raised: Bool = false
    var radius: CGFloat = Radius.card
    
    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(raised ? Color.surfaceRaised : Color.surface)
            .shadow(color: Color.floatShadow.opacity(raised ? 0.9 : 0.45), radius: raised ? 14 : 8, y: raised ? 6 : 2)
    }
}

struct GroupBackground: View {
    var body: some View {
        CardBackground(radius: Radius.group)
    }
}

struct IconTile: View {
    let systemName: String
    var tint: Color = .ink
    var size: CGFloat = Metrics.iconTile
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundColor(tint)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .fill(Color.fillQuiet)
            )
    }
}

// MARK: - Buttons

enum ButtonEmphasis {
    case quiet   // raised pill with a thin outline
    case ink     // solid ink: the confirm action of a sheet
}

/// The look of every capsule button. `progress` paints the hold fill.
struct CapsuleFace: View {
    let title: String
    var emphasis: ButtonEmphasis = .quiet
    var progress: Double = 0
    /// Optional small template image from the asset catalog, before the title.
    var leadingImage: String? = nil
    
    var body: some View {
        let shape = Capsule(style: .continuous)
        HStack(spacing: Space.xs) {
            if let leadingImage {
                Image(leadingImage)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }
            Text(title)
        }
            .textStyle(.button)
            .foregroundColor(emphasis == .quiet ? Color.ink : Color.inkInverse)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, Space.l)
            .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
            .background {
                ZStack(alignment: .leading) {
                    shape.fill(fillColor)
                    if progress > 0 {
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color.ink.opacity(0.08))
                                .frame(width: geo.size.width * min(progress, 1))
                        }
                        .clipShape(shape)
                    }
                    if emphasis == .quiet {
                        shape.stroke(Color.hairline, lineWidth: 0.5)
                    }
                }
            }
            .shadow(color: Color.floatShadow.opacity(emphasis == .quiet ? 1 : 0.5), radius: 14, y: 6)
    }
    
    private var fillColor: Color {
        switch emphasis {
        case .quiet: return .surfaceRaised
        case .ink: return .ink
        }
    }
}

struct PrimaryButton: View {
    let title: String
    var emphasis: ButtonEmphasis = .quiet
    var isEnabled: Bool = true
    var accessibilityID: String? = nil
    var leadingImage: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            CapsuleFace(title: title, emphasis: emphasis, leadingImage: leadingImage)
        }
        .buttonStyle(PressScaleStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityID(accessibilityID)
        .accessibilityLabel(title)
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.quick, value: configuration.isPressed)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: Space.m) {
            Spacer(minLength: Space.xxxl)
            ZStack {
                Circle()
                    .fill(Color.fillQuiet)
                    .frame(width: 88, height: 88)
                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .regular))
                    .foregroundColor(Color.inkSecondary)
            }
            Text(title)
                .textStyle(.headline)
                .foregroundColor(Color.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .textStyle(.subhead)
                .foregroundColor(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Space.xxxl)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.horizontal, Space.xxxl)
                    .padding(.top, Space.xs)
            }
            Spacer(minLength: Space.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Settings row

struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var detail: String? = nil
    var showsChevron: Bool = true
    
    var body: some View {
        SettingsRowLayout(icon: icon, title: title, subtitle: subtitle) {
            if let detail {
                Text(detail)
                    .textStyle(.subhead)
                    .foregroundColor(Color.inkSecondary)
                    .fixedSize()
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.inkTertiary)
            }
        }
        .contentShape(Rectangle())
    }
}

/// A Settings row with a switch where the chevron would be.
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var accessibilityID: String? = nil
    
    var body: some View {
        SettingsRowLayout(icon: icon, title: title, subtitle: subtitle) {
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(Color.accent)
                .accessibilityID(accessibilityID)
        }
    }
}

/// Glyph, title and optional one-line subtitle, then a trailing accessory.
/// Every Settings row shares it so they line up.
private struct SettingsRowLayout<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    @ViewBuilder var trailing: Trailing
    
    var body: some View {
        HStack(spacing: Space.s) {
            RowGlyph(systemName: icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textStyle(.body, weight: .medium)
                    .foregroundColor(Color.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if let subtitle {
                    Text(subtitle)
                        .textStyle(.footnote, weight: .regular)
                        .foregroundColor(Color.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.horizontal, Space.m)
        .padding(.vertical, subtitle == nil ? 0 : Space.s)
        .frame(minHeight: 54)
    }
}

/// Small line glyph at the start of a row.
struct RowGlyph: View {
    let systemName: String
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(Color.ink)
            .frame(width: 22)
    }
}

struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(GroupBackground())
    }
}

struct HairlineDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.hairline)
            .frame(height: 0.5)
            .padding(.leading, Space.m + 22 + Space.s)
    }
}

// MARK: - Today pill

struct TodayPill: View {
    let seconds: TimeInterval
    
    var body: some View {
        HStack(spacing: 6) {
            Text(DurationText.hoursMinutes(seconds))
                .textStyle(.headline, weight: .bold)
                .foregroundColor(Color.ink)
                .numericTransition()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("blocked today")
                .textStyle(.footnote)
                .foregroundColor(Color.inkSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                .fill(Color.surfaceRaised)
                .shadow(color: Color.floatShadow, radius: 10, y: 3)
        )
    }
}

extension View {
    /// Sets an accessibility identifier only when one is given.
    @ViewBuilder
    func accessibilityID(_ id: String?) -> some View {
        if let id {
            accessibilityIdentifier(id)
        } else {
            self
        }
    }
}
