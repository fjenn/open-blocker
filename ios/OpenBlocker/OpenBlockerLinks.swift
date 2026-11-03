import Foundation

enum OpenBlockerLinks {
    static let projectPage = URL(string: "https://openblocker.org")!
    static let feedback = URL(string: "https://openblocker.org/feedback")!
    static let sourceCode = URL(string: "https://github.com/fjenn/open-blocker")!
    static let privacy = URL(string: "https://openblocker.org/privacy")!
    static let appStore = URL(string: "https://apps.apple.com/app/id6824046126")!
    static let screenTimePasscode = URL(string: "https://support.apple.com/guide/iphone/set-up-screen-time-iphbfa8fc685/ios")!
}

/// What the "Share Open Blocker" row in Settings hands to the share sheet.
enum ShareOpenBlocker {
    static let rowTitle = "Share Open Blocker"
    static let icon = "square.and.arrow.up"
    static let url = OpenBlockerLinks.appStore
    static let subject = "Open Blocker"
    static let message = "Open Blocker: block distracting apps, unlock only with a physical key. Free and open source."
}
