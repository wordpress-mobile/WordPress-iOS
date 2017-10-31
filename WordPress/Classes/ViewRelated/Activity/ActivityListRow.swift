import Gridicons

struct ActivityListRow: ImmuTableRow {
    typealias CellType = ActivityTableViewCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "ActivityTableViewCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()

    let activity: Activity
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CellType
        cell.configureCell(activity)
        cell.selectionStyle = .none
    }
}
