import UIKit
import PhotosUI

extension MediaPickerMenu {
    /// Returns an action for picking photos from the device's Photos library.
    ///
    /// - note: Use `PHPickerResult.loadImage(for:)` to retrieve an image from the result.
    func makePhotosAction(delegate: PHPickerViewControllerDelegate) -> UIAction {
        UIAction(
            title: Strings.pickFromPhotosLibrary,
            image: UIImage(systemName: "photo.on.rectangle.angled"),
            attributes: [],
            handler: { _ in showPhotosPicker(delegate: delegate) }
        )
    }

    func showPhotosPicker(delegate: PHPickerViewControllerDelegate) {
        var configuration = PHPickerConfiguration()
        configuration.preferredAssetRepresentationMode = .current
        if let filter {
            switch filter {
            case .images:
                configuration.filter = .images
            case .videos:
                configuration.filter = .videos
            }
        }
        if isMultipleSelectionEnabled {
            configuration.selectionLimit = 0
            configuration.selection = .ordered
        }
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = delegate
        presentingViewController?.present(picker, animated: true)
    }
}

private enum Strings {
    static let pickFromPhotosLibrary = NSLocalizedString("mediaPicker.pickFromPhotosLibrary", value: "Choose from Device", comment: "The name of the action in the context menu")
}
