import Foundation

struct JetpackNotWPErrorViewModel: JetpackErrorViewModel {
    let title: String? = nil
    let image: UIImage? = UIImage(named: "jetpack-empty-state-illustration")
    var description: FormattedStringProvider = FormattedStringProvider(string: Constants.description)
    var primaryButtonTitle: String? = Constants.primaryButtonTitle
    var secondaryButtonTitle: String? = nil

    func didTapPrimaryButton(in viewController: UIViewController?) {
        viewController?.navigationController?.popToRootViewController(animated: true)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) { }

    private struct Constants {
        static let description = NSLocalizedString("We were not able to detect a WordPress site at the address you entered."
                                                                + " Please make sure WordPress is installed and that you are running"
                                                                + " the latest available version.",
                                                               comment: "Message explaining that WordPress was not detected.")


        static let primaryButtonTitle = NSLocalizedString("Try With Another Account",
                                                          comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")
    }
}
