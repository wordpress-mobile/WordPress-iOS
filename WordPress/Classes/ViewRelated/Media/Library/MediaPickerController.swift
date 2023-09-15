import UIKit
import Photos
import PhotosUI

final class MediaPickerController: NSObject, PHPickerViewControllerDelegate, ImagePickerControllerDelegate, StockPhotosPickerDelegate, TenorPickerDelegate, UIDocumentPickerDelegate {
    let blog: Blog
    let coordinator: MediaCoordinator

    init(blog: Blog, coordinator: MediaCoordinator) {
        self.blog = blog
        self.coordinator = coordinator
    }

    func makeMenu(for viewController: UIViewController) -> UIMenu {
        let menu = MediaPickerMenu(viewController: viewController, isMultipleSelectionEnabled: true)
        return UIMenu(options: [.displayInline], children: [
            UIMenu(options: [.displayInline], children: [
                menu.makePhotosAction(delegate: self),
            ]),
            UIMenu(options: [.displayInline], children: [
                menu.makeCameraAction(delegate: self),
                makeDocumentPickerAction(from: viewController)
            ]),
            UIMenu(options: [.displayInline], children: [
                menu.makeStockPhotos(blog: blog, delegate: self),
                menu.makeFreeGIFAction(blog: blog, delegate: self)
            ])
        ])
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

    // MARK: - Document Picker

    private func makeDocumentPickerAction(from presentingViewController: UIViewController) -> UIAction {
        UIAction(
            title: Strings.pickFromOtherApps,
            image: UIImage(systemName: "folder"),
            attributes: [],
            handler: { [weak presentingViewController, blog] _ in
                let allowedFileTypes = blog.allowedTypeIdentifiers.compactMap(UTType.init)
                let viewController = UIDocumentPickerViewController(forOpeningContentTypes: allowedFileTypes, asCopy: true)
                viewController.delegate = self
                viewController.allowsMultipleSelection = true
                presentingViewController?.present(viewController, animated: true)
            }
        )
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for documentURL in urls as [NSURL] {
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.otherApps), selectionMethod: .documentPicker)
            coordinator.addMedia(from: documentURL, to: blog, analyticsInfo: info)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.presentingViewController?.dismiss(animated: true)
    }
}

private enum Strings {
    static let pickFromOtherApps = NSLocalizedString("mediaPicker.pickFromOtherApps", value: "Other Files", comment: "The name of the action in the context menu for selecting photos from other apps (Files app)")
}
