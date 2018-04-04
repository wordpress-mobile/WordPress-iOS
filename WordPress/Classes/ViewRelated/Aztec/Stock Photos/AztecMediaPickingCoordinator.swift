import MobileCoreServices
import WPMediaPicker

/// Prepares the alert controller that will be presented when tapping the "more" button in Aztec's Format Bar
final class AztecMediaPickingCoordinator {
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

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(freePhotoAction(origin: origin, blog: blog))
        alertController.addAction(otherAppsAction(origin: origin))
        alertController.addAction(cancelAction())

        alertController.popoverPresentationController?.sourceView = fromView
        alertController.popoverPresentationController?.sourceRect = CGRect(origin: fromView.frame.origin, size: CGSize(width: 1, height: 1))
        alertController.popoverPresentationController?.permittedArrowDirections = .any

        origin.present(alertController, animated: true, completion: nil)
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
