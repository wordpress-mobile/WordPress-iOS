
struct RewindStatusRow: ImmuTableRow {

    typealias CellType = RewindStatusTableViewCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "RewindStatusTableViewCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()

    let action: ImmuTableAction? = nil

    let title: String
    let summary: String
    let progress: Float

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CellType

        cell.configureCell(title: title, summary: summary, progress: progress)
        cell.selectionStyle = .none
    }

}
