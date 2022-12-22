import UIKit

class CountriesCell: StatsBaseCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var subtitleStackView: UIStackView!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!
    @IBOutlet weak var bottomSeparatorLine: UIView!
    @IBOutlet weak var subtitlesStackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var rowsStackViewTopConstraint: NSLayoutConstraint!

    @IBOutlet private var topSeparatorLineHeightConstraint: NSLayoutConstraint!

    private weak var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?
    private weak var siteStatsInsightsDetailsDelegate: SiteStatsInsightsDelegate?
    private var dataRows = [StatsTotalRowData]()
    private typealias Style = WPStyleGuide.Stats
    private var forDetails = false

    // MARK: - Configure

    func configure(itemSubtitle: String,
                   dataSubtitle: String,
                   dataRows: [StatsTotalRowData],
                   siteStatsPeriodDelegate: SiteStatsPeriodDelegate? = nil,
                   siteStatsInsightsDetailsDelegate: SiteStatsInsightsDelegate? = nil,
                   forDetails: Bool = false) {
        itemSubtitleLabel.text = itemSubtitle
        dataSubtitleLabel.text = dataSubtitle
        self.dataRows = dataRows
        self.siteStatsPeriodDelegate = siteStatsPeriodDelegate
        self.siteStatsInsightsDetailsDelegate = siteStatsInsightsDetailsDelegate
        self.forDetails = forDetails
        bottomSeparatorLine.isHidden = forDetails

        if !forDetails {
        addRows(dataRows,
                toStackView: rowsStackView,
                forType: .period,
                limitRowsDisplayed: true,
                viewMoreDelegate: self)
        }

        setSubtitleVisibility()
        applyStyles()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeRowsFromStackView(rowsStackView)
    }
}

private extension CountriesCell {

    func applyStyles() {
        Style.configureCell(self)
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)
        Style.configureViewAsSeparator(topSeparatorLine)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

    func setSubtitleVisibility() {
        subtitleStackView.layoutIfNeeded()
        let subtitleHeight = subtitlesStackViewTopConstraint.constant * 2 + subtitleStackView.frame.height

        if forDetails {
            rowsStackViewTopConstraint.constant = subtitleHeight
            return
        }

        rowsStackViewTopConstraint.constant = !dataRows.isEmpty ? subtitleHeight : 0
        topSeparatorLineHeightConstraint.constant = dataRows.isEmpty ? 0.5 : 0.33
    }

}

// MARK: - ViewMoreRowDelegate

extension CountriesCell: ViewMoreRowDelegate {

    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        siteStatsPeriodDelegate?.viewMoreSelectedForStatSection?(statSection)
        siteStatsInsightsDetailsDelegate?.viewMoreSelectedForStatSection?(statSection)
    }

}
