import UIKit
import Gridicons

struct MediaPickerMenu {
    static func makePickFromPhotosAction(_ handler: @escaping () -> Void) -> UIAction {
        UIAction(
            title: Strings.pickFromPhotosLibrary,
            image: UIImage(systemName: "photo.on.rectangle.angled"),
            attributes: [],
            handler: { _ in handler() }
        )
    }

    static func makeTakePhotoAction(_ handler: @escaping () -> Void) -> UIAction {
        UIAction(
            title: Strings.takePhoto,
            image: UIImage(systemName: "camera"),
            attributes: [],
            handler: { _ in handler() }
        )
    }

    static func makePickFromMediaAction(_ handler: @escaping () -> Void) -> UIAction {
        UIAction(
            title: Strings.pickFromMedia,
            image: UIImage(systemName: "photo.stack"),
            attributes: [],
            handler: { _ in handler() }
        )
    }
}

private enum Strings {
    static let pickFromPhotosLibrary = NSLocalizedString("mediaPicker.pickFromPhotosLibrary", value: "Choose from Device", comment: "The name of the action in the context menu")
    static let takePhoto = NSLocalizedString("mediaPicker.takePhoto", value: "Take Photo", comment: "The name of the action in the context menu")
    static let pickFromMedia = NSLocalizedString("mediaPicker.pickFromMediaLibrary", value: "Choose from Media", comment: "The name of the action in the context menu (user's WordPress Media Library")
}
