import Foundation

struct BlockKey: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    let kind: Kind
    let secret: String
    let addedAt: Date
    
    enum Kind: String, Codable {
        case openBlockerTag
        case card
        case qr
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        kind: Kind,
        secret: String,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.secret = secret
        self.addedAt = addedAt
    }
    
    var icon: String {
        switch kind {
        case .openBlockerTag:
            return "wave.3.right"
        case .card:
            return "creditcard"
        case .qr:
            return "qrcode"
        }
    }
    
    func matches(_ scannedKey: ScannedKey) -> Bool {
        switch (kind, scannedKey) {
        case (.openBlockerTag, .openBlocker(let id, let uid)):
            return secret == id.hexString || secret == uid.hexString
        case (.openBlockerTag, .card(let uid)):
            return secret == uid.hexString
        case (.card, .card(let uid)):
            return secret == uid.hexString
        case (.card, .openBlocker(_, let uid)):
            return secret == uid.hexString
        case (.qr, .qr(let payload)):
            return KeyRegistration.qrPayloadsMatch(secret, payload)
        default:
            return false
        }
    }
}

extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
