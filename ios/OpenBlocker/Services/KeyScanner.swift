import Foundation

enum KeyScanner {
    enum Route: Equatable {
        case none
        case nfc
        case qr
        case choose
    }
    
    static func route(for keys: [BlockKey]) -> Route {
        let hasNFC = keys.contains { $0.kind == .openBlockerTag || $0.kind == .card }
        let hasCode = keys.contains { $0.kind == .qr || $0.kind == .barcode }
        switch (hasNFC, hasCode) {
        case (false, false):
            return .none
        case (true, false):
            return .nfc
        case (false, true):
            return .qr
        case (true, true):
            return .choose
        }
    }
    
    static func scannedKey(fromCode payload: String) -> ScannedKey {
        if payload.hasPrefix("openblocker://") {
            return .qr(payload: KeyRegistration.canonicalizeQR(payload))
        }
        return .barcode(payload: payload)
    }
}
