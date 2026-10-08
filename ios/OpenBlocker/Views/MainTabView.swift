import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var tabBar = TabBarState()
    @State private var selectedTab: AppTab
    
    init(initialTab: AppTab = .block) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .block:
                    BlockTab()
                case .schedule:
                    ScheduleTab()
                case .activity:
                    ActivityTab()
                case .settings:
                    SettingsTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            
            if !tabBar.hidden {
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .background(Color.brickCanvas)
        .environmentObject(tabBar)
    }
}
