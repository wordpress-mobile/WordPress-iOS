import MobileCoreServices

/// Prepares the alert controller that will be presented when tapping the "more" button in Aztec's Format Bar
final class AztecMoreCoordinator {
    func present(origin: UIViewController & UIDocumentPickerDelegate, view: UIView) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(freePhotoAction())
        alertController.addAction(otherAppsAction(origin: origin))
        alertController.addAction(cancelAction())


        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = CGRect(origin: view.frame.origin, size: CGSize(width: 1, height: 1))
        alertController.popoverPresentationController?.permittedArrowDirections = .any

        origin.present(alertController, animated: true, completion: nil)
    }

    private func freePhotoAction() -> UIAlertAction {
        return UIAlertAction(title: .freePhotosLibrary, style: .default, handler: { [weak self] action in
            self?.showStockPhotos()
        })
    }

    private func otherAppsAction(origin: UIViewController & UIDocumentPickerDelegate) -> UIAlertAction {
        return UIAlertAction(title: .files, style: .default, handler: { [weak self] action in
            self?.showDocumentPicker(origin: origin)
        })
    }

    private func cancelAction() -> UIAlertAction {
        return UIAlertAction(title: .cancelMoreOptions, style: .cancel, handler: nil)
    }

    private func showStockPhotos() {
        //This would be the starting point of the next PR
        print("Nothing to see here yet")
    }

    private func showDocumentPicker(origin: UIViewController & UIDocumentPickerDelegate) {
        let docTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
        let docPicker = UIDocumentPickerViewController(documentTypes: docTypes, in: .import)
        docPicker.delegate = origin
        WPStyleGuide.configureDocumentPickerNavBarAppearance()
        origin.present(docPicker, animated: true, completion: nil)
    }
}
