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

struct MainTabView: View {
    @State private var selectedTab: AppTab
    /// Bumped when the selected tab is tapped again: rebuilding the tab pops
    /// its navigation stack to the root and drops sheets it presented.
    @State private var resetToken = 0
    
    init(initialTab: AppTab = .block) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .block: BlockTab()
                case .schedule: ScheduleTab()
                case .activity: ActivityTab()
                case .settings: SettingsTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id("\(selectedTab.rawValue)-\(resetToken)")
            .transition(.opacity)
            .background(Color.canvas)
            .clipShape(ScreenCardShape())
            .shadow(color: Color.floatShadow, radius: 18, y: 8)
            .zIndex(1)
            
            TextTabBar(selectedTab: $selectedTab, onReselect: { _ in
                UISelectionFeedbackGenerator().selectionChanged()
                resetToken += 1
            })
        }
        .animation(Motion.fade, value: selectedTab)
        .background(Color.chrome.ignoresSafeArea())
    }
}
