import SwiftUI
import StoreKit

/// Apple's rating prompt after a few real physical-key unblocks. No custom
/// pre-prompt, no review text, no incentive.
enum ReviewPrompt {
    static let threshold = 3
    static let countKey = "reviewPromptKeyUnblockCount"
    static let askedVersionsKey = "reviewPromptAskedVersions"
    
    /// Successful NFC/QR key unblocks only. Emergency unblocks, schedule ends,
    /// and block starts do not count.
    static func keyUnblockCount(in defaults: UserDefaults = .standard) -> Int {
        max(0, defaults.integer(forKey: countKey))
    }
    
    /// Call from the single successful key-unblock path (NFC and QR both land
    /// there). Returns the new persistent count.
    @discardableResult
    static func recordKeyUnblock(defaults: UserDefaults = .standard) -> Int {
        let next = keyUnblockCount(in: defaults) + 1
        defaults.set(next, forKey: countKey)
        return next
    }
    
    /// Ask after enough key unblocks, once per app version.
    static func shouldAsk(
        keyUnblockCount: Int,
        appVersion: String,
        askedVersions: Set<String>
    ) -> Bool {
        guard !appVersion.isEmpty else { return false }
        guard !askedVersions.contains(appVersion) else { return false }
        return keyUnblockCount >= threshold
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

/// Calls StoreKit a short moment after a successful key unblock settles on
/// the foreground scene. Never on block start, and never for emergency ends.
struct ReviewPromptModifier: ViewModifier {
    @Environment(\.requestReview) private var requestReview
    @ObservedObject private var appState = AppState.shared
    @State private var pendingAsk: Task<Void, Never>?
    
    func body(content: Content) -> some View {
        content
            .onAppear { scheduleIfNeeded() }
            .onChange(of: appState.keyUnblockCount) { _ in
                scheduleIfNeeded()
            }
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
        guard !appState.isBlocking else { return false }
        return ReviewPrompt.shouldAsk(
            keyUnblockCount: appState.keyUnblockCount,
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
