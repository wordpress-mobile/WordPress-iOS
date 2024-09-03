import UIKit

class PostingActivityCell: StatsBaseCell, NibLoadable, Accessible {

    // MARK: - Properties

    @IBOutlet weak var monthsStackView: UIStackView!
    @IBOutlet weak var viewMoreLabel: UILabel!
    @IBOutlet weak var legendView: UIStackView!

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    @IBOutlet private var viewMoreView: UIView!
    @IBOutlet private weak var viewMoreButton: UIButton!

    private typealias Style = WPStyleGuide.Stats
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?

    // MARK: - Init

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
        addLegend()
        prepareForVoiceOver()
    }

    func configure(withData monthsData: [[PostingStreakEvent]], andDelegate delegate: SiteStatsInsightsDelegate?) {
        siteStatsInsightsDelegate = delegate
        statSection = .insightsPostingActivity
        addMonths(monthsData: monthsData)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeExistingMonths()
    }

    func prepareForVoiceOver() {
        viewMoreButton.accessibilityLabel =
            NSLocalizedString("View more", comment: "Accessibility label for viewing more posting activity.")
        viewMoreButton.accessibilityHint = NSLocalizedString("Tap to view more details.", comment: "Accessibility hint for a button that opens a new view with more details.")
    }

    override var accessibilityElements: [Any]? {
        get {
            [headingLabel] + monthsStackView.arrangedSubviews + [viewMoreButton].compactMap { $0 }
        }
        set { }
    }
}

// MARK: - Private Extension

private extension PostingActivityCell {

    func applyStyles() {
        viewMoreView.backgroundColor = .secondarySystemGroupedBackground
        viewMoreLabel.text = NSLocalizedString("View more", comment: "Label for viewing more posting activity.")
        viewMoreLabel.textColor = Style.actionTextColor
        Style.configureCell(self)
        Style.configureViewAsSeparator(topSeparatorLine)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

    func addLegend() {
        let legend = PostingActivityLegend.loadFromNib()
        legendView.addArrangedSubview(legend)
    }

    func addMonths(monthsData: [[PostingStreakEvent]]) {
        for monthData in monthsData {
            let monthView = PostingActivityMonth.loadFromNib()
            monthView.configure(monthData: monthData)
            monthsStackView.addArrangedSubview(monthView)
        }
    }

    func removeExistingMonths() {
        monthsStackView.arrangedSubviews.forEach {
            monthsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    @IBAction func didTapViewMoreButton(_ sender: UIButton) {
        WPAppAnalytics.track(.statsViewMoreTappedPostingActivity)
        siteStatsInsightsDelegate?.showPostingActivityDetails?()
    }

}
