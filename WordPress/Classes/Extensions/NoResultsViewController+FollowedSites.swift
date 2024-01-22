import Foundation

extension NoResultsViewController {
    private struct Constants {
        static let noFollowedSitesTitle = NSLocalizedString(
            "reader.no.blogs.title",
            value: "No blog subscriptions",
            comment: "Title for the no followed blogs result screen"
        )
        static let noFollowedSitesSubtitle = NSLocalizedString(
            "reader.no.blogs.subtitle",
            value: "Subscribe to blogs in Discover and you’ll see their latest posts here. Or search for a blog that you like already.",
            comment: "Subtitle for the no followed blogs result screen"
        )
        static let noFollowedSitesButtonTitle = NSLocalizedString(
            "reader.no.blogs.button",
            value: "Discover Blogs",
            comment: "Title for button on the no followed blogs result screen"
        )
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
                                return subtitleText })
        controller.hideImageView()
        controller.labelStackViewSpacing = 8
        controller.labelButtonStackViewSpacing = 18
        controller.loadViewIfNeeded()
        controller.setupReaderButtonStyles()

        return controller
    }
}

extension NoResultsViewController {

    func setupReaderButtonStyles() {
        actionButton.primaryNormalBackgroundColor = .text
        actionButton.primaryTitleColor = .systemBackground
        actionButton.primaryHighlightBackgroundColor = .text
    }

}
