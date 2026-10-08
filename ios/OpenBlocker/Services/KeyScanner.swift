import Foundation

enum KeyScanner {
    enum Route: Equatable {
        case none
        case nfc
        case qr
        case choose
    }
    
    static func route(for keys: [BlockKey]) -> Route {
        let hasNFC = keys.contains { $0.kind != .qr }
        let hasQR = keys.contains { $0.kind == .qr }
        switch (hasNFC, hasQR) {
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
    
    static func scannedKey(fromQR payload: String) -> ScannedKey {
        .qr(payload: KeyRegistration.canonicalizeQR(payload))
    }
}
