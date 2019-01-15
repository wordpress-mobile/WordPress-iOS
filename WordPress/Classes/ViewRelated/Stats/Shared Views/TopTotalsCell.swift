import UIKit

/// This cell type displays the top 6 data rows (controlled by maxNumberOfDataRows) for a Stat type,
/// with subtitles for the items and data.
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

    private let maxNumberOfDataRows = 6
    private var dataRows = [StatsTotalRowData]()
    private var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(itemSubtitle: String,
                   dataSubtitle: String,
                   dataRows: [StatsTotalRowData],
                   siteStatsInsightsDelegate: SiteStatsInsightsDelegate) {
        self.dataRows = dataRows
        itemSubtitleLabel.text = itemSubtitle
        dataSubtitleLabel.text = dataSubtitle
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate

        addRows()
        applyStyles()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeExistingRows()
    }

}

private extension TopTotalsCell {

    func addRows() {
        let numberOfDataRows = dataRows.count

        if numberOfDataRows == 0 {
            let row = StatsNoDataRow.loadFromNib()
            rowsStackView.addArrangedSubview(row)
            return
        }

        let numberOfRowsToAdd = numberOfDataRows > maxNumberOfDataRows ? maxNumberOfDataRows : numberOfDataRows

        for index in 0..<numberOfRowsToAdd {
            let dataRow = dataRows[index]
            let row = StatsTotalRow.loadFromNib()
            row.configure(rowData: dataRow, delegate: self)

            // Don't show the separator line on the last row.
            if index == (numberOfRowsToAdd - 1) {
                row.showSeparator = false
            }

            rowsStackView.addArrangedSubview(row)
        }

        // If there are more data rows, show 'View more'.
        if numberOfDataRows > maxNumberOfDataRows {
            addViewMoreRow()
        }
    }

    func addViewMoreRow() {
        let row = ViewMoreRow.loadFromNib()
        rowsStackView.addArrangedSubview(row)
    }

    func removeExistingRows() {
        rowsStackView.arrangedSubviews.forEach {
            rowsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

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
