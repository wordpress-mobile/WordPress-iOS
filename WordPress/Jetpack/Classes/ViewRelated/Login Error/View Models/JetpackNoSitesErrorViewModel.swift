import Foundation

struct JetpackNoSitesErrorViewModel: JetpackErrorViewModel {
    let image: UIImage? = UIImage(named: "jetpack-empty-state-illustration")
    var title: String? = Constants.title
    var description: FormattedStringProvider = FormattedStringProvider(string: Constants.description)
    var primaryButtonTitle: String? = Constants.primaryButtonTitle
    var secondaryButtonTitle: String? = Constants.secondaryButtonTitle

    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let url = URL(string: Constants.helpURLString) else {
            return
        }

        let controller = WebViewControllerFactory.controller(url: url, source: "jetpack_no_sites")
        let navController = UINavigationController(rootViewController: controller)

        viewController?.present(navController, animated: true)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        AccountHelper.logOutDefaultWordPressComAccount()
    }

    private struct Constants {
        static let title = AppLocalizedString("No Jetpack sites found",
                                            comment: "Title when users have no Jetpack sites.")

        static let description = AppLocalizedString("If you already have a site, you’ll need to install the free Jetpack plugin and connect it to your WordPress.com account.",
                                                   comment: "Message explaining that they will need to install Jetpack on one of their sites.")


        static let primaryButtonTitle = AppLocalizedString("See Instructions",
                                                          comment: "Action button linking to instructions for installing Jetpack."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let secondaryButtonTitle = AppLocalizedString("Try With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                                + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let helpURLString = "https://jetpack.com/support/getting-started-with-jetpack/"
    }
}
