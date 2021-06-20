import Foundation

struct ReferrerDetailsRow: ImmuTableRow {
    private typealias CellType = ReferrerDetailsCell

    static var cell = ImmuTableCell.class(CellType.self)
    var action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CellType else {
            return
        }
        cell.configure()
    }
}
