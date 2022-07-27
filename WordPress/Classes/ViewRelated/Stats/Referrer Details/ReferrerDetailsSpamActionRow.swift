import Foundation

struct ReferrerDetailsSpamActionRow: ImmuTableRow {
    private typealias CellType = ReferrerDetailsSpamActionCell

    static var cell = ImmuTableCell.class(CellType.self)
    var action: ImmuTableAction?
    var isSpam: Bool
    var isLoading: Bool

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CellType else {
            return
        }
        cell.configure(markAsSpam: !isSpam, isLoading: isLoading)
    }
}
