// Empty state for Stock Photos
final class StockPhotosPlaceholder: WPNoResultsView {

    private let companyUrl = "https://www.pexels.com"
    private let companyName = "Pexels"

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
        let htmlTaggedLink = "<a href=\"\(companyUrl)\">\(companyName)</a>"
        let htmlTaggedText = subtitle.replacingOccurrences(of: companyName, with: htmlTaggedLink)

        return NSAttributedString.attributedStringWithHTML(htmlTaggedText, attributes: nil)
    }
}
