// Empty state for Stock Photos
final class StockPhotosPlaceholder: WPNoResultsView {

    private let pexelsUrl = "https://www.pexels.com"

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
        do {
            attributedMessageText = try createStringWithLinkAttributes(from: .freePhotosPlaceholderSubtitle)
        } catch {
            // A translation error could make the creation of link attributes to fail. (i.e. removing the '{')
            // This will make sure that the message is still present, without any {}, but without the link.
            messageText = removeCurlybraces(from: .freePhotosPlaceholderSubtitle)
        }
    }

    private func createStringWithLinkAttributes(from subtitle: String) throws -> NSAttributedString {
        let htmlTaggedString = subtitle.replacingOccurrences(of: "{", with: "<a href=\"\(pexelsUrl)\">")
            .replacingOccurrences(of: "}", with: "</a>")

        guard let htmlTaggedData = htmlTaggedString.data(using: .utf8) else {
            throw NSError()
        }

        let attributedString = try NSMutableAttributedString(
            data: htmlTaggedData,
            options:[.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil)

        return attributedString
    }

    private func removeCurlybraces(from string: String) -> String {
        return string.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")
    }
}
