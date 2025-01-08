import Photos
import PhotosUI

final class MediaPickerMenuController: NSObject {
    var onSelection: (([MediaPickerSelection]) -> Void)?
}

extension MediaPickerMenuController: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.presentingViewController?.dismiss(animated: true) {
            if !results.isEmpty {
                self.onSelection?(results.map { MediaPickerSelection.phPickerResult($0) })
            }
        }
    }
}

extension MediaPickerMenuController: SiteMediaPickerViewControllerDelegate {
    func siteMediaPickerViewController(_ viewController: SiteMediaPickerViewController, didFinishWithSelection selection: [Media]) {
        // TODO:
    }
}

extension MediaPickerMenuController: ImagePlaygroundPickerDelegate {
    func imagePlaygroundViewController(_ viewController: UIViewController, didCreateImageAt imageURL: URL) {
        // TODO:
    }
}
