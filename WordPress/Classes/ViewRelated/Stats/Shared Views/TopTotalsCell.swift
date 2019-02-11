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
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private weak var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?
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
        initChildRows()

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

    // MARK: - Child Row Handling

    func initChildRows() {
        rowsStackView.arrangedSubviews.forEach { subview in
            guard let row = subview as? StatsTotalRow,
                row.hasChildRows else {
                    return
            }

            toggleChildRowsForRow(row)
        }
    }

    func addChildRowsForRow(_ row: StatsTotalRow) {

        guard let rowIndex = indexForRow(row),
            let childRows = row.rowData?.childRows else {
                return
        }

        // Make sure we don't duplicate child rows.
        removeChildRowsForRow(row)

        // Add child rows to their own stack view,
        // store that on the row (for possible removal later),
        // and add the child stack view to the cell's row stack view.

        let numberOfRowsToAdd = childRows.count > maxChildRowsToDisplay ? maxChildRowsToDisplay : childRows.count
        let childRowsStackView = childStackView()

        for childRowsIndex in 0..<numberOfRowsToAdd {
            let childRowData = childRows[childRowsIndex]
            let childRow = StatsTotalRow.loadFromNib()

            childRow.configure(rowData: childRowData, delegate: self)
            childRow.showSeparator = false

            // Show the expanded bottom separator on the last row
            childRow.showBottomExpandedSeparator = (childRowsIndex == numberOfRowsToAdd - 1)

            childRowsStackView.addArrangedSubview(childRow)
        }

        row.childRowsStackView = childRowsStackView
        rowsStackView.insertArrangedSubview(childRowsStackView, at: rowIndex + 1)
    }

    func removeChildRowsForRow(_ row: StatsTotalRow) {
        rowsStackView.removeArrangedSubview(row.childRowsStackView)
        row.childRowsStackView.removeFromSuperview()
    }

    func toggleSeparatorForRowPreviousTo(_ row: StatsTotalRow) {
        guard let rowIndex = indexForRow(row), (rowIndex - 1) > 0,
        let previousRow = rowsStackView.arrangedSubviews[rowIndex - 1] as? StatsTotalRow else {
            return
        }

        previousRow.showSeparator = !row.expanded
    }

    func indexForRow(_ row: StatsTotalRow) -> Int? {
        guard let rowView = rowsStackView.arrangedSubviews.first(where: ({ $0 == row })),
            let rowIndex = rowsStackView.arrangedSubviews.index(of: rowView) else {
                return nil
        }

        return rowIndex
    }

    func childStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fill
        return stackView
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

    func toggleChildRowsForRow(_ row: StatsTotalRow) {
        row.expanded ? addChildRowsForRow(row) : removeChildRowsForRow(row)
        toggleSeparatorForRowPreviousTo(row)
        siteStatsInsightsDelegate?.expandedRowUpdated?(row)
    }

}
