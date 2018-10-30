import UIKit
import WordPressComStatsiOS

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

    @IBOutlet weak var viewMoreLabel: UILabel!

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(withData summaryData: StatsLatestPostSummary?) {
        guard let summaryData = summaryData else {
            return
        }

        summaryLabel.attributedText = attributedSummary(postTitle: summaryData.postTitle, postAge: summaryData.postAge)
        viewsDataLabel.text = summaryData.views
        likesDataLabel.text = summaryData.likes
        commentsDataLabel.text = summaryData.comments
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
        viewsLabel.text = CellStrings.views
        viewsDataLabel.textColor = WPStyleGuide.darkGrey()

        likesLabel.textColor = viewsLabel.textColor
        likesLabel.text = CellStrings.likes
        likesDataLabel.textColor = viewsDataLabel.textColor

        commentsLabel.textColor = viewsLabel.textColor
        commentsLabel.text = CellStrings.comments
        commentsDataLabel.textColor = viewsDataLabel.textColor

        viewMoreLabel.textColor = WPStyleGuide.wordPressBlue()
        viewMoreLabel.text = CellStrings.viewMore
    }

    func attributedSummary(postTitle: String, postAge: String) -> NSAttributedString {

        let unformattedString = String(format: CellStrings.summary, postAge, postTitle)

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
        static let summary = NSLocalizedString("It's been %@ since %@ was published. Here's how the post performed so far.", comment: "Latest post summary text including placeholder for time and the post title.")
        static let views = NSLocalizedString("Views", comment: "Label for post views count.")
        static let likes = NSLocalizedString("Likes", comment: "Label for post likes count.")
        static let comments = NSLocalizedString("Comments", comment: "Label for post comments count.")
        static let viewMore = NSLocalizedString("View more", comment: "Label for viewing more post information.")
    }

}
