import UIKit

class AnnualSiteStatsCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var totalPostsStackView: UIStackView!
    @IBOutlet weak var bodyStackView: UIStackView!
    @IBOutlet weak var totalsStackView: UIStackView!
    @IBOutlet weak var averagesStackView: UIStackView!

    // MARK: - Configure

    func configure(totalPostsRowData: StatsTotalRowData,
                   totalsDataRows: [StatsTotalRowData],
                   averagesDataRows: [StatsTotalRowData]) {
        addRows([totalPostsRowData], toStackView: totalPostsStackView, limitRowsDisplayed: false)
        addRows(totalsDataRows, toStackView: totalsStackView, limitRowsDisplayed: false)
        addRows(averagesDataRows, toStackView: averagesStackView, limitRowsDisplayed: false)
    }

}
