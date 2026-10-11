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

class CountManager: ObservableObject {
    static let shared = CountManager()
    static let enabledByDefault = true
    
    @Published private(set) var isEnabled = false
    
    private let defaults = UserDefaults.standard
    private let isEnabledKey = "countMeEnabled"
    private let installIdKey = "installId"
    private let firstBlockSentKey = "firstBlockSent"
    private let sendPendingKey = "sendPending"
    private let blockCountKey = "blockCount"
    private let reviewPromptShownKey = "reviewPromptShown"
    
    private init() {
        if defaults.object(forKey: isEnabledKey) == nil {
            isEnabled = CountManager.enabledByDefault
            if isEnabled {
                ensureInstallId()
            }
        } else {
            isEnabled = defaults.bool(forKey: isEnabledKey)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionStarted), name: .sessionStarted, object: nil)
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        defaults.set(enabled, forKey: isEnabledKey)
        
        if enabled {
            ensureInstallId()
        }
    }
    
    private func ensureInstallId() {
        if defaults.string(forKey: installIdKey) == nil {
            defaults.set(UUID().uuidString, forKey: installIdKey)
        }
    }
    
    @objc private func sessionStarted() {
        guard isEnabled else { return }
        
        let count = defaults.integer(forKey: blockCountKey) + 1
        defaults.set(count, forKey: blockCountKey)
        
        if count == 1 && !defaults.bool(forKey: firstBlockSentKey) {
            defaults.set(true, forKey: sendPendingKey)
            sendFirstBlock()
        } else if count == 3 && !defaults.bool(forKey: reviewPromptShownKey) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .showReviewPrompt, object: nil)
            }
            defaults.set(true, forKey: reviewPromptShownKey)
        }
    }
    
    func retrySendIfPending() {
        guard isEnabled,
              defaults.bool(forKey: sendPendingKey),
              !defaults.bool(forKey: firstBlockSentKey) else {
            return
        }
        sendFirstBlock()
    }
    
    private func sendFirstBlock() {
        guard Config.countEnabled,
              let installId = defaults.string(forKey: installIdKey) else {
            return
        }
        
        Task {
            do {
                guard let url = URL(string: "\(Config.countURL)/rest/v1/pings") else { return }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(Config.countKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(Config.countKey)", forHTTPHeaderField: "Authorization")
                request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
                
                let payload: [String: Any] = [
                    "install_id": installId,
                    "event": "first_block",
                    "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse,
                   (200...299).contains(httpResponse.statusCode) {
                    defaults.set(true, forKey: firstBlockSentKey)
                    defaults.set(false, forKey: sendPendingKey)
                }
            } catch {
                // Silent failure, will retry
            }
        }
    }
    
    func sendReview(review: String, email: String?) {
        guard Config.countEnabled,
              let installId = defaults.string(forKey: installIdKey) else {
            return
        }
        
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
                    "install_id": installId,
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
