import Photos
import PhotosUI

final class MediaPickerMenuController: NSObject {
    var onSelection: ((MediaPickerSelection) -> Void)?

    fileprivate func didSelect(_ items: [MediaPickerItem], source: MediaPickerSource) {
        let selection = MediaPickerSelection(items: items, source: source)
        onSelection?(selection)
    }
}

extension MediaPickerMenuController: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.presentingViewController?.dismiss(animated: true) {
            if !results.isEmpty {
                self.didSelect(results.map { MediaPickerItem.pickerResult($0) }, source: .photos)
            }
        }
    }
}

extension MediaPickerMenuController: ImagePickerControllerDelegate {
    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.presentingViewController?.dismiss(animated: true) {
            if let image = info[.originalImage] as? UIImage {
                self.didSelect([.image(image)], source: .camera)
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
