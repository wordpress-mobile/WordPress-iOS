class StatsGhostBaseCell: UITableViewCell {
    private typealias Style = WPStyleGuide.Stats
    private(set) var topBorder: UIView?
    private(set) var bottomBorder: UIView?

    override func awakeFromNib() {
        super.awakeFromNib()
        Style.configureCell(self)
        setupBorders()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopGhostAnimation()
    }

    private func setupBorders() {
        topBorder = addTopBorder(withColor: .divider)
        topBorder?.isGhostableDisabled = true

        bottomBorder = addBottomBorder(withColor: .divider)
        bottomBorder?.isGhostableDisabled = true
    }
}

class StatsGhostTwoColumnCell: StatsGhostBaseCell, NibLoadable { }
class StatsGhostTopCell: StatsGhostBaseCell, NibLoadable { }
class StatsGhostTopHeaderCell: StatsGhostBaseCell, NibLoadable {
    override func awakeFromNib() {
        super.awakeFromNib()
        topBorder?.removeFromSuperview()
        bottomBorder?.removeFromSuperview()
    }
}
class StatsGhostChartCell: StatsGhostBaseCell, NibLoadable { }
class StatsGhostTabbedCell: StatsGhostBaseCell, NibLoadable { }
class StatsGhostTitleCell: StatsGhostBaseCell, NibLoadable {
    override func awakeFromNib() {
        super.awakeFromNib()
        topBorder?.isHidden = true
    }
}
class StatsGhostSingleRowCell: StatsGhostBaseCell, NibLoadable {
    @IBOutlet private var border: UIView! {
        didSet {
            border.backgroundColor = .divider
            border.isGhostableDisabled = true
        }
    }
    @IBOutlet private var imageTopConstraint: NSLayoutConstraint!
    @IBOutlet private var labelTopConstraint: NSLayoutConstraint!
    @IBOutlet private var borderLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var borderHeightConstraint: NSLayoutConstraint! {
        didSet {
            borderHeightConstraint.constant = .hairlineBorderWidth
        }
    }

    var enableTopPadding: Bool = false {
        didSet {
            imageTopConstraint.isActive = !enableTopPadding
            labelTopConstraint.isActive = !enableTopPadding
        }
    }

    var isLastRow: Bool = false {
        didSet {
            borderLeadingConstraint.isActive = isLastRow
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        bottomBorder?.removeFromSuperview()
    }
}
class StatsGhostPostingActivityCell: StatsGhostBaseCell, NibLoadable {
    private var monthData: [PostingStreakEvent] = {
        return Date().getAllDays().map { PostingStreakEvent(date: $0, postCount: 0) }
    }()

    @IBOutlet private var stackView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()

        for _ in 0...2 {
            let monthView = PostingActivityMonth.loadFromNib()
            monthView.configureGhost(monthData: monthData)
            stackView.addArrangedSubview(monthView)
        }
    }
}

fileprivate extension Date {
    mutating func add(days: Int) {
        self = Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    func firstDayOfTheMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.month, .year], from: self)) ?? self
    }

    func getAllDays() -> [Date] {
        var days: [Date] = []
        let range = Calendar.current.range(of: .day, in: .month, for: self)!
        var day = firstDayOfTheMonth()

        for _ in 1...range.count {
            days.append(day)
            day.add(days: 1)
        }

        return days
    }
}
