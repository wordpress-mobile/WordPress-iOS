import UIKit

final class StockPhotosWelcomeView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        let textLabel = UILabel()
        textLabel.text = Strings.title
        textLabel.font = WPStyleGuide.fontForTextStyle(.title2)
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.attributedText = makeAttributedSubtitle()
        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.body)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [
            UIImageView(image: UIImage(named: "media-no-results")),
            textLabel,
            subtitleLabel
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 24
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)

        let wrapper = UIStackView(arrangedSubviews: [stack])
        wrapper.alignment = .center
        addSubview(wrapper)
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(wrapper)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Constants {
    static let companyUrl = "https://www.pexels.com"
    static let companyName = "Pexels"
}

private func makeAttributedSubtitle() -> NSAttributedString {
    let subtitle: String = Strings.freePhotosPlaceholderSubtitle
    let htmlTaggedLink = "<a href=\"\(Constants.companyUrl)\">\(Constants.companyName)</a>"
    let htmlTaggedText = subtitle.replacingOccurrences(of: Constants.companyName, with: htmlTaggedLink)
    return NSAttributedString.attributedStringWithHTML(htmlTaggedText, attributes: nil)
}

private enum Strings {
    static let title = NSLocalizedString("stockPhotos.title", value: "Search to find free photos to add to your Media Library!", comment: "Title for placeholder in Free Photos")
    static var freePhotosPlaceholderSubtitle: String {
        return NSLocalizedString("stockPhotos.subtitle", value: "Photos provided by Pexels", comment: "Subtitle for placeholder in Free Photos. The company name 'Pexels' should always be written as it is.")
    }
}
