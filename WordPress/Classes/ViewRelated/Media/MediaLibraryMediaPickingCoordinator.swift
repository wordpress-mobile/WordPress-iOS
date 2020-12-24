import MobileCoreServices
import WPMediaPicker

/// Prepares the alert controller that will be presented when tapping the "+" button in Media Library
final class MediaLibraryMediaPickingCoordinator {
    typealias PickersDelegate = StockPhotosPickerDelegate & WPMediaPickerViewControllerDelegate & TenorPickerDelegate
    private weak var delegate: PickersDelegate?
    private var tenor: TenorPicker?

    private var stockPhotos: StockPhotosPicker?
    private let cameraCapture = CameraCaptureCoordinator()
    private let mediaLibrary = MediaLibraryPicker()

    init(delegate: PickersDelegate) {
        self.delegate = delegate

        mediaLibrary.delegate = delegate
    }

    func present(context: MediaPickingContext) {
        let origin = context.origin
        let blog = context.blog
        let fromView = context.view
        let buttonItem = context.barButtonItem

        let menuAlert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        if let quotaUsageDescription = blog.quotaUsageDescription {
            menuAlert.title = quotaUsageDescription
        }

        if WPMediaCapturePresenter.isCaptureAvailable() {
            menuAlert.addAction(cameraAction(origin: origin, blog: blog))
        }

        menuAlert.addAction(photoLibraryAction(origin: origin, blog: blog))

        if blog.supports(.stockPhotos) {
            menuAlert.addAction(freePhotoAction(origin: origin, blog: blog))
        }

        menuAlert.addAction(tenorAction(origin: origin, blog: blog))
        menuAlert.addAction(otherAppsAction(origin: origin, blog: blog))
        menuAlert.addAction(cancelAction())

        menuAlert.popoverPresentationController?.sourceView = fromView
        menuAlert.popoverPresentationController?.sourceRect = fromView.bounds
        menuAlert.popoverPresentationController?.barButtonItem = buttonItem

        origin.present(menuAlert, animated: true)
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

    private func tenorAction(origin: UIViewController, blog: Blog) -> UIAlertAction {
        return UIAlertAction(title: .tenor, style: .default, handler: { [weak self] action in
            self?.showTenor(origin: origin, blog: blog)
        })
    }

    private func otherAppsAction(origin: UIViewController & UIDocumentPickerDelegate, blog: Blog) -> UIAlertAction {
        return UIAlertAction(title: .otherApps, style: .default, handler: { [weak self] action in
            self?.showDocumentPicker(origin: origin, blog: blog)
        })
    }

    private func cancelAction() -> UIAlertAction {
        return UIAlertAction(title: .cancelMoreOptions, style: .cancel, handler: nil)
    }

    private func showCameraCapture(origin: UIViewController, blog: Blog) {
        cameraCapture.presentMediaCapture(origin: origin, blog: blog)
    }

    private func showStockPhotos(origin: UIViewController, blog: Blog) {
        let picker = StockPhotosPicker()
        // add delegate conformance, allow release of picker in the same manner as the tenor picker
        // in order to prevent duplicated uploads and botched de-selection on second upload
        picker.delegate = self
        picker.presentPicker(origin: origin, blog: blog)
        stockPhotos = picker
    }

    private func showTenor(origin: UIViewController, blog: Blog) {
        let picker = TenorPicker()
        // Delegate to the PickerCoordinator so we can release the Tenor instance
        picker.delegate = self
        picker.presentPicker(origin: origin, blog: blog)
        tenor = picker
    }


    private func showDocumentPicker(origin: UIViewController & UIDocumentPickerDelegate, blog: Blog) {
        let docTypes = blog.allowedTypeIdentifiers
        let docPicker = UIDocumentPickerViewController(documentTypes: docTypes, in: .import)
        docPicker.delegate = origin
        docPicker.allowsMultipleSelection = true
        origin.present(docPicker, animated: true)
    }

    private func showMediaPicker(origin: UIViewController, blog: Blog) {
        mediaLibrary.presentPicker(origin: origin, blog: blog)
    }
}

extension MediaLibraryMediaPickingCoordinator: TenorPickerDelegate {
    func tenorPicker(_ picker: TenorPicker, didFinishPicking assets: [TenorMedia]) {
        delegate?.tenorPicker(picker, didFinishPicking: assets)
        tenor = nil
    }
}

extension MediaLibraryMediaPickingCoordinator: StockPhotosPickerDelegate {
    func stockPhotosPicker(_ picker: StockPhotosPicker, didFinishPicking assets: [StockPhotosMedia]) {
        delegate?.stockPhotosPicker(picker, didFinishPicking: assets)
        stockPhotos = nil
    }
}
