// Adapted from TapBack (MIT, (c) 2026 SarahUniverse): TapBack/Services/NFCScannerProtocol.swift, CoreNFCScanner.swift, MockNFCScanner.swift

import Foundation
#if !targetEnvironment(simulator)
import CoreNFC
#endif

protocol NFCScannerProtocol {
    func scan(keyMatcher: ((ScannedKey) -> Bool)?) async throws -> ScannedKey
}

enum NFCScanError: Error, Equatable, LocalizedError {
    case unavailable
    case sessionTimeout
    case userCancelled
    case readFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "NFC is not available on this device."
        case .sessionTimeout:
            return "NFC scan timed out."
        case .userCancelled:
            return "Scan cancelled."
        case .readFailed(let message):
            return message
        }
    }
}

#if DEBUG || targetEnvironment(simulator)
final class MockNFCScanner: NFCScannerProtocol {
    /// Stable 7-byte UID used by the simulator mock and the demo Desk Key.
    static let defaultUID = Data([0x04, 0xa1, 0xb2, 0xc3, 0xd4, 0xe5, 0xf6])
    
    var results: [Result<ScannedKey, NFCScanError>]
    var scanDelay: TimeInterval
    private(set) var scanCallCount = 0
    
    init(
        results: [Result<ScannedKey, NFCScanError>] = [
            .success(.card(uid: MockNFCScanner.defaultUID))
        ],
        scanDelay: TimeInterval = 0
    ) {
        self.results = results
        self.scanDelay = scanDelay
    }
    
    convenience init(behavior: Behavior, scanDelay: TimeInterval = 0) {
        switch behavior {
        case .success(let key):
            self.init(results: [.success(key)], scanDelay: scanDelay)
        case .failure(let error):
            self.init(results: [.failure(error)], scanDelay: scanDelay)
        }
    }
    
    enum Behavior {
        case success(ScannedKey)
        case failure(NFCScanError)
    }
    
    func scan(keyMatcher: ((ScannedKey) -> Bool)? = nil) async throws -> ScannedKey {
        scanCallCount += 1
        if scanDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(scanDelay * 1_000_000_000))
        }
        guard !results.isEmpty else {
            throw NFCScanError.readFailed("Mock NFC scanner has no results")
        }
        let index = min(scanCallCount - 1, results.count - 1)
        guard let keyMatcher else { return try results[index].get() }
        // Like the real reader: unknown tags keep the session polling
        // ("Ready to scan"); only a matching tag completes it.
        for result in results[index...] {
            let key = try result.get()
            if keyMatcher(key) { return key }
            rejectedCount += 1
        }
        throw NFCScanError.userCancelled
    }
    
    /// Tags the matcher rejected (the session kept polling instead of finishing).
    private(set) var rejectedCount = 0
    
}
#endif

#if !targetEnvironment(simulator)
final class CoreNFCScanner: NSObject, NFCScannerProtocol {
    private var session: NFCTagReaderSession?
    private var scanDelegate: ScanDelegate?
    
    func scan(keyMatcher: ((ScannedKey) -> Bool)? = nil) async throws -> ScannedKey {
        guard NFCNDEFReaderSession.readingAvailable else {
            throw NFCScanError.unavailable
        }
        
        defer {
            self.session = nil
            self.scanDelegate = nil
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = ScanDelegate(continuation: continuation, keyMatcher: keyMatcher)
            self.scanDelegate = delegate
            
            let newSession = NFCTagReaderSession(
                pollingOption: [.iso14443, .iso15693],
                delegate: delegate,
                queue: nil
            )
            guard let newSession else {
                continuation.resume(throwing: NFCScanError.unavailable)
                return
            }
            delegate.session = newSession
            self.session = newSession
            newSession.alertMessage = "Hold the top of your iPhone near your key."
            newSession.begin()
        }
    }
}

private final class ScanDelegate: NSObject, NFCTagReaderSessionDelegate {
    private var continuation: CheckedContinuation<ScannedKey, Error>?
    private let keyMatcher: ((ScannedKey) -> Bool)?
    weak var session: NFCTagReaderSession?
    
    init(continuation: CheckedContinuation<ScannedKey, Error>, keyMatcher: ((ScannedKey) -> Bool)?) {
        self.continuation = continuation
        self.keyMatcher = keyMatcher
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        guard let continuation else { return }
        self.continuation = nil
        
        if let readerError = error as? NFCReaderError {
            switch readerError.code {
            case .readerSessionInvalidationErrorUserCanceled:
                continuation.resume(throwing: NFCScanError.userCancelled)
            case .readerSessionInvalidationErrorSessionTimeout:
                continuation.resume(throwing: NFCScanError.sessionTimeout)
            default:
                continuation.resume(throwing: NFCScanError.readFailed(readerError.localizedDescription))
            }
        } else {
            continuation.resume(throwing: NFCScanError.readFailed(error.localizedDescription))
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let continuation, let tag = tags.first else { return }
        
        session.connect(to: tag) { error in
            if let error {
                session.invalidate(errorMessage: "Connection failed")
                self.continuation = nil
                continuation.resume(throwing: NFCScanError.readFailed(error.localizedDescription))
                return
            }
            
            guard let uid = Self.getUID(for: tag) else {
                session.invalidate(errorMessage: "Could not read tag")
                self.continuation = nil
                continuation.resume(throwing: NFCScanError.readFailed("Could not read tag identifier"))
                return
            }
            
            Self.readOpenBlockerID(from: tag) { id in
                let scannedKey: ScannedKey = if let id {
                    .openBlocker(id: id, uid: uid)
                } else {
                    .card(uid: uid)
                }
                
                // Check if we have a matcher and if the key matches
                if let matcher = self.keyMatcher {
                    if matcher(scannedKey) {
                        // Match found - success!
                        session.alertMessage = "Done"
                        session.invalidate()
                        self.continuation = nil
                        continuation.resume(returning: scannedKey)
                    } else {
                        // No match - restart polling to scan another tag
                        session.alertMessage = "Unknown key. Try another."
                        session.restartPolling()
                    }
                } else {
                    // No matcher - accept any tag (registration mode)
                    session.alertMessage = "Done"
                    session.invalidate()
                    self.continuation = nil
                    continuation.resume(returning: scannedKey)
                }
            }
        }
    }
    
    private static func getUID(for tag: NFCTag) -> Data? {
        switch tag {
        case .miFare(let t):
            return t.identifier
        case .iso7816(let t):
            return t.identifier
        case .iso15693(let t):
            return t.identifier
        case .feliCa(let t):
            return t.currentIDm
        @unknown default:
            return nil
        }
    }
    
    private static func readOpenBlockerID(from tag: NFCTag, completion: @escaping (Data?) -> Void) {
        switch tag {
        case .miFare(let mifareTag):
            mifareTag.readNDEF { message, _ in
                completion(openBlockerID(message))
            }
        case .iso15693(let isoTag):
            isoTag.readNDEF { message, _ in
                completion(openBlockerID(message))
            }
        default:
            completion(nil)
        }
    }
    
    private static func openBlockerID(_ message: NFCNDEFMessage?) -> Data? {
        guard let message else { return nil }
        for record in message.records where record.typeNameFormat == .nfcExternal {
            let type = String(decoding: record.type, as: UTF8.self)
            if type == OpenBlockerFormat.TYPE_EXTERNAL,
               record.payload.count >= 17,
               record.payload.first == OpenBlockerFormat.VERSION {
                return record.payload.subdata(in: 1..<17)
            }
        }
        return nil
    }
}
#endif

extension NFCScannerProtocol {
    /// Accepts any tag (key registration).
    func scan() async throws -> ScannedKey {
        try await scan(keyMatcher: nil)
    }
}

extension KeyRegistration {
    /// Sticker setup is one scan. The key is saved by chip UID, so nothing is written to the tag.
    static func registerSticker(using scanner: NFCScannerProtocol) async throws -> String? {
        nfcUIDHex(from: try await scanner.scan())
    }
}
