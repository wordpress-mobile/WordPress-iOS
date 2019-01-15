import UIKit

/// This cell type displays the top data rows for a Stat type, with subtitles for the items and data.
/// Ex: Insights Tags and Categories, Period Post and Pages.
/// If there are more than 6 data rows, a View more row is added to display the full list.
/// If a row is tapped, a webView is displayed (via StatsTotalRowDelegate) with the data row URL.
///

class TopTotalsCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(itemSubtitle: String,
                   dataSubtitle: String,
                   dataRows: [StatsTotalRowData],
                   siteStatsInsightsDelegate: SiteStatsInsightsDelegate) {
        itemSubtitleLabel.text = itemSubtitle
        dataSubtitleLabel.text = dataSubtitle
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate

        addRows(dataRows, toStackView: rowsStackView, rowDelegate: self)
        applyStyles()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeRowsFromStackView(rowsStackView)
    }

}

private extension TopTotalsCell {

    func applyStyles() {
        Style.configureCell(self)
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)
        Style.configureViewAsSeperator(topSeparatorLine)
        Style.configureViewAsSeperator(bottomSeparatorLine)
    }

}

// MARK: - StatsTotalRowDelegate

extension TopTotalsCell: StatsTotalRowDelegate {

    func displayWebViewWithURL(_ url: URL) {
        siteStatsInsightsDelegate?.displayWebViewWithURL?(url)
    }

}
