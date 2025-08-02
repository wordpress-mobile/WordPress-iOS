import Photos
import PhotosUI
import WordPressShared
import WordPressData

final class MediaPickerMenuController: NSObject {
    var onSelection: ((MediaPickerSelection) -> Void)?

    fileprivate func didSelect(_ items: [MediaPickerItem], source: MediaPickerID) {
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
            self.didSelect(results.map(MediaPickerItem.pickerResult), source: .applePhotos)
        }
    }
}

extension MediaPickerMenuController: ImagePickerControllerDelegate {
    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.presentingViewController?.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            self.didSelect([.image(image)], source: .camera)
        }
    }
}

extension MediaPickerMenuController: SiteMediaPickerViewControllerDelegate {
    func siteMediaPickerViewController(_ viewController: SiteMediaPickerViewController, didFinishWithSelection selection: [Media]) {
        viewController.presentingViewController?.dismiss(animated: true)
        if !selection.isEmpty {
            self.didSelect(selection.map(MediaPickerItem.media), source: .siteMedia)
        }
    }
}

extension MediaPickerMenuController: ImagePlaygroundPickerDelegate {
    func imagePlaygroundViewController(_ viewController: UIViewController, didCreateImageAt imageURL: URL) {

        viewController.presentingViewController?.dismiss(animated: true)
        if let data = try? Data(contentsOf: imageURL), let image = UIImage(data: data) {
            self.didSelect([.image(image)], source: .imagePlayground)
        } else {
            wpAssertionFailure("failed to read the image created by ImagePlayground")
        }
    }
}

extension MediaPickerMenuController: ExternalMediaPickerViewDelegate {
    func externalMediaPickerViewController(_ viewController: ExternalMediaPickerViewController, didFinishWithSelection selection: [ExternalMediaAsset]) {
        viewController.presentingViewController?.dismiss(animated: true)
        if !selection.isEmpty {
            let source: MediaPickerID = viewController.source == .tenor ? .freeGIFs : .freePhotos
            self.didSelect(selection.map(MediaPickerItem.external), source: source)
        }
    }
}
