import MobileCoreServices
import WPMediaPicker

/// Prepares the alert controller that will be presented when tapping the "more" button in Aztec's Format Bar
final class AztecMediaPickingCoordinator {
    private let giphy = GiphyPicker()
    private let stockPhotos = StockPhotosPicker()

    init(delegate: GiphyPickerDelegate & StockPhotosPickerDelegate) {
        giphy.delegate = delegate
        stockPhotos.delegate = delegate
    }

    func present(context: MediaPickingContext) {
        let origin = context.origin
        let blog = context.blog
        let fromView = context.view

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if blog.supports(.stockPhotos) {
            alertController.addAction(freePhotoAction(origin: origin, blog: blog))
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

    private func giphyAction(origin: UIViewController, blog: Blog) -> UIAlertAction {
        return UIAlertAction(title: .giphy, style: .default, handler: { [weak self] action in
            self?.showGiphy(origin: origin, blog: blog)
        })
    }

    private func otherAppsAction(origin: UIViewController & UIDocumentPickerDelegate, blog: Blog) -> UIAlertAction {
        return UIAlertAction(title: .files, style: .default, handler: { [weak self] action in
            self?.showDocumentPicker(origin: origin, blog: blog)
        })
    }

    private func cancelAction() -> UIAlertAction {
        return UIAlertAction(title: .cancelMoreOptions, style: .cancel, handler: nil)
    }

    private func showStockPhotos(origin: UIViewController, blog: Blog) {
        stockPhotos.presentPicker(origin: origin, blog: blog)
    }

    private func showGiphy(origin: UIViewController, blog: Blog) {
        giphy.presentPicker(origin: origin, blog: blog)
    }

    private func showDocumentPicker(origin: UIViewController & UIDocumentPickerDelegate, blog: Blog) {
        let docTypes = blog.allowedTypeIdentifiers
        let docPicker = UIDocumentPickerViewController(documentTypes: docTypes, in: .import)
        docPicker.delegate = origin
        docPicker.allowsMultipleSelection = true
        WPStyleGuide.configureDocumentPickerNavBarAppearance()
        origin.present(docPicker, animated: true)
    }
}
