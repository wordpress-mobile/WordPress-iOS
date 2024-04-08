import UIKit
import Photos
import PhotosUI

final class SiteMediaAddMediaMenuController: NSObject, PHPickerViewControllerDelegate, ImagePickerControllerDelegate, ExternalMediaPickerViewDelegate, UIDocumentPickerDelegate {
    let blog: Blog
    let coordinator: MediaCoordinator

    init(blog: Blog, coordinator: MediaCoordinator) {
        self.blog = blog
        self.coordinator = coordinator
    }

    func makeMenu(for viewController: UIViewController) -> UIMenu {
        let menu = MediaPickerMenu(viewController: viewController, isMultipleSelectionEnabled: true)
        var children: [UIMenuElement] = [
            UIMenu(options: [.displayInline], children: [
                menu.makePhotosAction(delegate: self),
            ]),
            UIMenu(options: [.displayInline], children: [
                menu.makeCameraAction(delegate: self),
                makeDocumentPickerAction(from: viewController)
            ])
        ]
        let freeMediaActions: [UIAction] = [
            menu.makeStockPhotos(blog: blog, delegate: self),
            menu.makeFreeGIFAction(blog: blog, delegate: self)
        ].compactMap { $0 }
        if !freeMediaActions.isEmpty {
            children += [
                UIMenu(options: [.displayInline], children: freeMediaActions)
            ]
        }
        if let quotaUsageDescription = blog.quotaUsageDescription {
            children += [
                UIAction(subtitle: quotaUsageDescription, handler: { _ in })
            ]
        }
        return UIMenu(options: [.displayInline], children: children)
    }

    func showPhotosPicker(from viewController: UIViewController) {
        MediaPickerMenu(viewController: viewController, isMultipleSelectionEnabled: true)
            .showPhotosPicker(delegate: self)
    }

    // MARK: - PHPickerViewControllerDelegate

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.presentingViewController?.dismiss(animated: true)

        guard results.count > 0 else {
            return
        }

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

    // MARK: - ExternalMediaPickerViewDelegate

    func externalMediaPickerViewController(_ viewController: ExternalMediaPickerViewController, didFinishWithSelection assets: [ExternalMediaAsset]) {
        viewController.presentingViewController?.dismiss(animated: true)
        for asset in assets {
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(viewController.source), selectionMethod: .fullScreenPicker)
            coordinator.addMedia(from: asset, to: blog, analyticsInfo: info)

            switch viewController.source {
            case .stockPhotos:
                WPAnalytics.track(.stockMediaUploaded)
            case .tenor:
                WPAnalytics.track(.tenorUploaded)
            default:
                assertionFailure("Unsupported source: \(viewController.source)")
            }
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
