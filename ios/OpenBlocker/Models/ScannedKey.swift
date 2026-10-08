import Foundation

enum ScannedKey: Equatable {
    case openBlocker(id: Data, uid: Data)
    case card(uid: Data)
    case qr(payload: String)
}
