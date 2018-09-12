// Empty state for Giphy

struct NoResultsGiphyConfiguration {

    static func configureAsIntro(_ viewController: NoResultsViewController) {
        viewController.configure(title: .giphyPlaceholderTitle,
                                 buttonTitle: nil,
                                 subtitle: nil,
                                 attributedSubtitle: attributedSubtitle(),
                                 image: Constants.imageName,
                                 accessoryView: nil)

        viewController.view.layoutIfNeeded()
    }

    static func configureAsLoading(_ viewController: NoResultsViewController) {
        viewController.configure(title: .giphySearchLoading,
                                 buttonTitle: nil,
                                 subtitle: nil,
                                 attributedSubtitle: nil,
                                 image: Constants.imageName,
                                 accessoryView: nil)

        viewController.view.layoutIfNeeded()
    }

    static func configure(_ viewController: NoResultsViewController, asNoSearchResultsFor string: String) {
        viewController.configure(title: .giphySearchNoResult,
                                 buttonTitle: nil,
                                 subtitle: string,
                                 attributedSubtitle: nil,
                                 image: Constants.imageName,
                                 accessoryView: nil)

        viewController.view.layoutIfNeeded()
    }

    private enum Constants {
        static let companyUrl = "https://www.giphy.com"
        static let companyName = "Giphy"
        static let imageName = "media-no-results"
    }

    static func attributedSubtitle() -> NSAttributedString {
        let subtitle: String = .giphyPlaceholderSubtitle
        let htmlTaggedLink = "<a href=\"\(Constants.companyUrl)\">\(Constants.companyName)</a>"
        let htmlTaggedText = subtitle.replacingOccurrences(of: Constants.companyName, with: htmlTaggedLink)
        return NSAttributedString.attributedStringWithHTML(htmlTaggedText, attributes: nil)
    }
}
