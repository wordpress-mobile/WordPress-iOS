import UIKit
import Photos
import PhotosUI
import WordPressCore
import WordPressData
import WordPressShared
import SwiftUI

final class SiteMediaAddMediaMenuController: NSObject, PHPickerViewControllerDelegate, ImagePickerControllerDelegate, ExternalMediaPickerViewDelegate, UIDocumentPickerDelegate, ImagePlaygroundPickerDelegate {
    let blog: Blog
    let coordinator: MediaCoordinator
    weak var viewController: UIViewController?

    private var mediaUploadService: MediaUploadService?

    init(blog: Blog, coordinator: MediaCoordinator, viewController: UIViewController) {
        self.blog = blog
        self.coordinator = coordinator
        self.viewController = viewController

        if FeatureFlag.newUploadMedia.enabled, let client = try? WordPressClient(site: WordPressSite(blog: blog)) {
            self.mediaUploadService = MediaUploadService(
                coreDataStack: ContextManager.shared,
                blog: TaggedManagedObjectID(blog),
                client: client
            )
        }
    }

    func makeMenu(for viewController: UIViewController) -> UIMenu {
        let menu = MediaPickerMenu(viewController: viewController, isMultipleSelectionEnabled: true)
        var children: [UIMenuElement] = [
            UIMenu(options: [.displayInline], children: [
                menu.makePhotosAction(delegate: self),
            ]),
            UIMenu(options: [.displayInline], children: [
                menu.makeCameraAction(delegate: self),
                menu.makeImagePlaygroundAction(delegate: self),
                makeDocumentPickerAction(from: viewController)
            ].compactMap { $0 })
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

    private func addMedia(_ assets: [ExportableAsset], analytics: MediaAnalyticsInfo) {
        if let mediaUploadService, let viewController {
            let mediaUploadingView = MediaUploadingView(mediaUploadService: mediaUploadService, assets: assets)
            let hostingController = UIHostingController(rootView: mediaUploadingView)
            viewController.present(hostingController, animated: true)
        } else {
            for asset in assets {
                coordinator.addMedia(from: asset, to: blog, analyticsInfo: analytics)
            }
        }
    }

    // MARK: - PHPickerViewControllerDelegate

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.presentingViewController?.dismiss(animated: true)

        guard results.count > 0 else {
            return
        }

        let assets = results.map { $0.itemProvider }
        addMedia(assets, analytics: MediaAnalyticsInfo(origin: .mediaLibrary(.deviceLibrary), selectionMethod: .fullScreenPicker))
    }

    // MARK: - ImagePlaygroundPickerDelegate

    func imagePlaygroundViewController(_ viewController: UIViewController, didCreateImageAt imageURL: URL) {
        viewController.presentingViewController?.dismiss(animated: true)

        let asset = MediaPickerMenu.makeItemProvider(with: imageURL)
        addMedia([asset], analytics: MediaAnalyticsInfo(origin: .mediaLibrary(.imagePlayground), selectionMethod: .fullScreenPicker))
    }

    // MARK: - ImagePickerControllerDelegate

    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.presentingViewController?.dismiss(animated: true)

        var assets = [ExportableAsset]()

        guard let mediaType = info[.mediaType] as? String else {
            return
        }
        switch mediaType {
        case UTType.image.identifier:
            if let image = info[.originalImage] as? UIImage {
                assets.append(image)
            }
        case UTType.movie.identifier:
            if let videoURL = info[.mediaURL] as? URL {
                assets.append(videoURL as NSURL)
            }
        default:
            break
        }

        guard !assets.isEmpty else { return }

        addMedia(assets, analytics: MediaAnalyticsInfo(origin: .mediaLibrary(.camera), selectionMethod: .fullScreenPicker))
    }

    // MARK: - ExternalMediaPickerViewDelegate

    func externalMediaPickerViewController(_ viewController: ExternalMediaPickerViewController, didFinishWithSelection assets: [ExternalMediaAsset]) {
        viewController.presentingViewController?.dismiss(animated: true)

        addMedia(assets, analytics: MediaAnalyticsInfo(origin: .mediaLibrary(viewController.source), selectionMethod: .fullScreenPicker))

        for _ in assets {
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
        addMedia(urls.map { $0 as NSURL }, analytics: MediaAnalyticsInfo(origin: .mediaLibrary(.otherApps), selectionMethod: .documentPicker))
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.presentingViewController?.dismiss(animated: true)
    }
}

private enum Strings {
    static let pickFromOtherApps = NSLocalizedString("mediaPicker.pickFromOtherApps", value: "Other Files", comment: "The name of the action in the context menu for selecting photos from other apps (Files app)")
}
