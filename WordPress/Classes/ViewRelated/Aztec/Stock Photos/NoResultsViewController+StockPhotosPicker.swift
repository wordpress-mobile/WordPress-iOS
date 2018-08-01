// Empty state for Stock Photos

extension NoResultsViewController {

    private enum Constants {
        static let companyUrl = "https://www.pexels.com"
        static let companyName = "Pexels"
        static let imageName = "media-no-results"
    }

    func configureAsIntro() {
        configure(title: .freePhotosPlaceholderTitle,
                  buttonTitle: nil,
                  subtitle: nil,
                  attributedSubtitle: attributedSubtitle(),
                  image: Constants.imageName,
                  accessoryView: nil)
    }

    private func attributedSubtitle() -> NSAttributedString {
        let subtitle: String = .freePhotosPlaceholderSubtitle
        let htmlTaggedLink = "<a href=\"\(Constants.companyUrl)\">\(Constants.companyName)</a>"
        let htmlTaggedText = subtitle.replacingOccurrences(of: Constants.companyName, with: htmlTaggedLink)
        return NSAttributedString.attributedStringWithHTML(htmlTaggedText, attributes: nil)
    }

    func configureAsLoading() {
        configure(title: .freePhotosSearchLoading,
                  buttonTitle: nil,
                  subtitle: nil,
                  attributedSubtitle: nil,
                  image: Constants.imageName,
                  accessoryView: nil)
    }

    func configureAsNoSearchResults(for string: String) {
        configure(title: configureSearchResultTitle(for: string),
                  buttonTitle: nil,
                  subtitle: nil,
                  attributedSubtitle: nil,
                  image: Constants.imageName,
                  accessoryView: nil)
    }

    private func configureSearchResultTitle(for string: String) -> String {
        //Translators could add an empty space at the end of this phrase.
        let sanitizedNoResultString = String.freePhotosSearchNoResult.trimmingCharacters(in: .whitespaces)
        let titleText = sanitizedNoResultString + " " + string
        return titleText
    }

}
