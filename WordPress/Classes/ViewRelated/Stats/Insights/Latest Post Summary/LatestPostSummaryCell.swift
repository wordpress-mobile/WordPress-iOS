import UIKit
import WordPressComStatsiOS
import Gridicons

class LatestPostSummaryCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var contentStackViewTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var summariesStackView: UIStackView!
    @IBOutlet weak var chartStackView: UIStackView!
    @IBOutlet weak var actionStackView: UIStackView!

    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var viewsDataLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var likesDataLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var commentsDataLabel: UILabel!

    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var actionImageView: UIImageView!
    @IBOutlet weak var disclosureImageView: UIImageView!

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private typealias Style = WPStyleGuide.Stats
    private var lastPostInsight: StatsLastPostInsight?

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

    func configure(withData lastPostInsight: StatsLastPostInsight?, andDelegate delegate: SiteStatsInsightsDelegate) {

        siteStatsInsightsDelegate = delegate

        // If there is no summary data, there is no post. Show Create Post option.
        guard let lastPostInsight = lastPostInsight else {
            actionType = .createPost
            return
        }

        self.lastPostInsight = lastPostInsight
        viewsDataLabel.text = lastPostInsight.viewsCount.abbreviatedString()
        likesDataLabel.text = lastPostInsight.likesCount.abbreviatedString()
        commentsDataLabel.text = lastPostInsight.commentsCount.abbreviatedString()

        // If there is a post but 0 data, show Share Post option.
        if lastPostInsight.likesCount == 0 && lastPostInsight.viewsCount == 0 && lastPostInsight.commentsCount == 0 {
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

        Style.configureCell(self)

        Style.configureLabelAsSummary(summaryLabel)
        Style.configureViewAsSeparator(topSeparatorLine)
        Style.configureViewAsSeparator(bottomSeparatorLine)

        viewsLabel.text = CellStrings.views
        viewsLabel.textColor = Style.defaultTextColor
        viewsDataLabel.textColor = Style.defaultTextColor

        likesLabel.text = CellStrings.likes
        likesLabel.textColor = Style.defaultTextColor
        likesDataLabel.textColor = Style.defaultTextColor

        commentsLabel.text = CellStrings.comments
        commentsLabel.textColor = Style.defaultTextColor
        commentsDataLabel.textColor = Style.defaultTextColor

        actionLabel.textColor = Style.actionTextColor
    }

    func configureViewForAction() {
        guard let actionType = actionType else {
            return
        }

        summaryLabel.attributedText = attributedSummary()

        switch actionType {
        case .viewMore:
            toggleDataViews(hide: false)
            configureChartView()
            actionLabel.text = CellStrings.viewMore
        case .sharePost:
            toggleDataViews(hide: true)
            setActionImageFor(action: .sharePost)
            actionLabel.text = CellStrings.sharePost
        case .createPost:
            toggleDataViews(hide: true)
            setActionImageFor(action: .createPost)
            actionLabel.text = CellStrings.createPost
        }
    }

    func toggleDataViews(hide: Bool) {
        summariesStackView.isHidden = hide
        chartStackView.isHidden = hide
        disclosureImageView.isHidden = hide
        actionImageView.isHidden = !hide
        contentStackViewTopConstraint.constant = hide ? ContentStackViewTopConstraint.dataHidden
                                                        : ContentStackViewTopConstraint.dataShown
    }

    func setActionImageFor(action: ActionType) {
        let iconType: GridiconType = action == .sharePost ? .shareIOS : .create
        actionImageView.image = Style.imageForGridiconType(iconType, withTint: .blue)
    }

    func attributedSummary() -> NSAttributedString {

        guard let actionType = actionType else {
            return NSAttributedString()
        }

        if actionType == .createPost {
            return NSAttributedString(string: CellStrings.summaryNoPosts)
        }

        let postAge = lastPostInsight?.publishedDate.relativeStringInPast() ?? ""
        let postTitle = lastPostInsight?.title.nonEmptyString() ?? NSLocalizedString("(No Title)", comment: "Empty Post Title")

        var summaryString = String(format: CellStrings.summaryPostInfo, postAge, postTitle)
        let summaryToAppend = actionType == .viewMore ? CellStrings.summaryPerformance : CellStrings.summaryNoData
        summaryString.append(summaryToAppend)

        return Style.highlightString(postTitle, inString: summaryString)
    }

    // MARK: - Properties

    enum ActionType: Int {
        case viewMore
        case sharePost
        case createPost
    }

    struct ContentStackViewTopConstraint {
        static let dataShown = CGFloat(37)
        static let dataHidden = CGFloat(16)
    }

    struct CellStrings {
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

    // MARK: - Button Handling

    @IBAction func didTapSummaryButton(_ sender: UIButton) {

        guard let postURL = lastPostInsight?.url else {
            return
        }

        siteStatsInsightsDelegate?.displayWebViewWithURL?(postURL)
    }

    @IBAction func didTapActionButton(_ sender: UIButton) {

        guard let actionType = actionType else {
            return
        }

        switch actionType {
        case .viewMore:
            // TODO: show Post Details
            showAlertWithTitle("Post Details will be shown here.")
        case .sharePost:
            guard let postID = lastPostInsight?.postID else {
                return
            }
            siteStatsInsightsDelegate?.showShareForPost?(postID: postID as NSNumber, fromView: actionStackView)
        case .createPost:
            siteStatsInsightsDelegate?.showCreatePost?()
        }
    }

    func showAlertWithTitle(_ title: String) {
        let alertController =  UIAlertController(title: title,
                                                 message: nil,
                                                 preferredStyle: .alert)
        alertController.addCancelActionWithTitle("OK")
        alertController.presentFromRootViewController()
    }

    // MARK: - Chart support

    func resetChartView() {
        chartStackView.removeAllSubviews()
    }

    func configureChartView() {
        resetChartView()

        // Introduced via #11061, to be replaced with real data via #11067
        let stubbedData = LatestPostSummaryDataStub()
        let firstStubbedDateInterval = stubbedData.data.first?.date.timeIntervalSince1970 ?? 0
        let styling = LatestPostSummaryStyling(initialDateInterval: firstStubbedDateInterval)

        let chartView = StatsBarChartView(data: stubbedData, styling: styling)
        chartStackView.addArrangedSubview(chartView)

        NSLayoutConstraint.activate([
            chartView.leadingAnchor.constraint(equalTo: chartStackView.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: chartStackView.trailingAnchor),
            chartView.topAnchor.constraint(equalTo: chartStackView.topAnchor),
            chartView.bottomAnchor.constraint(equalTo: chartStackView.bottomAnchor)
        ])
    }
}
