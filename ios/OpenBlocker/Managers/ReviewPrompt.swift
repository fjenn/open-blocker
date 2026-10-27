import SwiftUI
import StoreKit

/// Apple's rating prompt after a few real completed blocks. No custom
/// pre-prompt, no review text, no incentive.
enum ReviewPrompt {
    static let threshold = 3
    static let askedVersionsKey = "reviewPromptAskedVersions"
    
    /// Real completed blocks only. Emergency unblocks and lost Screen Time
    /// access do not count.
    static func completedCount(in history: [SessionRecord]) -> Int {
        history.filter { CountManager.completedEndings.contains($0.endedBy) }.count
    }
    
    /// Ask when idle, after enough completed blocks, once per app version.
    static func shouldAsk(
        history: [SessionRecord],
        isBlocking: Bool,
        appVersion: String,
        askedVersions: Set<String>
    ) -> Bool {
        guard !isBlocking else { return false }
        guard !appVersion.isEmpty else { return false }
        guard !askedVersions.contains(appVersion) else { return false }
        return completedCount(in: history) >= threshold
    }
    
    static func askedVersions(in defaults: UserDefaults) -> Set<String> {
        Set(defaults.stringArray(forKey: askedVersionsKey) ?? [])
    }
    
    static func markAsked(version: String, defaults: UserDefaults = .standard) {
        var versions = askedVersions(in: defaults)
        versions.insert(version)
        defaults.set(Array(versions).sorted(), forKey: askedVersionsKey)
    }
    
    static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}

/// Calls StoreKit after the home screen is idle again. Never during a block.
struct ReviewPromptModifier: ViewModifier {
    @Environment(\.requestReview) private var requestReview
    @ObservedObject private var appState = AppState.shared
    @State private var pendingAsk: Task<Void, Never>?
    
    func body(content: Content) -> some View {
        content
            .onAppear { scheduleIfNeeded() }
            .onChange(of: appState.isBlocking) { blocking in
                if blocking {
                    pendingAsk?.cancel()
                    pendingAsk = nil
                } else {
                    scheduleIfNeeded()
                }
            }
    }
    
    private func scheduleIfNeeded() {
        pendingAsk?.cancel()
        guard !isDemoLaunch, shouldAskNow() else { return }
        pendingAsk = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled, shouldAskNow() else { return }
            let version = ReviewPrompt.currentAppVersion
            ReviewPrompt.markAsked(version: version)
            requestReview()
        }
    }
    
    private func shouldAskNow() -> Bool {
        ReviewPrompt.shouldAsk(
            history: appState.history,
            isBlocking: appState.isBlocking,
            appVersion: ReviewPrompt.currentAppVersion,
            askedVersions: ReviewPrompt.askedVersions(in: .standard)
        )
    }
    
    private var isDemoLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains("-demo")
    }
}

extension View {
    func offersReviewPrompt() -> some View {
        modifier(ReviewPromptModifier())
    }
}
