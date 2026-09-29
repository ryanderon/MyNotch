import AVFoundation

enum MirrorCameraError: Error {
    case accessDenied
    case noCamera
    case cannotAddInput
}

/// Front camera for the Mirror widget. Created when the widget appears and released when it disappears,
/// so no capture session ever outlives the open notch. Uses the 640x480 preset to keep CPU and memory low.
/// All session work runs on one private serial queue, as AVFoundation recommends, which is why this type
/// is not main-actor isolated.
nonisolated final class MirrorCamera: @unchecked Sendable {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "MyNotch.MirrorCamera", qos: .userInitiated)

    func start() async throws {
        guard await Self.hasAccess() else { throw MirrorCameraError.accessDenied }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    try Self.configure(self.session)
                    self.session.startRunning()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func stop() {
        sessionQueue.async {
            self.session.stopRunning()
            self.session.inputs.forEach { self.session.removeInput($0) }
        }
    }

    private static func hasAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: true
        case .notDetermined: await AVCaptureDevice.requestAccess(for: .video)
        default: false
        }
    }

    private static func configure(_ session: AVCaptureSession) throws {
        guard session.inputs.isEmpty else { return }
        guard let device = AVCaptureDevice.default(for: .video) else { throw MirrorCameraError.noCamera }
        let input = try AVCaptureDeviceInput(device: device)
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        if session.canSetSessionPreset(.vga640x480) {
            session.sessionPreset = .vga640x480
        }
        guard session.canAddInput(input) else { throw MirrorCameraError.cannotAddInput }
        session.addInput(input)
    }
}
