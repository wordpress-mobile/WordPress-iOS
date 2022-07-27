import UIKit

struct JetpackNotFoundErrorViewModel: JetpackErrorViewModel {
    let title: String? = nil
    let image: UIImage? = UIImage(named: "jetpack-empty-state-illustration")
    var description: FormattedStringProvider {
        let siteName = siteURL
        let description = String(format: Constants.description, siteName)
        let font: UIFont = JetpackLoginErrorViewController.descriptionFont.semibold()

        let attributedString = NSMutableAttributedString(string: description)
        attributedString.applyStylesToMatchesWithPattern(siteName, styles: [.font: font])

        return FormattedStringProvider(attributedString: attributedString)
    }

    var primaryButtonTitle: String? = Constants.primaryButtonTitle
    var secondaryButtonTitle: String? = Constants.secondaryButtonTitle

    private let siteURL: String

    init(with siteURL: String?) {
        self.siteURL = siteURL?.trimURLScheme() ?? Constants.yourSite
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let url = URL(string: Constants.helpURLString) else {
            return
        }

        let controller = WebViewControllerFactory.controller(url: url, source: "jetpack_not_found")
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

private extension String {
    // Removes http:// or https://
    func trimURLScheme() -> String? {
        guard let urlComponents = URLComponents(string: self),
              let host = urlComponents.host else {
            return self
        }

        return host + urlComponents.path
    }
}
