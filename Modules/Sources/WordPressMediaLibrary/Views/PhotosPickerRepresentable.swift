import PhotosUI
import SwiftUI

struct PhotosPickerRepresentable: UIViewControllerRepresentable {
    let onPicked: ([UploadSource]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 0
        config.preferredAssetRepresentationMode = .current
        let controller = PHPickerViewController(configuration: config)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotosPickerRepresentable

        init(parent: PhotosPickerRepresentable) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else {
                parent.onCancel()
                return
            }
            let sources: [UploadSource] = results.map { result in
                let provider = result.itemProvider
                let suggested = provider.suggestedName
                let hintUTI =
                    provider.registeredContentTypes(conformingTo: .movie).first
                    ?? provider.registeredContentTypes(conformingTo: .image).first
                    ?? .item
                return .photoLibrary(itemProvider: provider, suggestedName: suggested, hint: hintUTI)
            }
            parent.onPicked(sources)
        }
    }
}
