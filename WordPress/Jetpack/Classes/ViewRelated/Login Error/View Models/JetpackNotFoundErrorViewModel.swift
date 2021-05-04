import Foundation

struct JetpackNotFoundErrorViewModel: JetpackErrorViewModel {
    let image: UIImage? = UIImage(named: "wp-illustration-construct-site")
    var description: String = Constants.description
    var primaryButtonTitle: String? = Constants.primaryButtonTitle
    var secondaryButtonTitle: String? = Constants.secondaryButtonTitle

    private let siteURL: String

    init(with siteURL: String?) {
        self.siteURL = siteURL ?? Constants.yourSite
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let url = URL(string: Constants.helpURLString) else {
            return
        }

        let controller = WebViewControllerFactory.controller(url: url)
        let navController = UINavigationController(rootViewController: controller)

        viewController?.present(navController, animated: true)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.navigationController?.popToRootViewController(animated: true)
    }

    private struct Constants {
        static let yourSite = NSLocalizedString("your site",
                                                comment: "Placeholder for site url, if the url is unknown."
                                                    + "Presented when logging in with a site address that does not have a valid Jetpack installation."
                                                    + "The error would read: to use this app for your site you'll need...")

        static let description = NSLocalizedString("To use this app for %@ you'll need to have the Jetpack plugin installed and activated.",
                                                   comment: "Message explaining that Jetpack needs to be installed for a particular site. "
                                                    + "Reads like 'To use this app for example.com you'll need to have...")

        static let primaryButtonTitle = NSLocalizedString("See Instructions",
                                                          comment: "Action button linking to instructions for installing Jetpack."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let secondaryButtonTitle = NSLocalizedString("Try With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                                + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let helpURLString = "https://jetpack.com/support/getting-started-with-jetpack/"
    }
}
