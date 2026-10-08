import Foundation

enum KeyRegistration {
    static let rotatingCardMessage =
        "Many transit cards, hotel keys and work badges work. Test yours. Many bank cards and phone wallets show a new ID on each tap, so they can't be used."
    
    enum CardConfirm: Equatable {
        case match(uidHex: String)
        case rotating
    }
    
    static func nfcUIDHex(from scanned: ScannedKey) -> String? {
        switch scanned {
        case .card(let uid), .openBlocker(_, let uid):
            return uid.hexString
        case .qr:
            return nil
        }
    }
    
    static func confirmCard(firstUID: String, secondUID: String) -> CardConfirm {
        if firstUID == secondUID {
            return .match(uidHex: firstUID)
        }
        return .rotating
    }
    
    static func canonicalizeQR(_ payload: String) -> String {
        if let data = try? OpenBlockerFormat.decodeFromQR(payload) {
            return OpenBlockerFormat.encodeForQR(data)
        }
        return payload
    }
    
    static func qrPayloadsMatch(_ stored: String, _ scanned: String) -> Bool {
        canonicalizeQR(stored) == canonicalizeQR(scanned)
    }
}
