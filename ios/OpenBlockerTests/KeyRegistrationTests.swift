import XCTest
@testable import OpenBlocker

final class KeyRegistrationTests: XCTestCase {
    private let stableUID = Data("04aabbccddeeff".utf8)
    private let otherUID = Data("04ffffffffffff".utf8)
    
    func testStableCardUIDsRegister() async throws {
        let scanner = MockNFCScanner(results: [
            .success(.card(uid: stableUID)),
            .success(.card(uid: stableUID))
        ])
        let first = try await scanner.scan()
        let second = try await scanner.scan()
        XCTAssertEqual(scanner.scanCallCount, 2)
        
        let firstUID = try XCTUnwrap(KeyRegistration.nfcUIDHex(from: first))
        let secondUID = try XCTUnwrap(KeyRegistration.nfcUIDHex(from: second))
        XCTAssertEqual(
            KeyRegistration.confirmCard(firstUID: firstUID, secondUID: secondUID),
            .match(uidHex: firstUID)
        )
    }
    
    func testChangingCardUIDIsRejectedWithAgreedWording() async throws {
        let scanner = MockNFCScanner(results: [
            .success(.card(uid: stableUID)),
            .success(.card(uid: otherUID))
        ])
        let first = try await scanner.scan()
        let second = try await scanner.scan()
        let firstUID = try XCTUnwrap(KeyRegistration.nfcUIDHex(from: first))
        let secondUID = try XCTUnwrap(KeyRegistration.nfcUIDHex(from: second))
        XCTAssertEqual(
            KeyRegistration.confirmCard(firstUID: firstUID, secondUID: secondUID),
            .rotating
        )
        XCTAssertEqual(
            KeyRegistration.rotatingCardMessage,
            "Many transit cards, hotel keys and work badges work. Test yours. Many bank cards and phone wallets show a new ID on each tap, so they can't be used."
        )
    }
    
    func testOpenBlockerTagMatchesUIDAndNDEFId() {
        let uid = Data("04a1b2c3d4e5f6".utf8)
        let ndefId = Data((0..<16).map { UInt8($0) })
        let byUID = BlockKey(name: "Desk", kind: .openBlockerTag, secret: uid.hexString)
        let byNDEF = BlockKey(name: "Desk", kind: .openBlockerTag, secret: ndefId.hexString)
        
        XCTAssertTrue(byUID.matches(.card(uid: uid)))
        XCTAssertTrue(byUID.matches(.openBlocker(id: ndefId, uid: uid)))
        XCTAssertTrue(byNDEF.matches(.openBlocker(id: ndefId, uid: uid)))
        XCTAssertFalse(byNDEF.matches(.card(uid: uid)))
        XCTAssertFalse(byUID.matches(.card(uid: otherUID)))
    }
    
    func testCardKeyMatchesUIDFromOpenBlockerScan() {
        let uid = Data("04a1b2c3d4e5f6".utf8)
        let key = BlockKey(name: "Badge", kind: .card, secret: uid.hexString)
        XCTAssertTrue(key.matches(.card(uid: uid)))
        XCTAssertTrue(key.matches(.openBlocker(id: Data((0..<16).map { $0 }), uid: uid)))
        XCTAssertFalse(key.matches(.card(uid: otherUID)))
    }
    
    func testQRPayloadsMatchAfterCanonicalize() throws {
        let tagId = try OpenBlockerFormat.hexToBytes("550e8400e29b41d4a716446655440000")
        let uri = OpenBlockerFormat.encodeForQR(OpenBlockerFormat.TagData(tagId: tagId))
        let key = BlockKey(name: "Gym", kind: .qr, secret: uri)
        XCTAssertTrue(key.matches(.qr(payload: uri)))
        XCTAssertTrue(key.matches(KeyScanner.scannedKey(fromQR: uri)))
        XCTAssertFalse(key.matches(.qr(payload: "openblocker://tag/v1/ffffffffffffffffffffffffffffffff")))
    }
    
    func testKeyScannerRoute() {
        let nfc = BlockKey(name: "Desk", kind: .openBlockerTag, secret: "aa")
        let card = BlockKey(name: "Card", kind: .card, secret: "bb")
        let qr = BlockKey(name: "Gym", kind: .qr, secret: "cc")
        XCTAssertEqual(KeyScanner.route(for: []), .none)
        XCTAssertEqual(KeyScanner.route(for: [nfc]), .nfc)
        XCTAssertEqual(KeyScanner.route(for: [card]), .nfc)
        XCTAssertEqual(KeyScanner.route(for: [qr]), .qr)
        XCTAssertEqual(KeyScanner.route(for: [nfc, qr]), .choose)
    }
    
    func testDemoDeskKeyMatchesDefaultMockScan() async throws {
        let scanner = MockNFCScanner()
        let scanned = try await scanner.scan()
        let desk = BlockKey(
            name: "Desk Key",
            kind: .openBlockerTag,
            secret: MockNFCScanner.defaultUID.hexString
        )
        XCTAssertTrue(desk.matches(scanned))
        XCTAssertEqual(KeyRegistration.nfcUIDHex(from: scanned), MockNFCScanner.defaultUID.hexString)
    }
    
    func testMockWriteRecordsTagId() async throws {
        let scanner = MockNFCScanner()
        let tagId = OpenBlockerFormat.generateTagId()
        try await scanner.writeOpenBlockerRecord(tagId: tagId)
        XCTAssertEqual(scanner.writeCallCount, 1)
        XCTAssertEqual(scanner.lastWrittenTagId, tagId)
    }
}
