// Screen scaffolds and form controls shared by every screen.

import SwiftUI

// MARK: - Tab root

/// Root of a tab: small centred title, optional subtitle and trailing control,
/// scrolling content.
struct TabScreen<Trailing: View, Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var content: Content
    
    var body: some View {
        ZStack {
            ScreenCanvas()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.l) {
                    ZStack {
                        VStack(spacing: 2) {
                            Text(title)
                                .textStyle(.headline, weight: .medium)
                                .foregroundColor(Color.ink)
                                .accessibilityAddTraits(.isHeader)
                            if let subtitle {
                                Text(subtitle)
                                    .textStyle(.caption)
                                    .foregroundColor(Color.inkSecondary)
                            }
                        }
                        HStack {
                            Spacer()
                            trailing
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: Metrics.headerButton)
                    .padding(.top, Space.xs)
                    
                    content
                }
                .padding(.horizontal, Space.margin)
                .padding(.bottom, Space.tabBarClearance)
            }
            StatusBarScrim()
        }
    }
}

extension TabScreen where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = EmptyView()
        self.content = content()
    }
}

/// 40 pt round icon button (plus, close, more).
struct RoundIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    var accessibilityID: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.ink)
                .frame(width: Metrics.headerButton, height: Metrics.headerButton)
                .background(
                    Circle()
                        .fill(Color.surfaceRaised)
                        .shadow(color: Color.floatShadow, radius: 8, y: 2)
                )
                .contentShape(Circle())
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityID(accessibilityID)
    }
}

// MARK: - Sheet

/// A sheet control: a round icon button in the header, or (with a title)
/// the solid confirm button pinned to the bottom.
struct SheetAction {
    var title: String? = nil
    var systemImage: String? = nil
    var isEnabled = true
    var accessibilityLabel: String? = nil
    var accessibilityID: String? = nil
    let action: () -> Void
}

/// Every configuration screen is a sheet: centred title, round buttons in the
/// corners (close on the right), content, and one solid button at the bottom.
struct SheetScaffold<Content: View>: View {
    let title: String
    var leading: SheetAction? = nil
    var trailing: SheetAction? = nil
    var primary: SheetAction? = nil
    @ViewBuilder var content: Content
    
    var body: some View {
        ZStack {
            Color.sheet.ignoresSafeArea()
            VStack(spacing: 0) {
                ZStack {
                    Text(title)
                        .textStyle(.headline, weight: .medium)
                        .foregroundColor(Color.ink)
                        .accessibilityAddTraits(.isHeader)
                    HStack {
                        headerButton(leading)
                        Spacer()
                        headerButton(trailing)
                    }
                }
                .padding(.horizontal, Space.margin)
                .padding(.top, Space.l)
                .padding(.bottom, Space.m)
                
                content
                
                if let primary, let title = primary.title {
                    PrimaryButton(
                        title: title,
                        emphasis: .ink,
                        isEnabled: primary.isEnabled,
                        accessibilityID: primary.accessibilityID,
                        action: primary.action
                    )
                    .padding(.horizontal, Space.margin)
                    .padding(.top, Space.s)
                    .padding(.bottom, Space.xs)
                }
            }
        }
    }
    
    @ViewBuilder
    private func headerButton(_ action: SheetAction?) -> some View {
        if let action, let systemName = action.systemImage {
            RoundIconButton(
                systemName: systemName,
                accessibilityLabel: action.accessibilityLabel ?? action.title ?? "",
                accessibilityID: action.accessibilityID,
                action: action.action
            )
            .disabled(!action.isEnabled)
            .opacity(action.isEnabled ? 1 : 0.4)
        } else {
            Color.clear.frame(width: Metrics.headerButton, height: Metrics.headerButton)
        }
    }
}

// MARK: - Form pieces

struct FieldCaption: View {
    let text: String
    
    var body: some View {
        Text(text)
            .textStyle(.caption)
            .foregroundColor(Color.inkSecondary)
            .padding(.leading, Space.xxs)
    }
}

/// "Label ........ value" row used inside form cards.
struct FormRow<Trailing: View>: View {
    let label: String
    @ViewBuilder var trailing: Trailing
    
    var body: some View {
        HStack(spacing: Space.s) {
            Text(label)
                .textStyle(.subhead)
                .foregroundColor(Color.inkSecondary)
                .fixedSize()
            Spacer(minLength: Space.s)
            trailing
                .textStyle(.subhead, weight: .semibold)
                .foregroundColor(Color.ink)
        }
        .padding(.horizontal, Space.m)
        .frame(minHeight: 54)
    }
}

/// A labelled text field row; the text sits on the right like a value.
struct FormTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        FormRow(label: label) {
            TextField(placeholder, text: $text)
                .multilineTextAlignment(.trailing)
                .submitLabel(.done)
        }
    }
}

/// Small "i" note for a heads-up inside a form.
struct InfoNote: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Space.xs) {
            Image(systemName: "info.circle")
                .font(.system(size: 13, weight: .regular))
                .padding(.top, 1)
            Text(text)
                .textStyle(.footnote, weight: .regular)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(Color.inkSecondary)
        .padding(Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                .fill(Color.fillQuiet.opacity(0.7))
        )
    }
}

/// Capsule segmented control (replaces the system one for a calmer look).
struct SegmentedPill<Value: Hashable>: View {
    let options: [(label: String, value: Value)]
    @Binding var selection: Value
    @Namespace private var thumb
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let isOn = option.value == selection
                Button {
                    withAnimation(Motion.standard) { selection = option.value }
                } label: {
                    Text(option.label)
                        .textStyle(.subhead, weight: .semibold)
                        .foregroundColor(isOn ? Color.inkInverse : Color.inkSecondary)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background {
                            if isOn {
                                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                                    .fill(Color.ink)
                                    .matchedGeometryEffect(id: "thumb", in: thumb)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                .fill(Color.fillQuiet)
        )
    }
}

/// Title + explanation + switch, used by Rules and Notifications.
struct ToggleRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var accessibilityID: String? = nil
    
    var body: some View {
        HStack(alignment: .center, spacing: Space.s) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .textStyle(.body, weight: .semibold)
                    .foregroundColor(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .textStyle(.subhead)
                        .foregroundColor(Color.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: Space.s)
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(Color.accent)
                .accessibilityID(accessibilityID)
        }
        .padding(.horizontal, Space.m)
        .padding(.vertical, Space.m)
    }
}

/// One option in a chooser list: icon, title, subtitle, chevron.
struct OptionRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        HStack(spacing: Space.s) {
            IconTile(systemName: icon, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textStyle(.headline)
                    .foregroundColor(Color.ink)
                if let subtitle {
                    Text(subtitle)
                        .textStyle(.subhead)
                        .foregroundColor(Color.inkSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.inkTertiary)
        }
        .padding(Space.m)
        .background(CardBackground())
        .contentShape(Rectangle())
    }
}

// MARK: - Toast

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let message {
                Text(message)
                    .textStyle(.subhead, weight: .medium)
                    .foregroundColor(Color.inkInverse)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Space.l)
                    .padding(.vertical, Space.s)
                    .background(Capsule(style: .continuous).fill(Color.ink.opacity(0.92)))
                    .shadow(color: Color.floatShadow, radius: 16, y: 6)
                    .padding(.horizontal, Space.xl)
                    .padding(.top, Space.xs)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .onTapGesture { self.message = nil }
                    .task(id: message) {
                        UIAccessibility.post(notification: .announcement, argument: message)
                        try? await Task.sleep(nanoseconds: 2_800_000_000)
                        withAnimation(Motion.quick) { self.message = nil }
                    }
                    .accessibilityIdentifier("toast")
            }
        }
        .animation(reduceMotion ? nil : Motion.standard, value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}

// MARK: - Brand

/// The Open Blocker mark: keyhole inside a tag circle (press/logo.svg).
struct BrandMark: View {
    var size: CGFloat = 72
    
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0x4450F2))
            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: size * 10 / 512)
                .padding(size * 50 / 512)
            KeyholeShape()
                .fill(Color.white)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct KeyholeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 512
        var path = Path()
        path.addEllipse(in: CGRect(x: (256 - 62) * s, y: (214 - 62) * s, width: 124 * s, height: 124 * s))
        path.move(to: CGPoint(x: 226 * s, y: 250 * s))
        path.addLine(to: CGPoint(x: 286 * s, y: 250 * s))
        path.addLine(to: CGPoint(x: 306 * s, y: 366 * s))
        path.addQuadCurve(to: CGPoint(x: 294 * s, y: 380 * s), control: CGPoint(x: 308 * s, y: 380 * s))
        path.addLine(to: CGPoint(x: 218 * s, y: 380 * s))
        path.addQuadCurve(to: CGPoint(x: 206 * s, y: 366 * s), control: CGPoint(x: 204 * s, y: 380 * s))
        path.closeSubpath()
        return path
    }
}
