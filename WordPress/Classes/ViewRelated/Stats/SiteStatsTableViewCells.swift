import UIKit
import WordPressComStatsiOS

// MARK: - ImmuTableRow Structs

struct LatestPostSummaryRow: ImmuTableRow {

    typealias CellType = LatestPostSummaryCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "LatestPostSummaryCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()

    let summaryData: StatsLatestPostSummary?
    let siteStatsInsightsDelegate: SiteStatsInsightsDelegate
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(withData: summaryData, andDelegate: siteStatsInsightsDelegate)

    }
}
