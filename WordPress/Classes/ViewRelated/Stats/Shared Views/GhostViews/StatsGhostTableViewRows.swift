struct StatsGhostImmutableRow: ImmuTableRow {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsStackViewCell.defaultNib, StatsStackViewCell.self)
    }()
    let action: ImmuTableAction? = nil

    private let view: NibLoadable

    init<View: NibLoadable>(view: View.Type) {
        self.view = view.self.loadFromNib()
    }

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? StatsStackViewCell else {
            return
        }

        if let view = self.view as? UIView {
            cell.insert(view: view)
        }
    }
}

extension StatsGhostImmutableRow {
    static var twoColumnRow: ImmuTableRow {
        return StatsGhostRow<StatsTwoColumnRow>.row
    }
}

private struct StatsGhostRow<View: NibLoadable> {
    static var row: ImmuTableRow {
        return StatsGhostImmutableRow(view: View.self)
    }
}
