// Adapted from TapBack (MIT, (c) 2026 SarahUniverse): TapBack/Services/NFCScannerProtocol.swift, CoreNFCScanner.swift, MockNFCScanner.swift
// NDEF write session adapted from Foqos (MIT, (c) 2024 Ali Waseem): Foqos/Utils/NFCScannerUtil.swift

import Foundation
#if !targetEnvironment(simulator)
import CoreNFC
#endif

protocol NFCScannerProtocol {
    func scan() async throws -> ScannedKey
    func writeOpenBlockerRecord(tagId: Data) async throws
}

enum NFCScanError: Error, Equatable, LocalizedError {
    case unavailable
    case sessionTimeout
    case userCancelled
    case readFailed(String)
    case writeFailed(String)
    
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
        case .writeFailed(let message):
            return message
        }
    }
}

#if DEBUG || targetEnvironment(simulator)
final class MockNFCScanner: NFCScannerProtocol {
    /// Stable 7-byte UID used by the simulator mock and the demo Desk Key.
    static let defaultUID = Data([0x04, 0xa1, 0xb2, 0xc3, 0xd4, 0xe5, 0xf6])
    
    var results: [Result<ScannedKey, NFCScanError>]
    var writeError: NFCScanError?
    var scanDelay: TimeInterval
    private(set) var scanCallCount = 0
    private(set) var writeCallCount = 0
    private(set) var lastWrittenTagId: Data?
    
    init(
        results: [Result<ScannedKey, NFCScanError>] = [
            .success(.card(uid: MockNFCScanner.defaultUID))
        ],
        writeError: NFCScanError? = nil,
        scanDelay: TimeInterval = 0
    ) {
        self.results = results
        self.writeError = writeError
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
    
    func scan() async throws -> ScannedKey {
        scanCallCount += 1
        if scanDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(scanDelay * 1_000_000_000))
        }
        let index = min(scanCallCount - 1, results.count - 1)
        guard !results.isEmpty else {
            throw NFCScanError.readFailed("Mock NFC scanner has no results")
        }
        return try results[index].get()
    }
    
    func writeOpenBlockerRecord(tagId: Data) async throws {
        writeCallCount += 1
        lastWrittenTagId = tagId
        if let writeError {
            throw writeError
        }
    }
}
#endif

#if !targetEnvironment(simulator)
final class CoreNFCScanner: NSObject, NFCScannerProtocol {
    private var session: NFCTagReaderSession?
    private var writeSession: NFCNDEFReaderSession?
    private var scanDelegate: ScanDelegate?
    private var writeDelegate: WriteDelegate?
    
    func scan() async throws -> ScannedKey {
        guard NFCNDEFReaderSession.readingAvailable else {
            throw NFCScanError.unavailable
        }
        
        defer {
            self.session = nil
            self.scanDelegate = nil
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = ScanDelegate(continuation: continuation)
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
            self.session = newSession
            newSession.alertMessage = "Hold the top of your iPhone near your key."
            newSession.begin()
        }
    }
    
    func writeOpenBlockerRecord(tagId: Data) async throws {
        guard NFCNDEFReaderSession.readingAvailable else {
            throw NFCScanError.unavailable
        }
        
        defer {
            self.writeSession = nil
            self.writeDelegate = nil
        }
        
        let message = Self.openBlockerMessage(tagId: tagId)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let delegate = WriteDelegate(message: message, continuation: continuation)
            self.writeDelegate = delegate
            let session = NFCNDEFReaderSession(
                delegate: delegate,
                queue: nil,
                invalidateAfterFirstRead: false
            )
            self.writeSession = session
            session.alertMessage = "Hold your iPhone near the sticker to write Open Blocker."
            session.begin()
        }
    }
    
    static func openBlockerMessage(tagId: Data) -> NFCNDEFMessage {
        let payload = Data([OpenBlockerFormat.VERSION]) + tagId
        let record = NFCNDEFPayload(
            format: .nfcExternal,
            type: Data(OpenBlockerFormat.TYPE_EXTERNAL.utf8),
            identifier: Data(),
            payload: payload
        )
        let aar = NFCNDEFPayload(
            format: .nfcExternal,
            type: Data(OpenBlockerFormat.TYPE_AAR.utf8),
            identifier: Data(),
            payload: Data("app.openblocker.android".utf8)
        )
        return NFCNDEFMessage(records: [record, aar])
    }
}

private final class ScanDelegate: NSObject, NFCTagReaderSessionDelegate {
    private var continuation: CheckedContinuation<ScannedKey, Error>?
    
    init(continuation: CheckedContinuation<ScannedKey, Error>) {
        self.continuation = continuation
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
        self.continuation = nil
        
        session.connect(to: tag) { error in
            if let error {
                session.invalidate(errorMessage: "Connection failed")
                continuation.resume(throwing: NFCScanError.readFailed(error.localizedDescription))
                return
            }
            
            guard let uid = Self.getUID(for: tag) else {
                session.invalidate(errorMessage: "Could not read tag")
                continuation.resume(throwing: NFCScanError.readFailed("Could not read tag identifier"))
                return
            }
            
            Self.readOpenBlockerID(from: tag) { id in
                session.alertMessage = "Done"
                session.invalidate()
                if let id {
                    continuation.resume(returning: .openBlocker(id: id, uid: uid))
                } else {
                    continuation.resume(returning: .card(uid: uid))
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

private final class WriteDelegate: NSObject, NFCNDEFReaderSessionDelegate {
    private let message: NFCNDEFMessage
    private var continuation: CheckedContinuation<Void, Error>?
    
    init(message: NFCNDEFMessage, continuation: CheckedContinuation<Void, Error>) {
        self.message = message
        self.continuation = continuation
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {}
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        guard let continuation else { return }
        self.continuation = nil
        
        if let readerError = error as? NFCReaderError {
            switch readerError.code {
            case .readerSessionInvalidationErrorUserCanceled,
                 .readerSessionInvalidationErrorFirstNDEFTagRead:
                continuation.resume(throwing: NFCScanError.userCancelled)
            default:
                continuation.resume(throwing: NFCScanError.writeFailed(readerError.localizedDescription))
            }
        } else {
            continuation.resume(throwing: NFCScanError.writeFailed(error.localizedDescription))
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else { return }
        
        session.connect(to: tag) { error in
            if let error {
                session.invalidate(errorMessage: "Connection failed")
                self.finish(.failure(NFCScanError.writeFailed(error.localizedDescription)))
                return
            }
            
            tag.queryNDEFStatus { status, capacity, error in
                if let error {
                    session.invalidate(errorMessage: "Could not query tag")
                    self.finish(.failure(NFCScanError.writeFailed(error.localizedDescription)))
                    return
                }
                
                switch status {
                case .notSupported:
                    session.invalidate(errorMessage: "This tag cannot store NDEF")
                    self.finish(.failure(NFCScanError.writeFailed("Tag is not NDEF compliant")))
                case .readOnly:
                    session.invalidate(errorMessage: "This tag is read-only")
                    self.finish(.failure(NFCScanError.writeFailed("Tag is read-only")))
                case .readWrite:
                    let payloadLength = self.message.records.reduce(0) { $0 + $1.payload.count + 8 }
                    if capacity > 0, payloadLength > capacity {
                        session.invalidate(errorMessage: "Not enough space on this tag")
                        self.finish(.failure(NFCScanError.writeFailed("Tag capacity is too small")))
                        return
                    }
                    tag.writeNDEF(self.message) { error in
                        if let error {
                            session.invalidate(errorMessage: "Write failed")
                            self.finish(.failure(NFCScanError.writeFailed(error.localizedDescription)))
                        } else {
                            session.alertMessage = "Open Blocker record written"
                            session.invalidate()
                            self.finish(.success(()))
                        }
                    }
                @unknown default:
                    session.invalidate(errorMessage: "Unknown tag status")
                    self.finish(.failure(NFCScanError.writeFailed("Unknown tag status")))
                }
            }
        }
    }
    
    private func finish(_ result: Result<Void, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }
}
#endif
