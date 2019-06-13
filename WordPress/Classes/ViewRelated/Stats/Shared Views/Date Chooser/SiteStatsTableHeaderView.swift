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

    // Limits how far back the date chooser can go.
    // Corresponds to the number of bars shown on the Overview chart.
    static let defaultPeriodCount = 14
    private var expectedPeriodCount = SiteStatsTableHeaderView.defaultPeriodCount
    private var backLimit: Int {
        return -(expectedPeriodCount - 1)
    }

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

    func configure(date: Date?, period: StatsPeriodUnit?, delegate: SiteStatsTableHeaderDelegate, expectedPeriodCount: Int = SiteStatsTableHeaderView.defaultPeriodCount) {
        self.date = date
        self.period = period
        self.delegate = delegate
        self.expectedPeriodCount = expectedPeriodCount
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

            return "\(dateFormatter.string(from: weekStart)) – \(dateFormatter.string(from: weekEnd))"
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

        self.date = calculateEndDate(startDate: date, offsetBy: value, unit: period)

        delegate?.dateChangedTo(self.date)
        dateLabel.text = displayDate()
        updateButtonStates()
    }

    func updateButtonStates() {

        // Use dates without time
        let currentDate = Date().normalizedDate()

        guard var date = date,
            let period = period,
            var oldestDate = calendar.date(byAdding: period.calendarComponent, value: backLimit, to: currentDate) else {
            backButton.isEnabled = false
            forwardButton.isEnabled = false
            updateArrowStates()
            return
        }

        date = date.normalizedDate()
        oldestDate = oldestDate.normalizedDate()

        switch period {
        case .day:
            forwardButton.isEnabled = date < currentDate
            backButton.isEnabled = date > oldestDate
        case .week:
            let week = weekIncludingDate(date)
            if let weekStart = week?.weekStart,
                let weekEnd = week?.weekEnd,
                let currentWeekEnd = weekIncludingDate(currentDate)?.weekEnd,
                let oldestWeekStart = weekIncludingDate(oldestDate)?.weekStart {
                forwardButton.isEnabled = weekEnd < currentWeekEnd
                backButton.isEnabled = weekStart > oldestWeekStart
            } else {
                forwardButton.isEnabled = false
                backButton.isEnabled = false
            }
        case .month:
            if let month = monthFromDate(date),
                let currentMonth = monthFromDate(currentDate),
                let oldestMonth = monthFromDate(oldestDate) {
                forwardButton.isEnabled = month < currentMonth
                backButton.isEnabled = month > oldestMonth
            } else {
                backButton.isEnabled = false
                forwardButton.isEnabled = false
            }
        case .year:
            let year = yearFromDate(date)
            forwardButton.isEnabled = year < yearFromDate(currentDate)
            backButton.isEnabled = year > yearFromDate(oldestDate)
        }

        updateArrowStates()
    }

    func updateArrowStates() {
        forwardArrow.image = Style.imageForGridiconType(.chevronRight, withTint: (forwardButton.isEnabled ? .darkGrey : .grey))
        backArrow.image = Style.imageForGridiconType(.chevronLeft, withTint: (backButton.isEnabled ? .darkGrey : .grey))
    }

    // MARK: - Date Helpers

    func weekIncludingDate(_ date: Date) -> (weekStart: Date, weekEnd: Date)? {
        // Note: Week is Monday - Sunday

        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                return nil
        }

        return (weekStart, weekEnd)
    }

    func monthFromDate(_ date: Date) -> Date? {
        let dateComponents = calendar.dateComponents([.month, .year], from: date)
        return calendar.date(from: dateComponents)
    }

    func yearFromDate(_ date: Date) -> Int {
        return calendar.component(.year, from: date)
    }
}

extension SiteStatsTableHeaderView: StatsBarChartViewDelegate {
    func statsBarChartValueSelected(_ statsBarChartView: StatsBarChartView, entryIndex: Int, entryCount: Int) {
        guard let period = period, entryCount > 0, entryCount <= SiteStatsTableHeaderView.defaultPeriodCount else {
            return
        }

        let periodShift = -((entryCount - 1) - entryIndex)

        self.date = calculateEndDate(startDate: Date().normalizedDate(), offsetBy: periodShift, unit: period)

        delegate?.dateChangedTo(self.date)
        dateLabel.text = displayDate()
        updateButtonStates()
    }
}

private extension SiteStatsTableHeaderView {
    func calculateEndDate(startDate: Date, offsetBy count: Int = 1, unit: StatsPeriodUnit) -> Date? {
        let calendar = Calendar.autoupdatingCurrent

        guard let adjustedDate = calendar.date(byAdding: unit.calendarComponent, value: count, to: startDate) else {
            DDLogError("[Stats] Couldn't do basic math on Calendars in Stats. Returning original value.")
            return startDate
        }

        switch unit {
        case .day:
            return adjustedDate.normalizedDate()

        case .week:

            // The hours component here is because the `dateInterval` returnd by Calendar is a closed range
            // — so the "end" of a specific week is also simultenously a 'start' of the next one.
            // This causes problem when calling this math on dates that _already are_ an end/start of a week.
            // This doesn't work for our calculations, so we force it to rollover using this hack.
            // (I *think* that's what's happening here. Doing Calendar math on this method has broken my brain.
            // I spend like 10h on this ~50 LoC method. Beware.)
            let components = DateComponents(day: 7 * count, hour: -12)

            guard let weekAdjusted = calendar.date(byAdding: components, to: startDate.normalizedDate()) else {
                DDLogError("[Stats] Couldn't add a multiple of 7 days and -12 hours to a date in Stats. Returning original value.")
                return startDate
            }

            let endOfAdjustedWeek = calendar.dateInterval(of: .weekOfYear, for: weekAdjusted)?.end

            return endOfAdjustedWeek?.normalizedDate()

        case .month:
            guard let maxComponent = calendar.range(of: .day, in: .month, for: adjustedDate)?.max() else {
                DDLogError("[Stats] Couldn't determine number of days in a given month in Stats. Returning original value.")
                return startDate
            }

            return calendar.date(bySetting: .day, value: maxComponent, of: adjustedDate)?.normalizedDate()

        case .year:
            guard
                let maxMonth = calendar.range(of: .month, in: .year, for: adjustedDate)?.max(),
                let adjustedMonthDate = calendar.date(bySetting: .month, value: maxMonth, of: adjustedDate),
                let maxDay = calendar.range(of: .day, in: .month, for: adjustedMonthDate)?.max() else {
                    DDLogError("[Stats] Couldn't determine number of months in a given year, or days in a given monthin Stats. Returning original value.")
                    return startDate
            }
            let adjustedDayDate = calendar.date(bySetting: .day, value: maxDay, of: adjustedMonthDate)

            return adjustedDayDate?.normalizedDate()
        }
    }
}
