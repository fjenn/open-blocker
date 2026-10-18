// Camera scanner adapted from Foqos (MIT, (c) 2024 Ali Waseem): Foqos/Components/Strategy/QRCodeScanner.swift
// Uses AVCaptureMetadataOutput instead of the CodeScanner package.

import AVFoundation
import SwiftUI

struct QRScannerView: View {
    var onCode: (String) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            #if targetEnvironment(simulator)
            SimulatorQRFallback(onCode: onCode)
            #else
            QRCameraPreview(onCode: onCode)
                .ignoresSafeArea()
            Viewfinder()
            #endif
            
            VStack {
                ZStack {
                    Text("Scan your QR key")
                        .textStyle(.headline)
                        .foregroundColor(.white)
                    HStack {
                        Spacer()
                        Button(action: onCancel) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: Metrics.headerButton, height: Metrics.headerButton)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .accessibilityLabel("Cancel")
                    }
                }
                .padding(.horizontal, Space.margin)
                .padding(.top, Space.l)
                Spacer()
            }
        }
        .environment(\.colorScheme, .dark)
    }
}

/// Four rounded corner brackets around the scan area.
private struct Viewfinder: View {
    var body: some View {
        VStack(spacing: Space.xl) {
            CornerBrackets()
                .stroke(Color.white.opacity(0.95), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: 250, height: 250)
            Text("Fit the code inside the frame.")
                .textStyle(.subhead)
                .foregroundColor(.white.opacity(0.8))
        }
        .allowsHitTesting(false)
    }
}

private struct CornerBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let arm: CGFloat = 44
        let r: CGFloat = 28
        var path = Path()
        for (corner, dx, dy) in [
            (CGPoint(x: rect.minX, y: rect.minY), 1.0, 1.0),
            (CGPoint(x: rect.maxX, y: rect.minY), -1.0, 1.0),
            (CGPoint(x: rect.maxX, y: rect.maxY), -1.0, -1.0),
            (CGPoint(x: rect.minX, y: rect.maxY), 1.0, -1.0)
        ] {
            path.move(to: CGPoint(x: corner.x, y: corner.y + dy * arm))
            path.addLine(to: CGPoint(x: corner.x, y: corner.y + dy * r))
            path.addQuadCurve(to: CGPoint(x: corner.x + dx * r, y: corner.y), control: corner)
            path.addLine(to: CGPoint(x: corner.x + dx * arm, y: corner.y))
        }
        return path
    }
}

#if targetEnvironment(simulator)
private struct SimulatorQRFallback: View {
    var onCode: (String) -> Void
    @State private var payload = ""
    
    var body: some View {
        VStack(spacing: Space.m) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 54, weight: .light))
                .foregroundColor(.white.opacity(0.8))
            Text("The simulator has no camera. Paste an Open Blocker QR payload to test matching.")
                .textStyle(.subhead)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Space.xl)
            TextField("openblocker://tag/v1/...", text: $payload)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundColor(.white)
                .padding(.horizontal, Space.m)
                .frame(minHeight: 52)
                .background(RoundedRectangle(cornerRadius: Radius.input, style: .continuous).fill(Color.white.opacity(0.12)))
                .padding(.horizontal, Space.xl)
            Button {
                let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { onCode(trimmed) }
            } label: {
                Text("Use payload")
                    .textStyle(.button)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
                    .background(Capsule(style: .continuous).fill(Color.white))
            }
            .padding(.horizontal, Space.xxxl)
        }
    }
}
#endif

#if !targetEnvironment(simulator)
private struct QRCameraPreview: UIViewControllerRepresentable {
    var onCode: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRCameraViewController {
        let controller = QRCameraViewController()
        controller.onCode = onCode
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRCameraViewController, context: Context) {
        uiViewController.onCode = onCode
    }
}

final class QRCameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    
    private let session = AVCaptureSession()
    private var preview: AVCaptureVideoPreviewLayer?
    private var handled = false
    private let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        requestCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = view.bounds
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    /// The scanner only opens after Permissions granted the camera.
    private func requestCamera() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            startSession()
        } else {
            statusLabel.text = "Camera is off for Open Blocker."
        }
    }
    
    private func startSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                ?? AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            statusLabel.text = "Could not open the camera."
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            statusLabel.text = "Could not read QR codes."
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        // QR keys plus common barcodes (barcode keys).
        let wanted: [AVMetadataObject.ObjectType] = [.qr, .ean13, .ean8, .upce, .code128, .code39, .code93, .itf14, .dataMatrix, .pdf417]
        output.metadataObjectTypes = wanted.filter { output.availableMetadataObjectTypes.contains($0) }
        session.commitConfiguration()
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
        preview = layer
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !handled,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue,
              !value.isEmpty
        else { return }
        handled = true
        session.stopRunning()
        onCode?(value)
    }
}
#endif
