import UIKit
import Photos
import PhotosUI

extension MediaPickerMenu {
    /// Returns an action for picking photos from the device's Photos library.
    ///
    /// - note: Use `PhotosPickerAsset.loadImage(_:)` to retrieve an image from the result.
    func makePhotosAction(delegate: DevicePhotosPickerDelegate) -> UIAction {
        UIAction(
            title: Strings.pickFromPhotosLibrary,
            image: UIImage(systemName: "photo.on.rectangle.angled"),
            attributes: [],
            handler: { _ in showPhotosPicker(delegate: delegate) }
        )
    }

    func showPhotosPicker(delegate: DevicePhotosPickerDelegate) {
        guard let presentingViewController else { return }
        PhotosPickerPresenter.present(
            from: presentingViewController,
            filter: filter,
            isMultipleSelectionEnabled: isMultipleSelectionEnabled,
            delegate: delegate
        )
    }
}

private enum Strings {
    static let pickFromPhotosLibrary = NSLocalizedString("mediaPicker.pickFromPhotosLibrary", value: "Choose from Device", comment: "The name of the action in the context menu")
}
