import Foundation

struct Config {
    static var countURL: String {
        Bundle.main.infoDictionary?["COUNT_URL"] as? String ?? ""
    }
    
    static var countKey: String {
        Bundle.main.infoDictionary?["COUNT_KEY"] as? String ?? ""
    }
    
    static var countEnabled: Bool {
        !countURL.isEmpty && !countKey.isEmpty
    }
}

/// The anonymous count. While "Share anonymous count" is on (the default),
/// every completed block sends one tiny event: a random install ID made on
/// this phone, the event name, a random event ID (so a retry is not counted
/// twice) and the app version. No app names, no times of use, no personal data.
///
/// From these events the server derives two numbers:
/// - people who completed at least one block = distinct install IDs
/// - blocks completed = number of events
///
/// Nothing is sent while `endpoint` is unset (COUNT_ENDPOINT in the xcconfig).
@MainActor
final class CountManager: ObservableObject {
    static let shared = CountManager()
    
    /// On until the user turns it off.
    static let enabledByDefault = true
    
    /// The one line under the Settings switch.
    static let summary = "Counts finished blocks. No personal data."
    
    /// Exactly what is sent, on the Privacy page.
    static let disclosure = "When a block finishes, the app sends an anonymous install ID and a \"block completed\" event with the app version. No app names, no usage times, no personal data."
    
    /// The single place the events go. Nil (unset) means nothing is ever sent.
    static let endpoint: URL? = {
        let value = (Bundle.main.infoDictionary?["COUNT_ENDPOINT"] as? String ?? "")
            .trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty, let url = URL(string: value), url.scheme == "https" else { return nil }
        return url
    }()
    
    @Published private(set) var isEnabled = CountManager.enabledByDefault
    
    /// What happened to one event.
    enum Delivery: Equatable {
        /// Stored now, or already stored (409). Never resend.
        case delivered
        /// The server refused this event (400 and similar). Don't resend it.
        case dropped
        /// Offline, timeout, rate limit or server error. Try again later.
        case retry
    }
    
    nonisolated static func delivery(forStatus status: Int) -> Delivery {
        switch status {
        case 200...299, 409: return .delivered
        case 408, 429: return .retry
        case 400...499: return .dropped
        default: return .retry
        }
    }
    
    typealias Transport = (URLRequest) async -> Delivery
    
    private let defaults: UserDefaults
    private let endpoint: URL?
    private let transport: Transport
    private var isSending = false
    
    private let isEnabledKey = "countMeEnabled"
    private let installIdKey = "installId"
    private let reportedKey = "countReportedBlockIDs"
    private let baselineKey = "countBaselineDone"
    private let blockCountKey = "blockCount"
    private let reviewPromptShownKey = "reviewPromptShown"
    
    init(
        defaults: UserDefaults = .standard,
        endpoint: URL? = CountManager.endpoint,
        transport: @escaping Transport = CountManager.urlSessionTransport
    ) {
        self.defaults = defaults
        self.endpoint = endpoint
        self.transport = transport
        defaults.register(defaults: [isEnabledKey: Self.enabledByDefault])
        isEnabled = defaults.bool(forKey: isEnabledKey)
        if isEnabled { ensureInstallId() }
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionStarted), name: .sessionStarted, object: nil)
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        defaults.set(enabled, forKey: isEnabledKey)
        if enabled { ensureInstallId() }
    }
    
    var installId: String? { defaults.string(forKey: installIdKey) }
    
    private func ensureInstallId() {
        if defaults.string(forKey: installIdKey) == nil {
            defaults.set(UUID().uuidString, forKey: installIdKey)
        }
    }
    
    // MARK: Completed blocks
    
    /// Ways a block can end that count as "completed". Emergency unblocks and
    /// lost Screen Time access don't count.
    nonisolated static let completedEndings: Set<SessionRecord.EndReason> = [.key, .scheduleEnd, .passage]
    
    nonisolated static func completed(in history: [SessionRecord], excluding reported: Set<UUID>) -> [SessionRecord] {
        history.filter { completedEndings.contains($0.endedBy) && !reported.contains($0.id) }
    }
    
    /// The whole event. Nothing else is sent.
    nonisolated static func payload(for record: SessionRecord, installId: String, appVersion: String) -> [String: String] {
        [
            "installId": installId,
            "event": "block_completed",
            "eventId": record.id.uuidString,
            "appVersion": appVersion,
            "platform": "ios"
        ]
    }
    
    /// What the server computes from the events it received.
    nonisolated static func metrics(from events: [[String: String]]) -> (people: Int, blocks: Int) {
        let completed = events.filter { $0["event"] == "block_completed" }
        let unique = Dictionary(grouping: completed, by: { $0["eventId"] ?? UUID().uuidString })
        return (Set(completed.compactMap { $0["installId"] }).count, unique.count)
    }
    
    private var reportedIDs: Set<UUID> {
        Set((defaults.stringArray(forKey: reportedKey) ?? []).compactMap(UUID.init(uuidString:)))
    }
    
    private func markReported(_ id: UUID) {
        var list = defaults.stringArray(forKey: reportedKey) ?? []
        list.append(id.uuidString)
        defaults.set(Array(list.suffix(2000)), forKey: reportedKey)
    }
    
    /// Sends one event per completed block not sent yet. Safe to call often
    /// (launch, foreground, after a block ends); failures retry next time.
    func reportCompletedBlocks(in history: [SessionRecord]) async {
        // First run with this feature: blocks finished before it existed are
        // not sent, only ones finished from now on.
        if !defaults.bool(forKey: baselineKey) {
            for record in Self.completed(in: history, excluding: reportedIDs) { markReported(record.id) }
            defaults.set(true, forKey: baselineKey)
            return
        }
        guard isEnabled, let endpoint, !isSending else { return }
        ensureInstallId()
        guard let installId else { return }
        let pending = Self.completed(in: history, excluding: reportedIDs)
        guard !pending.isEmpty else { return }
        isSending = true
        defer { isSending = false }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        for record in pending {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(
                withJSONObject: Self.payload(for: record, installId: installId, appVersion: version),
                options: [.sortedKeys]
            )
            switch await transport(request) {
            case .delivered, .dropped: markReported(record.id)
            case .retry: return // try again later, in order
            }
        }
    }
    
    nonisolated static func urlSessionTransport(_ request: URLRequest) async -> Delivery {
        var request = request
        request.timeoutInterval = 15
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else { return .retry }
        return delivery(forStatus: http.statusCode)
    }
    
    // MARK: Review prompt (local only)
    
    @objc private func sessionStarted() {
        let count = defaults.integer(forKey: blockCountKey) + 1
        defaults.set(count, forKey: blockCountKey)
        if count == 3 && !defaults.bool(forKey: reviewPromptShownKey) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .showReviewPrompt, object: nil)
            }
            defaults.set(true, forKey: reviewPromptShownKey)
        }
    }
    
    func sendReview(review: String, email: String?) {
        // Deliberately no install ID: a review (which may include an email)
        // must never be linkable to the anonymous block count.
        guard isEnabled, Config.countEnabled else { return }
        
        Task {
            do {
                guard let url = URL(string: "\(Config.countURL)/rest/v1/reviews") else { return }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(Config.countKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(Config.countKey)", forHTTPHeaderField: "Authorization")
                request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
                
                var payload: [String: Any] = [
                    "review": review,
                    "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                    "platform": "ios"
                ]
                
                if let email = email, !email.isEmpty {
                    payload["email"] = email
                }
                
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                
                _ = try await URLSession.shared.data(for: request)
            } catch {
                // Silent failure
            }
        }
    }
}

extension Notification.Name {
    static let sessionStarted = Notification.Name("sessionStarted")
    static let showReviewPrompt = Notification.Name("showReviewPrompt")
}
