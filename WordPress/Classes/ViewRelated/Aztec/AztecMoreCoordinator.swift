import MobileCoreServices

final class AztecMoreCoordinator {
    func present(origin: UIViewController & UIDocumentPickerDelegate, view: UIView) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(freePhoto())
        alertController.addAction(files(origin: origin))
        alertController.addAction(cancel())


        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = CGRect(origin: view.frame.origin, size: CGSize(width: 1, height: 1))
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        origin.present(alertController, animated: true, completion: nil)
    }

    private func freePhoto() -> UIAlertAction {
        return UIAlertAction(title: .freePhotosLibrary, style: .default, handler: { action in
            print("going to free photos")
        })
    }

    private func files(origin: UIViewController & UIDocumentPickerDelegate) -> UIAlertAction {
        return UIAlertAction(title: .files, style: .default, handler: { [weak self] action in
            self?.showDocumentPicker(origin: origin)
        })
    }

    private func cancel() -> UIAlertAction {
        return UIAlertAction(title: .cancel, style: .cancel, handler: nil)
    }

    private func showDocumentPicker(origin: UIViewController & UIDocumentPickerDelegate) {
        let docTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
        let docPicker = UIDocumentPickerViewController(documentTypes: docTypes, in: .import)
        docPicker.delegate = origin
        WPStyleGuide.configureDocumentPickerNavBarAppearance()
        origin.present(docPicker, animated: true, completion: nil)
    }
}
