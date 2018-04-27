// Empty state for Stock Photos
final class StockPhotosPlaceholder: WPNoResultsView {

    private enum Constants {
        static let companyUrl = "https://www.pexels.com"
        static let companyName = "Pexels"
    }

    init() {
        super.init(frame: .zero)
        configureAsIntro()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureAsIntro() {
        configureImage()
        configureTitle()
        configureSubtitle()
    }

    func configureAsLoading() {
        configureLoadingIndicator()
        titleText = " " // empty strings are ignored.
        messageText = ""
    }

    func configureAsNoSearchResults(for string: String) {
        configureImage()
        configureSearchResultTitle(for: string)
        messageText = ""
    }

    private func configureSearchResultTitle(for string: String) {
        //Translators could add an empty space at the end of this phrase.
        let sanitizedNoResultString = String.freePhotosSearchNoResult.trimmingCharacters(in: .whitespaces)
        titleText = sanitizedNoResultString + " " + string
    }

    private func configureLoadingIndicator() {
        let activity = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activity.color = UIColor.gray
        accessoryView = activity
        activity.startAnimating()
    }

    private func configureImage() {
        accessoryView = UIImageView(image: UIImage(named: "media-free-photos-no-results"))
    }

    private func configureTitle() {
        titleText = .freePhotosPlaceholderTitle
    }

    private func configureSubtitle() {
        attributedMessageText = createStringWithLinkAttributes(from: .freePhotosPlaceholderSubtitle)
    }

    private func createStringWithLinkAttributes(from subtitle: String) -> NSAttributedString {
        let htmlTaggedLink = "<a href=\"\(Constants.companyUrl)\">\(Constants.companyName)</a>"
        let htmlTaggedText = subtitle.replacingOccurrences(of: Constants.companyName, with: htmlTaggedLink)

        return NSAttributedString.attributedStringWithHTML(htmlTaggedText, attributes: nil)
    }
}
