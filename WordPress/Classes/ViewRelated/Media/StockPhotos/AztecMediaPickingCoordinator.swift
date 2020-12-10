import MobileCoreServices
import WPMediaPicker

/// Prepares the alert controller that will be presented when tapping the "more" button in Aztec's Format Bar
final class AztecMediaPickingCoordinator {
    typealias PickersDelegate = StockPhotosPickerDelegate & TenorPickerDelegate
    private weak var delegate: PickersDelegate?
    private var tenor: TenorPicker?
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

        alertController.addAction(tenorAction(origin: origin, blog: blog))
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
        let picker = TenorPicker()
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
}

extension AztecMediaPickingCoordinator: TenorPickerDelegate {
    func tenorPicker(_ picker: TenorPicker, didFinishPicking assets: [TenorMedia]) {
        delegate?.tenorPicker(picker, didFinishPicking: assets)
        tenor = nil
    }
}
