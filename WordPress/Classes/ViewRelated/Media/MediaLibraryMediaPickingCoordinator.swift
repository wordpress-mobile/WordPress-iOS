import MobileCoreServices
import WPMediaPicker

final class MediaLibraryMediaPickingCoordinator {
    private weak var delegate: MediaPickingOptionsDelegate?

    private let stockPhotos = StockPhotosPicker()
    private let cameraCapture = CameraCaptureCoordinator()
    private let mediaLibrary = MediaLibraryPicker()

    init(delegate: MediaPickingOptionsDelegate & StockPhotosPickerDelegate & WPMediaPickerViewControllerDelegate) {
        self.delegate = delegate
        stockPhotos.delegate = delegate
        mediaLibrary.delegate = delegate
    }

    func present(context: MediaPickingContext) {
        let origin = context.origin
        let blog = context.blog
        let fromView = context.view
        let buttonItem = context.barButtonItem

        let menuAlert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

        if let quotaUsageDescription = blog.quotaUsageDescription {
            menuAlert.title = quotaUsageDescription
        }

        if WPMediaCapturePresenter.isCaptureAvailable() {
            menuAlert.addAction(cameraAction(origin: origin, blog: blog))
        }

        menuAlert.addAction(photoLibraryAction(origin: origin, blog: blog))
        menuAlert.addAction(freePhotoAction(origin: origin, blog: blog))

        if #available(iOS 11.0, *) {
            menuAlert.addAction(otherAppsAction(origin: origin))
        }

        menuAlert.addAction(cancelAction())

        menuAlert.popoverPresentationController?.sourceView = fromView
        menuAlert.popoverPresentationController?.barButtonItem = buttonItem

        origin.present(menuAlert, animated: true, completion: nil)
    }

    private func cameraAction(origin: UIViewController, blog: Blog) -> UIAlertAction {
                return UIAlertAction(title: .takePhotoOrVideo, style: .default, handler: { [weak self] action in
                    self?.showCameraCapture(origin: origin, blog: blog)
                })
    }

    private func photoLibraryAction(origin: UIViewController, blog: Blog) -> UIAlertAction {
        return UIAlertAction(title: .importFromPhotoLibrary, style: .default, handler: { [weak self] action in
            self?.showMediaPicker(origin: origin, blog: blog)
        })
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

    private func showCameraCapture(origin: UIViewController, blog: Blog) {
        cameraCapture.presentMediaCapture(origin: origin, blog: blog)
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

    private func showMediaPicker(origin: UIViewController, blog: Blog) {
        mediaLibrary.presentPicker(origin: origin, blog: blog)
    }
}
