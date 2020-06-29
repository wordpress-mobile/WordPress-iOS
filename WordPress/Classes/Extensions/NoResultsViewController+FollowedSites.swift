import Foundation

extension NoResultsViewController {
    private struct Constants {
        static let noFollowedSitesTitle = NSLocalizedString("No followed sites", comment: "Title for the no followed sites result screen")
        static let noFollowedSitesSubtitle = NSLocalizedString("When you follow sites, you’ll see their content here.", comment: "Subtitle for the no followed sites result screen")
        static let noFollowedSitesButtonTitle = NSLocalizedString("Discover Sites", comment: "Title for button on the no followed sites result screen")

        static let noFollowedSitesImage = "wp-illustration-following-empty-results"
    }

    class func noFollowedSitesController(showActionButton showButton: Bool) -> NoResultsViewController {
        let titleText = NSMutableAttributedString(string: Constants.noFollowedSitesTitle,
                                                  attributes: WPStyleGuide.noFollowedSitesErrorTitleAttributes())

        let subtitleText = NSMutableAttributedString(string: Constants.noFollowedSitesSubtitle,
                                                     attributes: WPStyleGuide.noFollowedSitesErrorSubtitleAttributes())

        let controller = NoResultsViewController.controller()

        controller.configure(title: "",
                             attributedTitle: titleText,
                             buttonTitle: showButton ? Constants.noFollowedSitesButtonTitle : nil,
                             attributedSubtitle: subtitleText,
                             attributedSubtitleConfiguration: { (attributedText: NSAttributedString) -> NSAttributedString? in
                                return subtitleText },
                             image: Constants.noFollowedSitesImage)
        controller.labelStackViewSpacing = 12
        controller.labelButtonStackViewSpacing = 18

        return controller
    }
}
