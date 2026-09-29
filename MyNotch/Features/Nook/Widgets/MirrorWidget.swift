import AVFoundation
import SwiftUI

struct MirrorWidget: View {
    private enum CameraState {
        case starting
        case running(MirrorCamera)
        case failed(String)
    }

    @State private var cameraState = CameraState.starting

    var body: some View {
        Group {
            switch cameraState {
            case .starting:
                Color.white.opacity(0.06)
            case .running(let camera):
                CameraPreview(session: camera.session)
            case .failed(let message):
                WidgetMessage(systemImage: "video.slash", message: message)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.vertical, 8)
        .task { await startCamera() }
        .onDisappear(perform: stopCamera)
    }

    private func startCamera() async {
        let camera = MirrorCamera()
        do {
            try await camera.start()
            cameraState = .running(camera)
        } catch MirrorCameraError.accessDenied {
            cameraState = .failed("Allow camera access in System Settings")
        } catch {
            cameraState = .failed("Camera unavailable")
        }
    }

    /// The PRD requires the camera to be released the moment the notch closes, never left running.
    private func stopCamera() {
        if case .running(let camera) = cameraState {
            camera.stop()
        }
        cameraState = .starting
    }
}

private struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer.connection?.isVideoMirrored = true
        view.layer = previewLayer
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
