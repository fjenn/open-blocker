import SwiftUI
import CoreImage.CIFilterBuiltins

struct KeySetupScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var appState = AppState.shared
    @State private var selectedType: BlockKey.Kind = .qr
    @State private var keyName: String = ""
    @State private var generatedKeyId: String = ""
    @State private var qrImage: UIImage?
    @State private var showingSaveSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.brickCanvas
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Type selector
                        Picker("Key Type", selection: $selectedType) {
                            Text("QR Code").tag(BlockKey.Kind.qr)
                            Text("NFC Tag").tag(BlockKey.Kind.openBlockerTag)
                            Text("NFC Card").tag(BlockKey.Kind.card)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Name input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Key Name")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            TextField("e.g. My QR Code", text: $keyName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.brickCard)
                                )
                        }
                        .padding(.horizontal)
                        
                        // Type-specific content
                        Group {
                            switch selectedType {
                            case .qr:
                                QRKeySetupView(
                                    keyId: $generatedKeyId,
                                    qrImage: $qrImage
                                )
                            case .openBlockerTag:
                                NFCTagSetupView(keyId: $generatedKeyId)
                            case .card:
                                NFCCardSetupView(keyId: $generatedKeyId)
                            }
                        }
                        
                        // Save button
                        if !generatedKeyId.isEmpty && !keyName.isEmpty {
                            Button(action: saveKey) {
                                Text("Save Key")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.brickCard)
                                    )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Key Saved", isPresented: $showingSaveSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your key has been saved successfully!")
            }
        }
    }
    
    private func saveKey() {
        let key = BlockKey(
            name: keyName,
            kind: selectedType,
            secret: generatedKeyId
        )
        appState.addKey(key)
        showingSaveSuccess = true
    }
}

struct QRKeySetupView: View {
    @Binding var keyId: String
    @Binding var qrImage: UIImage?
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = qrImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
            } else {
                Button(action: generateQRCode) {
                    VStack(spacing: 12) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 60))
                        Text("Generate QR Code")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .frame(width: 250, height: 250)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.brickCard)
                    )
                }
            }
            
            Text("Save this QR code and scan it to block/unblock")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if qrImage != nil {
                ShareLink(item: Image(uiImage: qrImage!), preview: SharePreview("Open Blocker Key")) {
                    Label("Share QR Code", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private func generateQRCode() {
        let data = OpenBlockerFormat.TagData(tagId: OpenBlockerFormat.generateTagId())
        let payload = OpenBlockerFormat.encodeForQR(data)
        keyId = payload
        
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = UIImage(cgImage: cgImage)
            }
        }
    }
}

struct NFCTagSetupView: View {
    @Binding var keyId: String
    @ObservedObject var appState = AppState.shared
    @State private var isScanning = false
    @State private var status = "Ready to scan"
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wave.3.right.circle")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Write NFC Tag")
                .font(.title2.weight(.semibold))
            
            Text("Hold a blank NTAG213, NTAG215, or NTAG216 tag near your iPhone.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text(status)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button(action: registerTag) {
                Text(isScanning ? "Hold your tag..." : "Start NFC Scan")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isScanning ? Color.gray.opacity(0.5) : Color.brickCard)
                    )
            }
            .disabled(isScanning)
            .padding(.horizontal, 40)
            
            Text("Requires a physical iPhone with NFC")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
    
    private func registerTag() {
        isScanning = true
        status = "Hold the tag to the top of your iPhone..."
        Task {
            defer { isScanning = false }
            do {
                let scanned = try await appState.nfcScanner.scan()
                guard let uid = KeyRegistration.nfcUIDHex(from: scanned) else {
                    status = "That was not an NFC tag."
                    return
                }
                let tagId = OpenBlockerFormat.generateTagId()
                do {
                    try await appState.nfcScanner.writeOpenBlockerRecord(tagId: tagId)
                    status = "UID registered and Open Blocker record written."
                } catch {
                    status = "UID registered. Could not write an Open Blocker record; the sticker still works by UID."
                }
                keyId = uid
            } catch NFCScanError.userCancelled {
                status = "Scan cancelled."
            } catch {
                status = error.localizedDescription
            }
        }
    }
}

struct NFCCardSetupView: View {
    @Binding var keyId: String
    @ObservedObject var appState = AppState.shared
    @State private var firstScan: String?
    @State private var isScanning = false
    @State private var status = "Ready for first scan"
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Register NFC Card")
                .font(.title2.weight(.semibold))
            
            Text("Hold your card (transit, hotel key, work badge) near your iPhone twice to confirm it has a stable ID.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text(status)
                .font(.system(size: 14))
                .foregroundColor(statusColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button(action: scanCard) {
                Text(isScanning ? "Hold your card..." : (firstScan == nil ? "First Scan" : "Second Scan"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isScanning ? Color.gray.opacity(0.5) : Color.brickCard)
                    )
            }
            .disabled(isScanning)
            .padding(.horizontal, 40)
            
            Text(KeyRegistration.rotatingCardMessage)
                .font(.system(size: 13))
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }
    
    private var statusColor: Color {
        if keyId.isEmpty == false { return .green }
        if status == KeyRegistration.rotatingCardMessage { return .orange }
        return .secondary
    }
    
    private func scanCard() {
        isScanning = true
        Task {
            defer { isScanning = false }
            do {
                let scanned = try await appState.nfcScanner.scan()
                guard let uid = KeyRegistration.nfcUIDHex(from: scanned) else {
                    status = "That was not an NFC card."
                    return
                }
                if let first = firstScan {
                    switch KeyRegistration.confirmCard(firstUID: first, secondUID: uid) {
                    case .match(let confirmed):
                        keyId = confirmed
                        status = "Card registered successfully!"
                    case .rotating:
                        firstScan = nil
                        keyId = ""
                        status = KeyRegistration.rotatingCardMessage
                    }
                } else {
                    firstScan = uid
                    status = "First scan complete! Scan again to confirm."
                }
            } catch NFCScanError.userCancelled {
                status = "Scan cancelled."
            } catch {
                status = error.localizedDescription
            }
        }
    }
}
