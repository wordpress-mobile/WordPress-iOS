import WordPressUI

protocol StatsRowGhostable: HashableImmuTableRow {
    var statSection: StatSection? { get }
}

extension StatsRowGhostable {
    var action: ImmuTableAction? {
        return nil
    }

    var statSection: StatSection? {
        return nil
    }

    func configureCell(_ cell: UITableViewCell) {
        DispatchQueue.main.async {
            cell.startGhostAnimation(style: GhostCellStyle.muriel)
        }

        if let detailCell = cell as? StatsBaseCell {
            detailCell.statSection = statSection
        }
    }
}

struct StatsGhostGrowAudienceImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostGrowAudienceCell.defaultNib, StatsGhostGrowAudienceCell.self)
    }()

    var statSection: StatSection? = nil
}

struct StatsGhostTwoColumnImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostTwoColumnCell.defaultNib, StatsGhostTwoColumnCell.self)
    }()

    var statSection: StatSection? = nil
}

struct StatsGhostTopImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostTopCell.defaultNib, StatsGhostTopCell.self)
    }()

    var hideTopBorder = false
    var hideBottomBorder = false
    var statSection: StatSection? = nil

    // MARK: - Hashable

    static func == (lhs: StatsGhostTopImmutableRow, rhs: StatsGhostTopImmutableRow) -> Bool {
        return lhs.hideTopBorder == rhs.hideTopBorder &&
            lhs.hideBottomBorder == rhs.hideBottomBorder &&
            lhs.statSection == rhs.statSection
    }

    func configureCell(_ cell: UITableViewCell) {
        DispatchQueue.main.async {
            cell.startGhostAnimation(style: GhostCellStyle.muriel)
        }

        if let detailCell = cell as? StatsGhostTopCell {
            detailCell.topBorder?.isHidden = hideTopBorder
            detailCell.bottomBorder?.isHidden = hideBottomBorder
            detailCell.statSection = statSection
        }
    }
}

struct StatsGhostTopHeaderImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostTopHeaderCell.defaultNib, StatsGhostTopHeaderCell.self)
    }()
}

struct StatsGhostTabbedImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostTabbedCell.defaultNib, StatsGhostTabbedCell.self)
    }()

    var statSection: StatSection? = nil
}

struct StatsGhostPostingActivitiesImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostPostingActivityCell.defaultNib, StatsGhostPostingActivityCell.self)
    }()

    var statSection: StatSection? = nil
}

struct StatsGhostChartImmutableRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostChartCell.defaultNib, StatsGhostChartCell.self)
    }()

    var statSection: StatSection?
}

struct StatsGhostDetailRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostSingleRowCell.defaultNib, StatsGhostSingleRowCell.self)
    }()

    var hideTopBorder = false
    var isLastRow = false
    var enableTopPadding = false

    func configureCell(_ cell: UITableViewCell) {
        DispatchQueue.main.async {
            cell.startGhostAnimation(style: GhostCellStyle.muriel)
        }

        if let detailCell = cell as? StatsGhostSingleRowCell {
            detailCell.topBorder?.isHidden = hideTopBorder
            detailCell.isLastRow = isLastRow
            detailCell.enableTopPadding = enableTopPadding
        }
    }
}

struct StatsGhostTitleRow: StatsRowGhostable {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsGhostTitleCell.defaultNib, StatsGhostTitleCell.self)
    }()
}

enum GhostCellStyle {
    static let muriel = GhostStyle(beatStartColor: .placeholderElement, beatEndColor: .placeholderElementFaded)
}
