protocol StatsRowGhostable: ImmuTableRow { }
extension StatsRowGhostable {
    var action: ImmuTableAction? {
        return nil
    }

    func configureCell(_ cell: UITableViewCell) {
        DispatchQueue.main.async {
            cell.startGhostAnimation(style: GhostCellStyle.muriel)
        }
    }
}

struct StatsGhostTwoColumnImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostTwoColumnCell.defaultNib, StatsGhostTwoColumnCell.self)
    }()
}

struct StatsGhostTopImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostTopCell.defaultNib, StatsGhostTopCell.self)
    }()
}

private enum GhostCellStyle {
    static let muriel = GhostStyle(beatDuration: TimeInterval(0.75),
                                   beatStartColor: .neutral(shade: .shade0),
                                   beatEndColor: .neutral(shade: .shade5))
}
