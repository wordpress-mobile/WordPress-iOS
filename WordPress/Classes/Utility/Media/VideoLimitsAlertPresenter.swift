
/// Handles user alerts regarding video limits allowances
protocol VideoLimitsAlertPresenter {
    func presentVideoLimitExceededFromPicker(on viewController: UIViewController)
    func presentVideoLimitExceededAfterCapture(on viewController: UIViewController)
}

extension VideoLimitsAlertPresenter {

    /// Alerts users that the video they are trying to select from a media picker exceeds the allowed duration
    func presentVideoLimitExceededFromPicker(on viewController: UIViewController) {
        let title = NSLocalizedString("Selection not allowed",
                                      comment: "Title of an alert informing users that the video they are trying to select is not allowed.")
        presentVideoLimitsAlert(on: viewController, title: title)
    }

    /// Alerts users that the video they just recorded exceeds the allowed duration
    func presentVideoLimitExceededAfterCapture(on viewController: UIViewController) {
        let title = NSLocalizedString("Video not uploaded",
                                      comment: "Title of an alert informing users that the video they are trying to select is not allowed.")
        presentVideoLimitsAlert(on: viewController, title: title)
    }

    /// Builds and presents an alert for users trying to upload a video that exceeds allowed limits
    /// - Parameters:
    ///   - viewController: presenting UIViewController
    ///   - title: title of the alert
    private func presentVideoLimitsAlert(on viewController: UIViewController, title: String) {
        let message = NSLocalizedString("Uploading videos longer than 5 minutes requires a paid plan.",
                                        comment: "Message of an alert informing users that the video they are trying to select is not allowed.")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        viewController.present(alert, animated: true, completion: nil)
    }
}
