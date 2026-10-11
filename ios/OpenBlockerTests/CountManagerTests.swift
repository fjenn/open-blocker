import XCTest
@testable import OpenBlocker

final class CountManagerTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "countMeEnabled")
        UserDefaults.standard.removeObject(forKey: "installId")
    }
    
    func testCountIsOnByDefault() {
        XCTAssertTrue(CountManager.enabledByDefault)
    }
    
    func testFirstLaunchDefaultsToEnabled() {
        UserDefaults.standard.removeObject(forKey: "countMeEnabled")
        
        let manager = CountManager.shared
        
        XCTAssertTrue(manager.isEnabled)
    }
    
    func testInstallIdCreatedWhenEnabledByDefault() {
        UserDefaults.standard.removeObject(forKey: "countMeEnabled")
        UserDefaults.standard.removeObject(forKey: "installId")
        
        _ = CountManager.shared
        
        let installId = UserDefaults.standard.string(forKey: "installId")
        XCTAssertNotNil(installId)
        XCTAssertFalse(installId?.isEmpty ?? true)
    }
    
    func testDisablingAndReenablingPreservesInstallId() {
        UserDefaults.standard.removeObject(forKey: "countMeEnabled")
        UserDefaults.standard.removeObject(forKey: "installId")
        
        let manager = CountManager.shared
        let originalId = UserDefaults.standard.string(forKey: "installId")
        
        manager.setEnabled(false)
        manager.setEnabled(true)
        
        let newId = UserDefaults.standard.string(forKey: "installId")
        XCTAssertEqual(originalId, newId)
    }
}
