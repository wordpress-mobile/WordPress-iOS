import Foundation

struct ReferrerDetailsHeaderRow: ImmuTableRow {
    private typealias CellType = ReferrerDetailsHeaderCell

    static var cell = ImmuTableCell.class(CellType.self)
    var action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CellType else {
            return
        }
        cell.configure(with: section)
    }
}

// MARK: - Private Computed Properties
private extension ReferrerDetailsHeaderRow {
    var section: StatSection {
        StatSection.periodReferrers
    }
}
