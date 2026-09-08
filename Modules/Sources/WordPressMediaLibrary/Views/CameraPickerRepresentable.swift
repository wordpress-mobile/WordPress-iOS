import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CameraPickerRepresentable: UIViewControllerRepresentable {
    enum Mode { case photo, video }
    let mode: Mode
    let onPicked: (UploadSource) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.mediaTypes = [
            mode == .photo ? UTType.image.identifier : UTType.movie.identifier
        ]
        if mode == .video {
            controller.videoQuality = .typeHigh
        }
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerRepresentable

        init(parent: CameraPickerRepresentable) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            picker.dismiss(animated: true)
            switch parent.mode {
            case .photo:
                if let image = info[.originalImage] as? UIImage {
                    parent.onPicked(.cameraImage(image, capturedAt: Date()))
                } else {
                    parent.onCancel()
                }
            case .video:
                if let url = info[.mediaURL] as? URL {
                    parent.onPicked(.cameraVideo(url, capturedAt: Date()))
                } else {
                    parent.onCancel()
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            parent.onCancel()
        }
    }
}
