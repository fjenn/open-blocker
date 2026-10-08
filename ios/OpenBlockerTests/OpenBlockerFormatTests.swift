import XCTest
@testable import OpenBlocker

final class OpenBlockerFormatTests: XCTestCase {
    
    func testGenerateTagId() {
        let id1 = OpenBlockerFormat.generateTagId()
        let id2 = OpenBlockerFormat.generateTagId()
        
        XCTAssertEqual(id1.count, 16)
        XCTAssertEqual(id2.count, 16)
        XCTAssertNotEqual(id1, id2)
    }
    
    func testEncodeDecodeMinimal() throws {
        let tagId = try OpenBlockerFormat.hexToBytes("550e8400e29b41d4a716446655440000")
        let data = OpenBlockerFormat.TagData(
            tagId: tagId,
            androidPackage: "app.openblocker.android"
        )
        
        let encoded = OpenBlockerFormat.encode(data)
        let decoded = try OpenBlockerFormat.decode(encoded)
        
        XCTAssertEqual(decoded.version, OpenBlockerFormat.VERSION)
        XCTAssertEqual(decoded.tagId, tagId)
        XCTAssertEqual(decoded.androidPackage, "app.openblocker.android")
    }
    
    func testEncodeDecodeWithoutAAR() throws {
        let tagId = try OpenBlockerFormat.hexToBytes("f47ac10b58cc4372a5670e02b2c3d479")
        let data = OpenBlockerFormat.TagData(tagId: tagId, androidPackage: nil)
        
        let encoded = OpenBlockerFormat.encode(data)
        let decoded = try OpenBlockerFormat.decode(encoded)
        
        XCTAssertEqual(decoded.version, OpenBlockerFormat.VERSION)
        XCTAssertEqual(decoded.tagId, tagId)
        XCTAssertNil(decoded.androidPackage)
    }
    
    func testTestVector1() throws {
        let tagId = try OpenBlockerFormat.hexToBytes("550e8400e29b41d4a716446655440000")
        let data = OpenBlockerFormat.TagData(
            tagId: tagId,
            androidPackage: "app.openblocker.android"
        )
        
        let encoded = OpenBlockerFormat.encode(data)
        
        XCTAssertTrue(encoded.count < 144)
        
        let decoded = try OpenBlockerFormat.decode(encoded)
        XCTAssertEqual(decoded.tagId, tagId)
        XCTAssertEqual(decoded.androidPackage, "app.openblocker.android")
    }
    
    func testTestVector2() throws {
        let tagId = try OpenBlockerFormat.hexToBytes("f47ac10b58cc4372a5670e02b2c3d479")
        let data = OpenBlockerFormat.TagData(tagId: tagId, androidPackage: nil)
        
        let encoded = OpenBlockerFormat.encode(data)
        
        XCTAssertTrue(encoded.count < 144)
        
        let decoded = try OpenBlockerFormat.decode(encoded)
        XCTAssertEqual(decoded.tagId, tagId)
        XCTAssertNil(decoded.androidPackage)
    }
    
    func testEncodeExactBytes() throws {
        let tagId = try OpenBlockerFormat.hexToBytes("550e8400e29b41d4a716446655440000")
        let data = OpenBlockerFormat.TagData(
            tagId: tagId,
            androidPackage: "app.openblocker.android"
        )
        
        let encoded = OpenBlockerFormat.encode(data)
        
        let flags1 = encoded[0]
        XCTAssertEqual(flags1 & 0x07, 0x04)
        
        XCTAssertEqual(encoded[1], 19)
        
        XCTAssertEqual(encoded[2], 17)
        
        let type1 = String(data: encoded[3..<22], encoding: .utf8)
        XCTAssertEqual(type1, "openblocker.org:tag")
        
        XCTAssertEqual(encoded[22], 0x01)
        
        let extractedId = encoded[23..<39]
        XCTAssertEqual(Data(extractedId), tagId)
    }
    
    func testQREncoding() throws {
        let tagId = try OpenBlockerFormat.hexToBytes("550e8400e29b41d4a716446655440000")
        let data = OpenBlockerFormat.TagData(tagId: tagId)
        
        let qrString = OpenBlockerFormat.encodeForQR(data)
        XCTAssertEqual(qrString, "openblocker://tag/v1/550e8400e29b41d4a716446655440000")
        
        let decoded = try OpenBlockerFormat.decodeFromQR(qrString)
        XCTAssertEqual(decoded.tagId, tagId)
    }
    
    func testBytesToHex() {
        let data = Data([0x04, 0x12, 0x34, 0x56, 0xab, 0xcd, 0xef])
        XCTAssertEqual(OpenBlockerFormat.bytesToHex(data), "04123456abcdef")
    }
    
    func testHexToBytes() throws {
        let hex = "04123456abcdef"
        let data = try OpenBlockerFormat.hexToBytes(hex)
        XCTAssertEqual(data, Data([0x04, 0x12, 0x34, 0x56, 0xab, 0xcd, 0xef]))
    }
}
