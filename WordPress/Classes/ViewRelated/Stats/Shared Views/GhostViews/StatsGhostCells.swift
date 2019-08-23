class StatsGhostBaseCell: UITableViewCell {
    private typealias Style = WPStyleGuide.Stats

    override func awakeFromNib() {
        super.awakeFromNib()
        Style.configureCell(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopGhostAnimation()
    }
}

class StatsGhostTwoColumnCell: StatsGhostBaseCell, NibLoadable { }
class StatsGhostTopCell: StatsGhostBaseCell, NibLoadable { }
class StatsGhostTabbedCell: StatsGhostBaseCell, NibLoadable { }
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
