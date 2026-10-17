import SwiftUI

/// Explains a permission that was turned off, with a way to Settings.
struct PermissionSheet: View {
    let permission: Permission
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.sheet.ignoresSafeArea()
            VStack(spacing: Space.m) {
                IconTile(systemName: permission.symbol, size: 56)
                    .padding(.top, Space.xl)
                VStack(spacing: Space.xs) {
                    Text(permission.deniedTitle)
                        .textStyle(.title, weight: .medium)
                        .foregroundColor(Color.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(permission.deniedMessage)
                        .textStyle(.body)
                        .foregroundColor(Color.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Space.l)
                Spacer(minLength: 0)
                VStack(spacing: Space.xs) {
                    PrimaryButton(
                        title: "Open Settings",
                        emphasis: .ink,
                        accessibilityID: AccessibilityID.permissionOpenSettings
                    ) {
                        Permissions.openSettings()
                        dismiss()
                    }
                    Button("Not now") { dismiss() }
                        .textStyle(.subhead, weight: .semibold)
                        .foregroundColor(Color.inkSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityIdentifier(AccessibilityID.permissionNotNow)
                }
            }
            .padding(.horizontal, Space.margin)
            .padding(.bottom, Space.xs)
        }
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
    }
}

extension View {
    /// Shows PermissionSheet while `permission` is set.
    func permissionSheet(_ permission: Binding<Permission?>) -> some View {
        sheet(item: permission) { PermissionSheet(permission: $0) }
    }
}
