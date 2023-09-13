import UIKit
import Photos
import PhotosUI

final class MediaPickerController: PHPickerViewControllerDelegate {
    let blog: Blog

    init(blog: Blog) {
        self.blog = blog
    }

    func makeMenu(for viewController: UIViewController) -> UIMenu {
        let menu = MediaPickerMenu(viewController: viewController, isMultipleSelectionEnabled: true)
        var actions: [UIAction] = [
            menu.makePhotosAction(delegate: self),
            //                mediaMenu.makeCameraAction(delegate: self),
            //                mediaMenu.makeMediaAction(blog: blog, delegate: self)
        ]
        return UIMenu(children: actions)
    }

    // MARK: - PHPickerViewControllerDelegate

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.presentingViewController?.dismiss(animated: true)

        for result in results {
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.deviceLibrary), selectionMethod: .fullScreenPicker)
            MediaCoordinator.shared.addMedia(from: result.itemProvider, to: blog, analyticsInfo: info)
        }
    }
}
