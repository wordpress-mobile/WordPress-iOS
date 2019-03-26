import UIKit

class SiteStatsTableHeaderView: UITableViewHeaderFooterView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var backArrow: UIImageView!
    @IBOutlet weak var forwardArrow: UIImageView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    static let height: CGFloat = 44
    private typealias Style = WPStyleGuide.Stats
    private var date: Date?
    private var period: StatsPeriodUnit?

    private lazy var calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .autoupdatingCurrent
        return cal
    }()

    // MARK: - View

    override func awakeFromNib() {
        applyStyles()
    }

    func configure(date: Date?, period: StatsPeriodUnit?) {
        self.date = date
        self.period = period
        dateLabel.text = displayDate()
    }

}

private extension SiteStatsTableHeaderView {

    func applyStyles() {
        Style.configureLabelAsCellRowTitle(dateLabel)
        Style.configureViewAsSeparator(bottomSeparatorLine)
        backArrow.image = Style.imageForGridiconType(.chevronLeft, withTint: .darkGrey)
        forwardArrow.image = Style.imageForGridiconType(.chevronRight)
    }

    func displayDate() -> String? {
        guard let date = date, let period = period else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate(period.dateFormatTemplate)

        switch period {
        case .day, .month, .year:
            return dateFormatter.string(from: date)
        case .week:
            // Week is Monday - Sunday
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)

            let startDate = dateFormatter.string(from: weekStart)
            let endDate = (weekEnd != nil) ? dateFormatter.string(from: weekEnd!) : ""

            let weekFormat = NSLocalizedString("%@ - %@", comment: "Stats label for week date range. Ex: Mar 25 - Mar 31")
            return String.localizedStringWithFormat(weekFormat, startDate, endDate)
        }
    }

    @IBAction func didTapBackButton(_ sender: UIButton) {
        updateDate(forward: false)
    }

    @IBAction func didTapForwardButton(_ sender: UIButton) {
        updateDate(forward: true)
    }

    func updateDate(forward: Bool) {
        guard let date = date, let period = period else {
            return
        }

        let value = forward ? 1 : -1
        self.date = calendar.date(byAdding: period.calendarComponent, value: value, to: date)
        dateLabel.text = displayDate()
    }

}

private extension StatsPeriodUnit {

    var dateFormatTemplate: String {
        switch self {
        case .day:
            return "MMM d, yyyy"
        case .week:
            return "MMM d"
        case .month:
            return "MMM yyyy"
        case .year:
            return "yyyy"
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .day:
            return .day
        case .week:
            return .weekOfYear
        case .month:
            return .month
        case .year:
            return .year
        }
    }

}
