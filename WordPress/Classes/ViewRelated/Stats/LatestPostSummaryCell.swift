import UIKit
import WordPressComStatsiOS
import Gridicons

class LatestPostSummaryCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet weak var borderedView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!

    @IBOutlet weak var summariesStackView: UIStackView!
    @IBOutlet weak var chartStackView: UIStackView!

    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var viewsDataLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var likesDataLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var commentsDataLabel: UILabel!

    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var actionImageView: UIImageView!
    @IBOutlet weak var disclosureImageView: UIImageView!

    private var summaryData: StatsLatestPostSummary?

    private var actionType: ActionType? {
        didSet {
            configureViewForAction()
        }
    }

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(withData summaryData: StatsLatestPostSummary?) {

        // If there is no summary data, there is no post. Show Create Post option.
        guard let summaryData = summaryData else {
            actionType = .createPost
            return
        }

        self.summaryData = summaryData
        viewsDataLabel.text = summaryData.views
        likesDataLabel.text = summaryData.likes
        commentsDataLabel.text = summaryData.comments

        // If there is a post but 0 data, show Share Post option.
        if summaryData.viewsValue == 0 && summaryData.likesValue == 0 && summaryData.commentsValue == 0 {
            actionType = .sharePost
            return
        }

        // If there is a post and post data, show View More option.
        actionType = .viewMore
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

        actionLabel.textColor = WPStyleGuide.wordPressBlue()
    }

    func configureViewForAction() {
        guard let actionType = actionType else {
            return
        }

        summaryLabel.attributedText = attributedSummary()

        switch actionType {
        case .viewMore:
            toggleDataViews(hide: false)
            disclosureImageView.isHidden = false
            actionImageView.isHidden = true
            actionLabel.text = CellStrings.viewMore
        case .sharePost:
            toggleDataViews(hide: true)
            disclosureImageView.isHidden = true
            actionImageView.isHidden = false
            let icon = Gridicon.iconOfType(.shareIOS).imageWithTintColor(WPStyleGuide.mediumBlue())
            actionImageView.image = icon
            actionLabel.text = CellStrings.sharePost
        case .createPost:
            toggleDataViews(hide: true)
            disclosureImageView.isHidden = true
            actionImageView.isHidden = false
            let icon = Gridicon.iconOfType(.create).imageWithTintColor(WPStyleGuide.mediumBlue())
            actionImageView.image = icon
            actionLabel.text = CellStrings.createPost
        }
    }

    func toggleDataViews(hide: Bool) {
        summariesStackView.isHidden = hide
        chartStackView.isHidden = hide
    }

    func attributedSummary() -> NSAttributedString {

        guard let actionType = actionType else {
            return NSAttributedString()
        }

        if actionType == .createPost {
            // Add formatting to entire string.
            return NSMutableAttributedString(string: CellStrings.summaryNoPosts, attributes: [
                .foregroundColor: WPStyleGuide.darkGrey(),
                .font: WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
                ])
        }

        let postAge = summaryData?.postAge ?? ""
        let postTitle = summaryData?.postTitle ?? ""

        var unformattedString = String(format: CellStrings.summaryPostInfo, postAge, postTitle)
        let summaryToAppend = actionType == .viewMore ? CellStrings.summaryPerformance : CellStrings.summaryNoData
        unformattedString.append(summaryToAppend)

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

    enum ActionType: Int {
        case viewMore
        case sharePost
        case createPost
    }

    struct CellStrings {
        static let header = NSLocalizedString("Latest Post Summary", comment: "Insights latest post summary section header")
        static let summaryPostInfo = NSLocalizedString("It's been %@ since %@ was published. ", comment: "Latest post summary text including placeholder for time and the post title.")
        static let summaryPerformance = NSLocalizedString("Here's how the post performed so far.", comment: "Appended to latest post summary text when the post has data.")
        static let summaryNoData = NSLocalizedString("Get the ball rolling and increase your post views by sharing your post.", comment: "Appended to latest post summary text when the post does not have data.")
        static let summaryNoPosts = NSLocalizedString("You haven't published any posts yet. Once you start publishing, your latest post's summary will appear here.", comment: "Latest post summary text when there are no posts.")
        static let views = NSLocalizedString("Views", comment: "Label for post views count.")
        static let likes = NSLocalizedString("Likes", comment: "Label for post likes count.")
        static let comments = NSLocalizedString("Comments", comment: "Label for post comments count.")
        static let viewMore = NSLocalizedString("View more", comment: "Label for viewing more post information.")
        static let sharePost = NSLocalizedString("Share Post", comment: "Label for action to share post.")
        static let createPost = NSLocalizedString("Create Post", comment: "Label for action to create a new post.")
    }

}
