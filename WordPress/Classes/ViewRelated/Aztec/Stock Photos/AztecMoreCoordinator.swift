import MobileCoreServices
import WPMediaPicker

struct MoreCoordinatorContext {
    let origin: UIViewController & UIDocumentPickerDelegate
    let view: UIView
    let blog: Blog
}

/// Prepares the alert controller that will be presented when tapping the "more" button in Aztec's Format Bar
final class AztecMoreCoordinator {
    private weak var delegate: AztecMoreCoordinatorDelegate?

    private let stockPhotos = StockPhotosPicker()

    init(delegate: AztecMoreCoordinatorDelegate & StockPhotosPickerDelegate) {
        self.delegate = delegate
        stockPhotos.delegate = delegate
    }

    func present(context: MoreCoordinatorContext) {
        let origin = context.origin
        let fromView = context.view

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(freePhotoAction(origin: origin))
        alertController.addAction(otherAppsAction(origin: origin))
        alertController.addAction(cancelAction())

        alertController.popoverPresentationController?.sourceView = fromView
        alertController.popoverPresentationController?.sourceRect = CGRect(origin: fromView.frame.origin, size: CGSize(width: 1, height: 1))
        alertController.popoverPresentationController?.permittedArrowDirections = .any

        origin.present(alertController, animated: true, completion: nil)
    }

    private func freePhotoAction(origin: UIViewController) -> UIAlertAction {
        return UIAlertAction(title: .freePhotosLibrary, style: .default, handler: { [weak self] action in
            self?.showStockPhotos(origin: origin)
        })
    }

    private func otherAppsAction(origin: UIViewController & UIDocumentPickerDelegate) -> UIAlertAction {
        return UIAlertAction(title: .files, style: .default, handler: { [weak self] action in
            self?.showDocumentPicker(origin: origin)
        })
    }

    private func cancelAction() -> UIAlertAction {
        return UIAlertAction(title: .cancelMoreOptions, style: .cancel, handler: { [weak self] action in
            self?.delegate?.didCancel(coordinator: self)
        })
    }

    private func showStockPhotos(origin: UIViewController) {
        stockPhotos.presentPicker(origin: origin)
    }

    private func showDocumentPicker(origin: UIViewController & UIDocumentPickerDelegate) {
        let docTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
        let docPicker = UIDocumentPickerViewController(documentTypes: docTypes, in: .import)
        docPicker.delegate = origin
        WPStyleGuide.configureDocumentPickerNavBarAppearance()
        origin.present(docPicker, animated: true, completion: nil)
    }
}
