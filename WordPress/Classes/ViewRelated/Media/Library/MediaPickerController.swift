import UIKit
import Photos
import PhotosUI

final class MediaPickerController: PHPickerViewControllerDelegate, ImagePickerControllerDelegate, StockPhotosPickerDelegate, TenorPickerDelegate {
    let blog: Blog
    let coordinator: MediaCoordinator

    init(blog: Blog, coordinator: MediaCoordinator) {
        self.blog = blog
        self.coordinator = coordinator
    }

    func makeMenu(for viewController: UIViewController) -> UIMenu {
        let menu = MediaPickerMenu(viewController: viewController, isMultipleSelectionEnabled: true)
        let actions: [UIAction] = [
            menu.makePhotosAction(delegate: self),
            menu.makeCameraAction(delegate: self),
            menu.makeStockPhotos(blog: blog, delegate: self),
            menu.makeFreeGIFAction(blog: blog, delegate: self)
        ]
        return UIMenu(children: actions)
    }

    // MARK: - PHPickerViewControllerDelegate

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.presentingViewController?.dismiss(animated: true)

        for result in results {
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.deviceLibrary), selectionMethod: .fullScreenPicker)
            coordinator.addMedia(from: result.itemProvider, to: blog, analyticsInfo: info)
        }
    }

    // MARK: - ImagePickerControllerDelegate

    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.presentingViewController?.dismiss(animated: true)

        func addAsset(from asset: ExportableAsset) {
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.camera), selectionMethod: .fullScreenPicker)
            coordinator.addMedia(from: asset, to: blog, analyticsInfo: info)
        }
        guard let mediaType = info[.mediaType] as? String else {
            return
        }
        switch mediaType {
        case UTType.image.identifier:
            if let image = info[.originalImage] as? UIImage {
                addAsset(from: image)
            }
        case UTType.movie.identifier:
            if let videoURL = info[.mediaURL] as? URL {
                addAsset(from: videoURL as NSURL)
            }
        default:
            break
        }
    }

    // MARK: - StockPhotosPickerDelegate

    func stockPhotosPicker(_ picker: StockPhotosPicker, didFinishPicking assets: [StockPhotosMedia]) {
        for asset in assets {
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.stockPhotos), selectionMethod: .fullScreenPicker)
            coordinator.addMedia(from: asset, to: blog, analyticsInfo: info)
            WPAnalytics.track(.stockMediaUploaded)
        }
    }

    // MARK: - TenorPickerDelegate

    func tenorPicker(_ picker: TenorPicker, didFinishPicking assets: [TenorMedia]) {
        for asset in assets {
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.tenor), selectionMethod: .fullScreenPicker)
            coordinator.addMedia(from: asset, to: blog, analyticsInfo: info)
            WPAnalytics.track(.tenorUploaded)
        }
    }
}
