import Foundation

struct ReferrerDetailsRow: ImmuTableRow {
    private typealias CellType = ReferrerDetailsCell

    static var cell = ImmuTableCell.class(CellType.self)
    var action: ImmuTableAction?
    var isLast = false

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CellType else {
            return
        }
        cell.configure(isLast: isLast)
    }
}
