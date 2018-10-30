import UIKit

class LatestPostSummaryCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet weak var borderedView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!

    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var viewsDataLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var likesDataLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var commentsDataLabel: UILabel!

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure() {
        summaryLabel.attributedText = attributedSummary()
    }

}

// MARK: - Private Extension

private extension LatestPostSummaryCell {

    func applyStyles() {
        contentView.backgroundColor = WPStyleGuide.greyLighten30()
        borderedView.layer.borderColor = WPStyleGuide.greyLighten20().cgColor
        borderedView.layer.borderWidth = 0.5

        headerLabel.text = CellStrings.header
        headerLabel.textColor = WPStyleGuide.darkGrey()
        headerLabel.font = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)

        viewsLabel.textColor = WPStyleGuide.darkGrey()
        viewsDataLabel.textColor = WPStyleGuide.darkGrey()

        likesLabel.textColor = viewsLabel.textColor
        likesDataLabel.textColor = viewsDataLabel.textColor

        commentsLabel.textColor = viewsLabel.textColor
        commentsDataLabel.textColor = viewsDataLabel.textColor
    }

    func attributedSummary() -> NSAttributedString {

        let postTitle = "Testing testing testing"
        let time = "666 months"

        let unformattedString = String(format: CellStrings.cardSummary, time, postTitle)

        // Add formatting to entire string.
        let attributedString = NSMutableAttributedString(string: unformattedString, attributes: [
            .foregroundColor: WPStyleGuide.darkGrey(),
            .font: WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
            ])

        guard let postTitleRange = unformattedString.nsRange(of: postTitle) else {
            return attributedString
        }

        // Add formatting to post title
        attributedString.addAttributes(        [
            .foregroundColor: WPStyleGuide.wordPressBlue(),
            .font: WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
            ], range: postTitleRange)

        return attributedString
    }

    struct CellStrings {
        static let header = NSLocalizedString("Latest Post Summary", comment: "Insights latest post summary section header")
        static let cardSummary = NSLocalizedString("It's been %@ since %@ was published. Here's how the post performed so far.", comment: "Latest post summary text including placeholder for time and the post title.")
    }

}
