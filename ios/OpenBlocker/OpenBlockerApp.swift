import SwiftUI
import FamilyControls

@main
struct OpenBlockerApp: App {
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

struct AppRootView: View {
    @StateObject private var appState = AppState.shared
    
    #if DEBUG
    private var isDemoMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-demo")
    }
    
    private var startTab: String? {
        let args = ProcessInfo.processInfo.arguments
        if let tabIndex = args.firstIndex(of: "-tab"), tabIndex + 1 < args.count {
            return args[tabIndex + 1]
        }
        return nil
    }
    
    private var startScreen: String? {
        let args = ProcessInfo.processInfo.arguments
        if let screenIndex = args.firstIndex(of: "-screen"), screenIndex + 1 < args.count {
            return args[screenIndex + 1]
        }
        return nil
    }
    
    #endif
    
    var body: some View {
        Group {
            #if DEBUG
            if isDemoMode {
                if let screen = startScreen {
                    DebugScreenLauncher(screen: screen)
                } else if let tab = startTab {
                    MainTabView(initialTab: appTabFromString(tab))
                } else {
                    MainTabView(initialTab: .block)
                }
            } else if !appState.hasSeenOnboarding {
                OnboardingView()
            } else {
                MainTabView(initialTab: .block)
            }
            #else
            if appState.hasSeenOnboarding {
                MainTabView(initialTab: .block)
            } else {
                OnboardingView()
            }
            #endif
        }
    }
    
    #if DEBUG
    private func appTabFromString(_ str: String) -> AppTab {
        switch str {
        case "block": return .block
        case "schedule": return .schedule
        case "activity": return .activity
        case "settings": return .settings
        default: return .block
        }
    }
    #endif
}

#if DEBUG
struct DebugScreenLauncher: View {
    let screen: String
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        switch screen {
        case "home-idle", "home-filling":
            MainTabView(initialTab: .block)
        case "home-blocked", "blocking":
            BlockedStateView()
        case "schedules":
            MainTabView(initialTab: .schedule)
        case "activity":
            MainTabView(initialTab: .activity)
        case "settings":
            MainTabView(initialTab: .settings)
        default:
            NavigationStack {
                Group {
                    switch screen {
                    case "modes":
                        ModesScreen()
                    case "mode-edit":
                        ModeEditScreen()
                    case "schedule-edit":
                        ScheduleEditScreen()
                    case "keys":
                        KeysManagementScreen()
                    case "key-setup":
                        KeySetupScreen()
                    case "emergency-unblock":
                        EmergencyUnblockScreen()
                    case "rules":
                        RulesScreen()
                    case "onboarding":
                        OnboardingView()
                    default:
                        MainTabView(initialTab: .block)
                    }
                }
            }
        }
    }
}

struct BlockedStateView: View {
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        MainTabView(initialTab: .block)
            .onAppear {
                #if DEBUG
                appState.startDemoBlocking()
                #endif
            }
    }
}
#endif
