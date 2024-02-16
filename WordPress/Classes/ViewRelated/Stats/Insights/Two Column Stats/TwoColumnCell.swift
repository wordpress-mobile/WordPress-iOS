import UIKit
import DesignSystem

class TwoColumnCell: StatsBaseCell, NibLoadable, Accessible {

    // MARK: - Properties

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var viewMoreView: UIView!
    @IBOutlet weak var viewMoreLabel: UILabel!
    @IBOutlet weak var viewMoreButton: UIButton!
    @IBOutlet weak var bottomSeparatorLine: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    private typealias Style = WPStyleGuide.Stats
    private var dataRows = [StatsTwoColumnRowData]()
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?

    override var accessibilityElements: [Any]? {
        get {
            return [headingLabel, rowsStackView, viewMoreButton].compactMap { $0 }
        }

        set { }
    }

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
        prepareForVoiceOver()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeRowsFromStackView(rowsStackView)
    }

    func configure(dataRows: [StatsTwoColumnRowData], statSection: StatSection, siteStatsInsightsDelegate: SiteStatsInsightsDelegate?) {
        self.dataRows = dataRows
        self.statSection = statSection
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate

        addRows()
        toggleViewMore()
    }

    func prepareForVoiceOver() {
        viewMoreButton.accessibilityLabel =
            NSLocalizedString("View more", comment: "Accessibility label for View more button in Stats.")
        viewMoreButton.accessibilityHint = NSLocalizedString("Tap to view more details.", comment: "Accessibility hint for a button that opens a new view with more details.")
    }
}

// MARK: - Private Extension

private extension TwoColumnCell {

    func applyStyles() {
        viewMoreView.backgroundColor = .listForeground
        viewMoreLabel.text = NSLocalizedString("View more", comment: "Label for viewing more stats.")
        viewMoreLabel.textColor = Style.actionTextColor
        Style.configureCell(self)
        Style.configureViewAsSeparator(topSeparatorLine)
        Style.configureViewAsSeparator(bottomSeparatorLine)
        configureSpacing()
    }

    private func configureSpacing() {
        bottomConstraint.constant = Length.Padding.double
        rowsStackView.spacing = Length.Padding.single
    }

    func addRows() {
        guard !dataRows.isEmpty else {
            let row = StatsNoDataRow.loadFromNib()
            row.configure(forType: .insights)
            rowsStackView.addArrangedSubview(row)
            return
        }

        for dataRow in dataRows {
            let row = StatsTwoColumnRow.loadFromNib()
            row.configure(rowData: dataRow)
            rowsStackView.addArrangedSubview(row)
        }
    }

    func toggleViewMore() {
        let showViewMore = !dataRows.isEmpty && statSection == .insightsAnnualSiteStats
        viewMoreView.isHidden = !showViewMore
    }

    @IBAction func didTapViewMore(_ sender: UIButton) {
        guard let statSection = statSection else {
            return
        }

        captureAnalyticsEventsFor(statSection)
        siteStatsInsightsDelegate?.viewMoreSelectedForStatSection?(statSection)
    }

    // MARK: - Analytics support

    func captureAnalyticsEventsFor(_ statSection: StatSection) {
        if let event = statSection.analyticsViewMoreEvent {
            captureAnalyticsEvent(event)
        }
    }

    func captureAnalyticsEvent(_ event: WPAnalyticsStat) {
        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, withBlogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event)
        }
    }
}
