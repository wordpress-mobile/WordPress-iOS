import MobileCoreServices
import WPMediaPicker

/// Prepares the alert controller that will be presented when tapping the "more" button in Aztec's Format Bar
final class AztecMediaPickingCoordinator {
    typealias PickersDelegate = StockPhotosPickerDelegate & ExternalMediaPickerViewDelegate
    private weak var delegate: PickersDelegate?
    private let stockPhotos = StockPhotosPicker()

    init(delegate: PickersDelegate) {
        self.delegate = delegate
        stockPhotos.delegate = delegate
    }

    func present(context: MediaPickingContext) {
        let origin = context.origin
        let blog = context.blog
        let fromView = context.view

        let alertController = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: UIDevice.isPad() ? .alert : .actionSheet)

        if blog.supports(.stockPhotos) {
            alertController.addAction(freePhotoAction(origin: origin, blog: blog))
        }
        if blog.supports(.tenor) {
            alertController.addAction(tenorAction(origin: origin, blog: blog))
        }

        alertController.addAction(otherAppsAction(origin: origin, blog: blog))
        alertController.addAction(cancelAction())

        alertController.popoverPresentationController?.sourceView = fromView
        alertController.popoverPresentationController?.sourceRect = CGRect(origin: fromView.frame.origin, size: CGSize(width: 1, height: 1))
        alertController.popoverPresentationController?.permittedArrowDirections = .any

        origin.present(alertController, animated: true)
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

    private func showStockPhotos(origin: UIViewController, blog: Blog) {
        stockPhotos.presentPicker(origin: origin, blog: blog)
    }

    private func showTenor(origin: UIViewController, blog: Blog) {
        MediaPickerMenu(viewController: origin, isMultipleSelectionEnabled: true)
            .showFreeGIFPicker(blog: blog, delegate: self)
    }

    private func showDocumentPicker(origin: UIViewController & UIDocumentPickerDelegate, blog: Blog) {
        let docTypes = blog.allowedTypeIdentifiers
        let docPicker = UIDocumentPickerViewController(documentTypes: docTypes, in: .import)
        docPicker.delegate = origin
        docPicker.allowsMultipleSelection = true
        origin.present(docPicker, animated: true)
    }
}

extension AztecMediaPickingCoordinator: ExternalMediaPickerViewDelegate {
    func externalMediaPickerViewController(_ viewController: ExternalMediaPickerViewController, didFinishWithSelection selection: [ExternalMediaAsset]) {
        delegate?.externalMediaPickerViewController(viewController, didFinishWithSelection: selection)
    }
}
