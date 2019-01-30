import UIKit

/// This cell type displays the top data rows for a Stat type, with optional subtitles for the items and data.
/// Ex: Insights Tags and Categories, Period Post and Pages.
/// If there are more than 6 data rows, a View more row is added to display the full list.
/// If a row is tapped, StatsTotalRowDelegate is informed to display the associated detail.
/// If the row has child rows, those child rows are added to the stack view below the selected row.
///

class TopTotalsCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var subtitleStackView: UIStackView!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!

    @IBOutlet weak var rowsStackViewTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private let maxChildRowsToDisplay = 10
    private let subtitlesBottomMargin: CGFloat = 7.0
    private var dataRows = [StatsTotalRowData]()
    private var subtitlesProvided = true
    private var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(itemSubtitle: String? = nil,
                   dataSubtitle: String? = nil,
                   dataRows: [StatsTotalRowData],
                   siteStatsInsightsDelegate: SiteStatsInsightsDelegate? = nil,
                   siteStatsPeriodDelegate: SiteStatsPeriodDelegate? = nil) {
        itemSubtitleLabel.text = itemSubtitle
        dataSubtitleLabel.text = dataSubtitle
        subtitlesProvided = (itemSubtitle != nil && dataSubtitle != nil)
        self.dataRows = dataRows
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate
        self.siteStatsPeriodDelegate = siteStatsPeriodDelegate

        setSubtitleVisibility()

        let statType: StatType = (siteStatsPeriodDelegate != nil) ? .period : .insights
        addRows(dataRows, toStackView: rowsStackView, forType: statType, rowDelegate: self)
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

    /// Hide the subtitles if there is no data or Subtitles.
    ///
    func setSubtitleVisibility() {
        let showSubtitles = dataRows.count > 0 && subtitlesProvided
        subtitleStackView.isHidden = !showSubtitles
        rowsStackViewTopConstraint.constant = showSubtitles ? subtitleStackView.frame.height + subtitlesBottomMargin : 0
    }

}

// MARK: - StatsTotalRowDelegate

extension TopTotalsCell: StatsTotalRowDelegate {

    func displayWebViewWithURL(_ url: URL) {
        siteStatsInsightsDelegate?.displayWebViewWithURL?(url)
        siteStatsPeriodDelegate?.displayWebViewWithURL?(url)
    }

    func displayMediaWithID(_ mediaID: NSNumber) {
        siteStatsPeriodDelegate?.displayMediaWithID?(mediaID)
    }

    func displayChildRowsForRow(_ row: StatsTotalRow) {

        // Find the row in the stackview, and the children of that row.
        guard let rowView = rowsStackView.arrangedSubviews.first(where: ({ $0 == row })),
            let rowIndex = rowsStackView.arrangedSubviews.index(of: rowView),
            let childRows = row.rowData?.childRows else {
                return
        }

        // On the parent row:
        // Hide the default bottom separator.
        // Show the expanded top separator.
        row.showSeparator = false
        row.showTopExpandedSeparator = true

        row.collapsed = false

        // On the row before the parent row, hide the default bottom separator.
        if (rowIndex - 1) > 0,
            let previousRow = rowsStackView.arrangedSubviews[rowIndex - 1] as? StatsTotalRow {
            previousRow.showSeparator = false
        }

        let numberOfRowsToAdd = childRows.count > maxChildRowsToDisplay ? maxChildRowsToDisplay : childRows.count
        var insertAtIndex = rowIndex + 1

        for childRowsIndex in 0..<numberOfRowsToAdd {
            let childRowData = childRows[childRowsIndex]
            let childRow = StatsTotalRow.loadFromNib()

            childRow.configure(rowData: childRowData, delegate: self)
            childRow.showSeparator = false

            // Show the expanded bottom separator on the last row
            childRow.showBottomExpandedSeparator = (insertAtIndex == (rowIndex + numberOfRowsToAdd))

            rowsStackView.insertArrangedSubview(childRow, at: insertAtIndex)
            insertAtIndex += 1
        }

        siteStatsInsightsDelegate?.expandedCellUpdated?()
    }

}
