import Photos
import PhotosUI

final class MediaPickerMenuController: NSObject {
    var onSelection: ((MediaPickerSelection) -> Void)?

    fileprivate func didSelect(_ items: [MediaPickerItem], source: String) {
        let selection = MediaPickerSelection(items: items, source: source)
        DispatchQueue.main.async {
            self.onSelection?(selection)
        }
    }
}

extension MediaPickerMenuController: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.presentingViewController?.dismiss(animated: true)
        if !results.isEmpty {
            self.didSelect(results.map(MediaPickerItem.pickerResult), source: "apple_photos")
        }
    }
}

extension MediaPickerMenuController: ImagePickerControllerDelegate {
    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.presentingViewController?.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            self.didSelect([.image(image)], source: "camera")
        }
    }
}

extension MediaPickerMenuController: SiteMediaPickerViewControllerDelegate {
    func siteMediaPickerViewController(_ viewController: SiteMediaPickerViewController, didFinishWithSelection selection: [Media]) {
        viewController.presentingViewController?.dismiss(animated: true)
        if !selection.isEmpty {
            self.didSelect(selection.map(MediaPickerItem.media), source: "site_media")
        }
    }
}

extension MediaPickerMenuController: ImagePlaygroundPickerDelegate {
    func imagePlaygroundViewController(_ viewController: UIViewController, didCreateImageAt imageURL: URL) {

        viewController.presentingViewController?.dismiss(animated: true)
        if let data = try? Data(contentsOf: imageURL), let image = UIImage(data: data) {
            self.didSelect([.image(image)], source: "image_playground")
        } else {
            wpAssertionFailure("failed to read the image created by ImagePlayground")
        }
    }
}

extension MediaPickerMenuController: ExternalMediaPickerViewDelegate {
    func externalMediaPickerViewController(_ viewController: ExternalMediaPickerViewController, didFinishWithSelection selection: [ExternalMediaAsset]) {
        viewController.presentingViewController?.dismiss(animated: true)
        if !selection.isEmpty {
            let source = viewController.source == .tenor ? "free_gifs" : "free_photos"
            self.didSelect(selection.map(MediaPickerItem.external), source: source)
        }
    }
}
