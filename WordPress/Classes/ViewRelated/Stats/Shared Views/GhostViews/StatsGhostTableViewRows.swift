struct StatsGhostImmutableRow: ImmuTableRow {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostCell.defaultNib, StatsGhostCell.self)
    }()
    let action: ImmuTableAction? = nil

    private let view: NibLoadable

    init<View: NibLoadable>(view: View.Type) {
        self.view = view.self.loadFromNib()
    }

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? StatsGhostCell else {
            return
        }

        if let view = self.view as? UIView {
            cell.insert(view: view)
        }
    }
}

struct StatsGhostRow<View: NibLoadable> {
    static var row: ImmuTableRow {
        return StatsGhostImmutableRow(view: View.self)
    }
}
