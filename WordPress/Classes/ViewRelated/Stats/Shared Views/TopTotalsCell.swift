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

    // If the subtitles are not shown, this is active.
    @IBOutlet weak var rowsStackViewTopConstraint: NSLayoutConstraint!
    // If the subtitles are shown, this is active.
    @IBOutlet weak var rowsStackViewTopConstraintWithSubtitles: NSLayoutConstraint!

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private var limitRowsDisplayed = true
    private let maxChildRowsToDisplay = 10
    private var dataRows = [StatsTotalRowData]()
    private var subtitlesProvided = true
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private weak var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?
    private weak var siteStatsDetailsDelegate: SiteStatsDetailsDelegate?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(itemSubtitle: String? = nil,
                   dataSubtitle: String? = nil,
                   dataRows: [StatsTotalRowData],
                   siteStatsInsightsDelegate: SiteStatsInsightsDelegate? = nil,
                   siteStatsPeriodDelegate: SiteStatsPeriodDelegate? = nil,
                   siteStatsDetailsDelegate: SiteStatsDetailsDelegate? = nil,
                   limitRowsDisplayed: Bool = true) {
        itemSubtitleLabel.text = itemSubtitle
        dataSubtitleLabel.text = dataSubtitle
        subtitlesProvided = (itemSubtitle != nil && dataSubtitle != nil)
        self.dataRows = dataRows
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate
        self.siteStatsPeriodDelegate = siteStatsPeriodDelegate
        self.siteStatsDetailsDelegate = siteStatsDetailsDelegate
        self.limitRowsDisplayed = limitRowsDisplayed

        let statType: StatType = (siteStatsPeriodDelegate != nil) ? .period : .insights

        addRows(dataRows,
                toStackView: rowsStackView,
                forType: statType,
                limitRowsDisplayed: limitRowsDisplayed,
                rowDelegate: self,
                viewMoreDelegate: self)

        setSubtitleVisibility()
        initChildRows()

        applyStyles()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        rowsStackView.arrangedSubviews.forEach { subview in

            // Remove granchild rows
            if let row = subview as? StatsTotalRow {
                removeChildRowsForRow(row)
            }

            // Remove child rows
            if let childView = subview as? StatsChildRowsView {
                removeRowsFromStackView(childView.rowsStackView)
            }
        }

        removeRowsFromStackView(rowsStackView)
    }

}

// MARK: - Private Extension

private extension TopTotalsCell {

    func applyStyles() {
        Style.configureCell(self)
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)
        Style.configureViewAsSeparator(topSeparatorLine)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

    /// Hide the subtitles if there is no data or Subtitles.
    ///
    func setSubtitleVisibility() {
        let showSubtitles = dataRows.count > 0 && subtitlesProvided
        subtitleStackView.isHidden = !showSubtitles
        rowsStackViewTopConstraint.isActive = !showSubtitles
        rowsStackViewTopConstraintWithSubtitles.isActive = showSubtitles
    }

    // MARK: - Child Row Handling

    func initChildRows() {
        rowsStackView.arrangedSubviews.forEach { subview in
            guard let row = subview as? StatsTotalRow else {
                    return
            }

            // On the Stats Detail view, do not expand rows initially.
            guard siteStatsDetailsDelegate == nil else {
                row.expanded = false
                return
            }

            toggleChildRowsForRow(row)

            row.childRowsView?.rowsStackView.arrangedSubviews.forEach { child in
                guard let childRow = child as? StatsTotalRow else {
                    return
                }
                toggleChildRowsForRow(childRow)
            }
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
        // and add the child view to the row stack view.

        let numberOfRowsToAdd = childRows.count > maxChildRowsToDisplay ? maxChildRowsToDisplay : childRows.count
        let containingStackView = stackViewContainingRow(row)
        let childRowsView = StatsChildRowsView.loadFromNib()

        for childRowsIndex in 0..<numberOfRowsToAdd {
            let childRowData = childRows[childRowsIndex]
            let childRow = StatsTotalRow.loadFromNib()

            childRow.configure(rowData: childRowData, delegate: self)
            childRow.showSeparator = false
            childRow.parentRow = row

            // If this child is just a child, then change the label color.
            // If this child is also a parent, then leave the color as default.
            if !childRow.hasChildRows {
                Style.configureLabelAsChildRowTitle(childRow.itemLabel)
            }

            // If the parent row has an icon, show the image view for the child
            // to make the child row appear "indented".
            // If the parent does not have an icon, don't indent the child row.
            childRow.imageView.isHidden = row.imageView.isHidden
            childRow.imageWidthConstraint.constant = row.imageWidthConstraint.constant

            childRowsView.rowsStackView.addArrangedSubview(childRow)
        }

        row.childRowsView = childRowsView
        containingStackView?.insertArrangedSubview(childRowsView, at: rowIndex + 1)
    }

    func removeChildRowsForRow(_ row: StatsTotalRow) {
        guard let childRowsView = row.childRowsView,
        let childRowsStackView = childRowsView.rowsStackView else {
            return
        }

        // If the row's children have children, remove those too.
        childRowsStackView.arrangedSubviews.forEach { subView in
            if let subView = subView as? StatsChildRowsView {
                removeRowsFromStackView(subView.rowsStackView)
            }
        }

        removeRowsFromStackView(childRowsStackView)
        stackViewContainingRow(row)?.removeArrangedSubview(childRowsView)
    }

    func toggleSeparatorsAroundRow(_ row: StatsTotalRow) {
        toggleSeparatorsBeforeRow(row)
        toggleSeparatorsAfterRow(row)
    }

    func toggleSeparatorsBeforeRow(_ row: StatsTotalRow) {
        guard let containingStackView = stackViewContainingRow(row),
            let rowIndex = indexForRow(row),
            (rowIndex - 1) >= 0 else {
                return
        }

        let previousRow = containingStackView.arrangedSubviews[rowIndex - 1]

        // Toggle the indented separator line only on top level rows. Children don't show them.
        if previousRow is StatsTotalRow && containingStackView == rowsStackView {
            (previousRow as! StatsTotalRow).showSeparator = !row.expanded
        }

        // Toggle the bottom line on the previous stack view
        if previousRow is StatsChildRowsView {
            (previousRow as! StatsChildRowsView).showBottomSeperatorLine = !row.expanded
        }

    }

    func toggleSeparatorsAfterRow(_ row: StatsTotalRow) {
        guard let containingStackView = stackViewContainingRow(row),
            let rowIndex = indexForRow(row),
            (rowIndex + 1) < containingStackView.arrangedSubviews.count else {
                return
        }

        let nextRow = containingStackView.arrangedSubviews[rowIndex + 1]

        // Toggle the indented separator line only on top level rows. Children don't show them.
        if nextRow is StatsTotalRow && containingStackView == rowsStackView {
            row.showSeparator = !(nextRow as! StatsTotalRow).expanded
        }

        // If the next row is a stack view, it is the children of this row.
        // Proceed to the next parent row, and toggle this row's bottom line
        // according to the next parent's expanded state.
        if nextRow is StatsChildRowsView {

            guard (rowIndex + 2) < containingStackView.arrangedSubviews.count,
                let nextParentRow = containingStackView.arrangedSubviews[rowIndex + 2] as? StatsTotalRow else {
                    return
            }

            row.childRowsView?.showBottomSeperatorLine = !nextParentRow.expanded
        }
    }

    func indexForRow(_ row: StatsTotalRow) -> Int? {
        guard let stackView = stackViewContainingRow(row),
            let rowView = stackView.arrangedSubviews.first(where: ({ $0 == row })),
            let rowIndex = stackView.arrangedSubviews.index(of: rowView) else {
                return nil
        }

        return rowIndex
    }

    func stackViewContainingRow(_ row: StatsTotalRow) -> UIStackView? {
        return row.parentRow?.childRowsView?.rowsStackView ?? rowsStackView
    }

}

// MARK: - StatsTotalRowDelegate

extension TopTotalsCell: StatsTotalRowDelegate {

    func displayWebViewWithURL(_ url: URL) {
        siteStatsInsightsDelegate?.displayWebViewWithURL?(url)
        siteStatsPeriodDelegate?.displayWebViewWithURL?(url)
        siteStatsDetailsDelegate?.displayWebViewWithURL?(url)
    }

    func displayMediaWithID(_ mediaID: NSNumber) {
        siteStatsPeriodDelegate?.displayMediaWithID?(mediaID)
        siteStatsDetailsDelegate?.displayMediaWithID?(mediaID)
    }

    func toggleChildRowsForRow(_ row: StatsTotalRow) {
        row.expanded ? addChildRowsForRow(row) : removeChildRowsForRow(row)
        toggleSeparatorsAroundRow(row)
        siteStatsInsightsDelegate?.expandedRowUpdated?(row)
        siteStatsPeriodDelegate?.expandedRowUpdated?(row)
        siteStatsDetailsDelegate?.expandedRowUpdated?(row)
    }

    func showPostStats(withPostTitle postTitle: String?, postURL: URL?) {
        siteStatsPeriodDelegate?.showPostStats?(withPostTitle: postTitle, postURL: postURL)
        siteStatsDetailsDelegate?.showPostStats?(withPostTitle: postTitle, postURL: postURL)
    }

}

// MARK: - ViewMoreRowDelegate

extension TopTotalsCell: ViewMoreRowDelegate {

    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        siteStatsInsightsDelegate?.viewMoreSelectedForStatSection?(statSection)
        siteStatsPeriodDelegate?.viewMoreSelectedForStatSection?(statSection)
    }

}
