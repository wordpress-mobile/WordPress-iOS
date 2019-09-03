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

struct StatsGhostTabbedImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostTabbedCell.defaultNib, StatsGhostTabbedCell.self)
    }()
}

struct StatsGhostPostingActivitiesImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostPostingActivityCell.defaultNib, StatsGhostPostingActivityCell.self)
    }()
}

struct StatsGhostChartImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostChartCell.defaultNib, StatsGhostChartCell.self)
    }()
}

private enum GhostCellStyle {
    static let muriel = GhostStyle(beatDuration: TimeInterval(0.75),
                                   beatStartColor: .neutral(.shade0),
                                   beatEndColor: .neutral(.shade5))
}
