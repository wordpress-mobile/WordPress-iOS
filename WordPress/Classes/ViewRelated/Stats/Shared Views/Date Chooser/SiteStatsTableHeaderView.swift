import UIKit

protocol SiteStatsTableHeaderDelegate: class {
    func dateChangedTo(_ newDate: Date?)
}

class SiteStatsTableHeaderView: UITableViewHeaderFooterView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var backArrow: UIImageView!
    @IBOutlet weak var forwardArrow: UIImageView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!

    static let height: CGFloat = 44
    private typealias Style = WPStyleGuide.Stats
    private weak var delegate: SiteStatsTableHeaderDelegate?
    private var date: Date?
    private var period: StatsPeriodUnit?

    private lazy var calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .autoupdatingCurrent
        return cal
    }()

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(date: Date?, period: StatsPeriodUnit?, delegate: SiteStatsTableHeaderDelegate) {
        self.date = date
        self.period = period
        self.delegate = delegate
        dateLabel.text = displayDate()
        updateButtonStates()
    }

}

private extension SiteStatsTableHeaderView {

    func applyStyles() {
        Style.configureLabelAsCellRowTitle(dateLabel)
        Style.configureViewAsSeparator(bottomSeparatorLine)
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
            let week = weekIncludingDate(date)
            guard let weekStart = week?.weekStart, let weekEnd = week?.weekEnd else {
                return nil
            }

            let startDate = dateFormatter.string(from: weekStart)
            let endDate = dateFormatter.string(from: weekEnd)

            let weekFormat = NSLocalizedString("%@ - %@", comment: "Stats label for week date range. Ex: Mar 25 - Mar 31")
            return String.localizedStringWithFormat(weekFormat, startDate, endDate)
        }
    }

    func weekIncludingDate(_ date: Date) -> (weekStart: Date, weekEnd: Date)? {
        // Note: Week is Monday - Sunday

        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                return nil
        }

        return (weekStart, weekEnd)
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
        delegate?.dateChangedTo(self.date)
        dateLabel.text = displayDate()
        updateButtonStates()
    }

    func updateButtonStates() {

        guard let date = date, let period = period else {
            backButton.isEnabled = false
            forwardButton.isEnabled = false
            updateArrowStates()
            return
        }

        // Use dates without time
        let normalizedDate = date.normalizedDate()
        let normalizedCurrentDate = Date().normalizedDate()

        switch period {
        case .day:
            forwardButton.isEnabled = normalizedDate < normalizedCurrentDate
        case .week:
            if let weekEnd = weekIncludingDate(normalizedDate)?.weekEnd,
                let currentWeekEnd = weekIncludingDate(normalizedCurrentDate)?.weekEnd {
                forwardButton.isEnabled = weekEnd < currentWeekEnd
            } else {
                forwardButton.isEnabled = false
            }
        case .month:
            let dateComponents = calendar.dateComponents([.month, .year], from: normalizedDate)
            let month = calendar.date(from: dateComponents)
            let currentDateComponents = calendar.dateComponents([.month, .year], from: normalizedCurrentDate)
            let currentMonth = calendar.date(from: currentDateComponents)

            if month != nil && currentMonth != nil {
                forwardButton.isEnabled = month! < currentMonth!
            } else {
                forwardButton.isEnabled = false
            }
        case .year:
            let year = calendar.component(.year, from: normalizedDate)
            let currentYear = calendar.component(.year, from: normalizedCurrentDate)
            forwardButton.isEnabled = year < currentYear
        }

        updateArrowStates()
    }

    func updateArrowStates() {
        forwardArrow.image = Style.imageForGridiconType(.chevronRight, withTint: (forwardButton.isEnabled ? .darkGrey : .grey))
        backArrow.image = Style.imageForGridiconType(.chevronLeft, withTint: (backButton.isEnabled ? .darkGrey : .grey))
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
