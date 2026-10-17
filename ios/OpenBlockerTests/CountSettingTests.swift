import XCTest
@testable import OpenBlocker

final class CountSettingTests: XCTestCase {
    func testCountIsOnByDefault() {
        XCTAssertTrue(CountManager.enabledByDefault)
    }
    
    func testSettingsLineIsShort() {
        let words = CountManager.summary.split(separator: " ")
        XCTAssertLessThanOrEqual(words.count, 8)
        XCTAssertTrue(CountManager.summary.contains("No personal data"))
    }
    
    func testPrivacyPageSaysExactlyWhatIsSent() {
        let text = CountManager.disclosure
        XCTAssertTrue(text.contains("anonymous install ID"))
        XCTAssertTrue(text.contains("\"block completed\" event"))
        XCTAssertTrue(text.contains("app version"))
        XCTAssertTrue(text.contains("No app names"))
        XCTAssertTrue(text.contains("no personal data"))
    }
    
    func testCopyHasNoOptInWordingOrEmDashes() {
        for text in [CountManager.summary, CountManager.disclosure] {
            XCTAssertFalse(text.localizedCaseInsensitiveContains("opt-in"))
            XCTAssertFalse(text.localizedCaseInsensitiveContains("off by default"))
            XCTAssertFalse(text.contains("\u{2014}"), "no em dashes in copy")
        }
    }
}

/// The app's links all use openblocker.org; the old vercel.app host is gone.
final class LinkDomainTests: XCTestCase {
    func testLinksUseOpenBlockerOrg() {
        XCTAssertEqual(OpenBlockerLinks.projectPage.host, "openblocker.org")
        XCTAssertEqual(OpenBlockerLinks.privacy.absoluteString, "https://openblocker.org/privacy")
        XCTAssertEqual(OpenBlockerLinks.feedback.absoluteString, "https://openblocker.org/feedback")
    }
    
    func testNoSourceStringContainsVercelApp() throws {
        // ios/OpenBlockerTests/<this file> -> ios/
        let ios = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let roots = ["OpenBlocker", "OpenBlockerMonitor", "Config", "project.yml"].map { ios.appendingPathComponent($0) }
        let banned = "vercel" + ".app"
        var checked = 0
        var offenders: [String] = []
        for root in roots {
            var files: [URL] = []
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDir) else { continue }
            if isDir.boolValue {
                let e = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
                while let url = e?.nextObject() as? URL {
                    if ["swift", "plist", "strings", "xcconfig", "json", "entitlements", "yml"].contains(url.pathExtension) { files.append(url) }
                }
            } else {
                files.append(root)
            }
            for file in files {
                guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
                checked += 1
                if text.contains(banned) { offenders.append(file.lastPathComponent) }
            }
        }
        try XCTSkipIf(checked == 0, "source tree not reachable from this test run")
        XCTAssertGreaterThan(checked, 20)
        XCTAssertEqual(offenders, [], "files still mentioning \(banned)")
        // Also the built Info.plist.
        let info = Bundle.main.infoDictionary?.description ?? ""
        XCTAssertFalse(info.contains(banned))
    }
}
