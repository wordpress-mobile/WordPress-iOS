import MobileCoreServices

final class AztecMoreOptionsSheet {
    func present(origin: UIViewController, view: UIView) {
        let alertController = UIAlertController(title: "Cesar", message: nil, preferredStyle: .actionSheet)
        alertController.addActionWithTitle("Cancel",
                                           style: .cancel,
                                           handler: { (action) in

        })


        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = CGRect(origin: view.frame.origin, size: CGSize(width: 1, height: 1))
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        origin.present(alertController, animated: true, completion: nil)
    }

    private func showDocumentPicker(origin: UIViewController) {
        let docTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
        let docPicker = UIDocumentPickerViewController(documentTypes: docTypes, in: .import)
        docPicker.delegate = origin as! UIDocumentPickerDelegate
        WPStyleGuide.configureDocumentPickerNavBarAppearance()
        origin.present(docPicker, animated: true, completion: nil)
    }
}
