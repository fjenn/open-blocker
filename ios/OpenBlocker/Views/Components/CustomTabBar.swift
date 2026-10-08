import SwiftUI

enum AppTab: String, CaseIterable {
    case block = "Block"
    case schedule = "Schedule"
    case activity = "Activity"
    case settings = "Settings"
    
    var accessibilityID: String {
        switch self {
        case .block: return AccessibilityID.tabBlock
        case .schedule: return AccessibilityID.tabSchedule
        case .activity: return AccessibilityID.tabActivity
        case .settings: return AccessibilityID.tabSettings
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabButton(
                    title: tab.rawValue,
                    isSelected: selectedTab == tab,
                    accessibilityID: tab.accessibilityID
                ) {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(Color.brickTabBar)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let accessibilityID: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .brickText(size: 15, weight: isSelected ? .semibold : .regular, relativeTo: .caption)
                    .foregroundColor(isSelected ? Color.brickInk : Color.brickMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                
                Circle()
                    .fill(isSelected ? Color.brickInk : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier(accessibilityID)
    }
}
