// Empty state for Stock Photos

struct NoResultsStockPhotosConfiguration {

    static func configureAsIntro(_ viewController: NoResultsViewController) {
        viewController.configure(title: .freePhotosPlaceholderTitle,
                                 buttonTitle: nil,
                                 subtitle: nil,
                                 attributedSubtitle: attributedSubtitle(),
                                 image: Constants.imageName,
                                 accessoryView: nil)

        viewController.view.layoutIfNeeded()
    }

    static func configureAsLoading(_ viewController: NoResultsViewController) {
        viewController.configure(title: .freePhotosSearchLoading,
                                 buttonTitle: nil,
                                 subtitle: nil,
                                 attributedSubtitle: nil,
                                 image: Constants.imageName,
                                 accessoryView: nil)

        viewController.view.layoutIfNeeded()
    }

    static func configure(_ viewController: NoResultsViewController, asNoSearchResultsFor string: String) {
        viewController.configure(title: .freePhotosSearchNoResult,
                                 buttonTitle: nil,
                                 subtitle: string,
                                 attributedSubtitle: nil,
                                 image: Constants.imageName,
                                 accessoryView: nil)

        viewController.view.layoutIfNeeded()
    }

    private enum Constants {
        static let companyUrl = "https://www.pexels.com"
        static let companyName = "Pexels"
        static let imageName = "media-no-results"
    }

    static func attributedSubtitle() -> NSAttributedString {
        let subtitle: String = .freePhotosPlaceholderSubtitle
        let htmlTaggedLink = "<a href=\"\(Constants.companyUrl)\">\(Constants.companyName)</a>"
        let htmlTaggedText = subtitle.replacingOccurrences(of: Constants.companyName, with: htmlTaggedLink)
        return NSAttributedString.attributedStringWithHTML(htmlTaggedText, attributes: nil)
    }
}
