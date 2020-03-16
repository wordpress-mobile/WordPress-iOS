enum GravatarUploaderStatus {
    case idle
    case uploading(image: UIImage)
    case finished
}

protocol GravatarUploader: AnyObject {
    func updateGravatarStatus(_ status: GravatarUploaderStatus)
}

extension GravatarUploader {
    func presentGravatarPicker(from sourceVC: UIViewController) {
        WPAppAnalytics.track(.gravatarTapped)

        let pickerViewController = GravatarPickerViewController()
        pickerViewController.onCompletion = { [weak self] image in
            if let updatedGravatarImage = image {
                self?.uploadGravatarImage(updatedGravatarImage)
            }

            sourceVC.dismiss(animated: true)
        }
        pickerViewController.modalPresentationStyle = .formSheet
        sourceVC.present(pickerViewController, animated: true)
    }

    func uploadGravatarImage(_ newGravatar: UIImage) {

        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        guard let account = accountService.defaultWordPressComAccount() else {
            return
        }

        updateGravatarStatus(.uploading(image: newGravatar))

        let service = GravatarService()
        service.uploadImage(newGravatar, forAccount: account) { [weak self] error in
            DispatchQueue.main.async(execute: {
                WPAppAnalytics.track(.gravatarUploaded)
                self?.updateGravatarStatus(.finished)
            })
        }
    }
}
