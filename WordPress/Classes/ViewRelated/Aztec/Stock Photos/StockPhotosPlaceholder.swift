// Empty state for Stock Photos
final class StockPhotosPlaceholder: WPNoResultsView {

    private enum Constants {
        static let companyUrl = "https://www.pexels.com"
        static let companyName = "Pexels"
    }

    init() {
        super.init(frame: .zero)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        configureImage()
        configureTitle()
        configureSubtitle()
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
