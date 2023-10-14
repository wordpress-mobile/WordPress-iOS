enum GravatarUploaderStatus {
    case idle
    case uploading(image: UIImage)
    case finished
}

protocol GravatarUploader: AnyObject {
    func updateGravatarStatus(_ status: GravatarUploaderStatus)
}

extension GravatarUploader {
    func uploadGravatarImage(_ newGravatar: UIImage) {

        let context = ContextManager.sharedInstance().mainContext

        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context) else {
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
