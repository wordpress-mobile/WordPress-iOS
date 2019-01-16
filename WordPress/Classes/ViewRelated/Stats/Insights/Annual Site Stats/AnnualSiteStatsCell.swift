import UIKit

/// This cell type displays the Insights Annual Site Stats:
/// - Total Posts count
/// - Totals for Comments, Likes, and Words.
/// - Averages for Comments, Likes, and Words.
/// If there are no posts:
/// - StatsNoDataRow is displayed instead of Total Posts.
/// - The remainder of the cell is hidden.
/// The cell and rows have no functionality. The cell simply lists the data rows provided.
///

class AnnualSiteStatsCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var totalPostsStackView: UIStackView!
    @IBOutlet weak var bodyStackView: UIStackView!
    @IBOutlet weak var totalsStackView: UIStackView!
    @IBOutlet weak var averagesStackView: UIStackView!

    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var averageLabel: UILabel!

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(totalPostsRowData: StatsTotalRowData,
                   totalsDataRows: [StatsTotalRowData],
                   averagesDataRows: [StatsTotalRowData]) {
        addRows([totalPostsRowData], toStackView: totalPostsStackView, limitRowsDisplayed: false)
        addRows(totalsDataRows, toStackView: totalsStackView, limitRowsDisplayed: false)
        addRows(averagesDataRows, toStackView: averagesStackView, limitRowsDisplayed: false)

        applyStyles()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeRowsFromStackView(totalPostsStackView)
        removeRowsFromStackView(totalsStackView)
        removeRowsFromStackView(averagesStackView)
    }
}

private extension AnnualSiteStatsCell {

    func applyStyles() {
        Style.configureCell(self)
        totalLabel.text = NSLocalizedString("Total", comment: "'Annual Site Stats' label for the totals section.")
        averageLabel.text = NSLocalizedString("Average", comment: "'Annual Site Stats' label for the averages section.")
        Style.configureLabelAsSubtitle(totalLabel)
        Style.configureLabelAsSubtitle(averageLabel)
        Style.configureViewAsSeperator(topSeparatorLine)
        Style.configureViewAsSeperator(bottomSeparatorLine)
    }

}
