import Foundation
import CryptoKit

struct OpenBlockerFormat {
    static let VERSION: UInt8 = 0x01
    static let TYPE_EXTERNAL = "openblocker.org:tag"
    static let TYPE_AAR = "android.com:pkg"
    
    private static let TNF_EXTERNAL_TYPE: UInt8 = 0x04
    private static let FLAG_MB: UInt8 = 0x80
    private static let FLAG_ME: UInt8 = 0x40
    private static let FLAG_SR: UInt8 = 0x10
    
    struct TagData {
        let version: UInt8
        let tagId: Data
        let androidPackage: String?
        
        init(version: UInt8 = VERSION, tagId: Data, androidPackage: String? = nil) {
            precondition(tagId.count == 16, "Tag ID must be exactly 16 bytes")
            precondition(version == VERSION, "Unsupported version")
            self.version = version
            self.tagId = tagId
            self.androidPackage = androidPackage
        }
    }
    
    static func generateTagId() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, 16, &bytes)
        return Data(bytes)
    }
    
    static func encode(_ data: TagData) -> Data {
        var result = Data()
        
        // Record 1: External type with tag ID
        let payload1 = Data([data.version]) + data.tagId
        let typeBytes1 = Data(TYPE_EXTERNAL.utf8)
        
        let flags1: UInt8
        if data.androidPackage == nil {
            flags1 = (FLAG_MB | FLAG_ME | FLAG_SR) | TNF_EXTERNAL_TYPE
        } else {
            flags1 = (FLAG_MB | FLAG_SR) | TNF_EXTERNAL_TYPE
        }
        
        result.append(flags1)
        result.append(UInt8(typeBytes1.count))
        result.append(UInt8(payload1.count))
        result.append(typeBytes1)
        result.append(payload1)
        
        // Record 2: Android Application Record (if specified)
        if let package = data.androidPackage {
            let payload2 = Data(package.utf8)
            let typeBytes2 = Data(TYPE_AAR.utf8)
            
            let flags2: UInt8 = (FLAG_ME | FLAG_SR) | TNF_EXTERNAL_TYPE
            
            result.append(flags2)
            result.append(UInt8(typeBytes2.count))
            result.append(UInt8(payload2.count))
            result.append(typeBytes2)
            result.append(payload2)
        }
        
        return result
    }
    
    static func decode(_ ndefMessage: Data) throws -> TagData {
        var offset = 0
        
        guard offset < ndefMessage.count else {
            throw FormatError.emptyMessage
        }
        
        let flags1 = ndefMessage[offset]
        let tnf1 = flags1 & 0x07
        let mb = (flags1 & 0x80) != 0
        let sr1 = (flags1 & 0x10) != 0
        
        guard mb else { throw FormatError.missingMBFlag }
        guard tnf1 == TNF_EXTERNAL_TYPE else { throw FormatError.invalidTNF }
        guard sr1 else { throw FormatError.expectedShortRecord }
        
        offset += 1
        
        let typeLength1 = Int(ndefMessage[offset])
        offset += 1
        
        let payloadLength1 = Int(ndefMessage[offset])
        offset += 1
        
        let typeData1 = ndefMessage[offset..<offset + typeLength1]
        let type1 = String(data: typeData1, encoding: .utf8)
        offset += typeLength1
        
        guard type1 == TYPE_EXTERNAL else { throw FormatError.invalidType }
        guard payloadLength1 == 17 else { throw FormatError.invalidPayloadLength }
        
        let version = ndefMessage[offset]
        offset += 1
        
        let tagId = ndefMessage[offset..<offset + 16]
        offset += 16
        
        var androidPackage: String? = nil
        
        if offset < ndefMessage.count {
            let flags2 = ndefMessage[offset]
            let tnf2 = flags2 & 0x07
            let me = (flags2 & 0x40) != 0
            let sr2 = (flags2 & 0x10) != 0
            
            guard me else { throw FormatError.missingMEFlag }
            guard tnf2 == TNF_EXTERNAL_TYPE else { throw FormatError.invalidTNF }
            guard sr2 else { throw FormatError.expectedShortRecord }
            
            offset += 1
            
            let typeLength2 = Int(ndefMessage[offset])
            offset += 1
            
            let payloadLength2 = Int(ndefMessage[offset])
            offset += 1
            
            let typeData2 = ndefMessage[offset..<offset + typeLength2]
            let type2 = String(data: typeData2, encoding: .utf8)
            offset += typeLength2
            
            guard type2 == TYPE_AAR else { throw FormatError.invalidType }
            
            let packageData = ndefMessage[offset..<offset + payloadLength2]
            androidPackage = String(data: packageData, encoding: .utf8)
        }
        
        return TagData(version: version, tagId: Data(tagId), androidPackage: androidPackage)
    }
    
    static func encodeForQR(_ data: TagData) -> String {
        return "openblocker://tag/v1/\(bytesToHex(data.tagId))"
    }
    
    static func decodeFromQR(_ qrString: String) throws -> TagData {
        guard qrString.starts(with: "openblocker://tag/v1/") else {
            throw FormatError.invalidQRFormat
        }
        
        let hexString = String(qrString.dropFirst("openblocker://tag/v1/".count))
        guard hexString.count == 32 else {
            throw FormatError.invalidQRFormat
        }
        
        let tagId = try hexToBytes(hexString)
        return TagData(tagId: tagId)
    }
    
    static func bytesToHex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
    
    static func hexToBytes(_ hex: String) throws -> Data {
        guard hex.count % 2 == 0 else {
            throw FormatError.invalidHex
        }
        
        var data = Data()
        var index = hex.startIndex
        
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = hex[index..<nextIndex]
            guard let byte = UInt8(byteString, radix: 16) else {
                throw FormatError.invalidHex
            }
            data.append(byte)
            index = nextIndex
        }
        
        return data
    }
    
    enum FormatError: Error, LocalizedError {
        case emptyMessage
        case missingMBFlag
        case missingMEFlag
        case invalidTNF
        case expectedShortRecord
        case invalidType
        case invalidPayloadLength
        case invalidQRFormat
        case invalidHex
        
        var errorDescription: String? {
            switch self {
            case .emptyMessage: return "Empty NDEF message"
            case .missingMBFlag: return "First record must have MB flag"
            case .missingMEFlag: return "Second record must have ME flag"
            case .invalidTNF: return "Expected external type"
            case .expectedShortRecord: return "Expected short record"
            case .invalidType: return "Invalid type string"
            case .invalidPayloadLength: return "Invalid payload length"
            case .invalidQRFormat: return "Invalid QR format"
            case .invalidHex: return "Invalid hex string"
            }
        }
    }
}
