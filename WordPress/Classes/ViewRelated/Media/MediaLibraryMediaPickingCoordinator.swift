import MobileCoreServices
import WPMediaPicker

final class MediaLibraryMediaPickingCoordinator {
    private weak var delegate: MediaPickingOptionsDelegate?

    private let stockPhotos = StockPhotosPicker()

    init(delegate: MediaPickingOptionsDelegate & StockPhotosPickerDelegate) {
        self.delegate = delegate
        stockPhotos.delegate = delegate
    }

    func present(context: MediaPickingContext) {
        let origin = context.origin
        let blog = context.blog
        let fromView = context.view

        let menuAlert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

        if let quotaUsageDescription = blog.quotaUsageDescription {
            menuAlert.title = quotaUsageDescription
        }

        if WPMediaCapturePresenter.isCaptureAvailable() {
            menuAlert.addDefaultActionWithTitle(NSLocalizedString("Take Photo or Video", comment: "Menu option for taking an image or video with the device's camera.")) { _ in
                //self.presentMediaCapture()
            }
        }

        menuAlert.addDefaultActionWithTitle(NSLocalizedString("Photo Library", comment: "Menu option for selecting media from the device's photo library.")) { _ in
            //self.showMediaPicker()
        }

        if #available(iOS 11.0, *) {
            menuAlert.addDefaultActionWithTitle(NSLocalizedString("Other Apps", comment: "Menu option used for adding media from other applications.")) { _ in
                //self.showDocumentPicker()
            }
        }

        menuAlert.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Cancel button"))

        // iPad support
//        menuAlert.popoverPresentationController?.sourceView = fromView
//        menuAlert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem

        origin.present(menuAlert, animated: true, completion: nil)
    }

    private func freePhotoAction(origin: UIViewController, blog: Blog) -> UIAlertAction {
        return UIAlertAction(title: .freePhotosLibrary, style: .default, handler: { [weak self] action in
            self?.showStockPhotos(origin: origin, blog: blog)
        })
    }

    private func otherAppsAction(origin: UIViewController & UIDocumentPickerDelegate) -> UIAlertAction {
        return UIAlertAction(title: .files, style: .default, handler: { [weak self] action in
            self?.showDocumentPicker(origin: origin)
        })
    }

    private func cancelAction() -> UIAlertAction {
        return UIAlertAction(title: .cancelMoreOptions, style: .cancel, handler: { [weak self] action in
            self?.delegate?.didCancel()
        })
    }

    private func showStockPhotos(origin: UIViewController, blog: Blog) {
        stockPhotos.presentPicker(origin: origin, blog: blog)
    }

    private func showDocumentPicker(origin: UIViewController & UIDocumentPickerDelegate) {
        let docTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
        let docPicker = UIDocumentPickerViewController(documentTypes: docTypes, in: .import)
        docPicker.delegate = origin
        WPStyleGuide.configureDocumentPickerNavBarAppearance()
        origin.present(docPicker, animated: true, completion: nil)
    }

}
