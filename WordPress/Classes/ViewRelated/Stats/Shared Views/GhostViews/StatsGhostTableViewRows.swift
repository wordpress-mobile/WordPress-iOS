protocol StatsRowGhostable: ImmuTableRow { }
extension StatsRowGhostable {
    var action: ImmuTableAction? {
        return nil
    }

    func configureCell(_ cell: UITableViewCell) {
        cell.startGhostAnimation()
    }
}

struct StatsGhostTwoColumnImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostTwoColumnCell.defaultNib, StatsGhostTwoColumnCell.self)
    }()
}
