import Foundation

typealias SiteCurrentDateGetter = () -> Date

class StatsTrafficDatePickerViewModel: ObservableObject {

    @Published var period: StatsPeriodUnit {
        didSet {
            period.track()
        }
    }
    @Published var date: Date

    private let getCurrentDateForSite: SiteCurrentDateGetter

    init(period: StatsPeriodUnit,
         date: Date,
         currentDateGetter: @escaping SiteCurrentDateGetter = StatsDataHelper.currentDateForSite
    ) {
        self.period = period
        self.date = date
        self.getCurrentDateForSite = currentDateGetter
        period.track()
    }

    var isNextPeriodAvailable: Bool {
        return StatsPeriodHelper().dateAvailableAfterDate(date, period: period)
    }

    func goToPreviousPeriod() {
        date = StatsDataHelper.calendar.date(byAdding: period.calendarComponent, value: -1, to: date) ?? date
        track(isNext: false)
    }

    func goToNextPeriod() {
        let nextDate = StatsDataHelper.calendar.date(byAdding: period.calendarComponent, value: 1, to: date) ?? date
        date = min(nextDate, getCurrentDateForSite())
        track(isNext: true)
    }

    func formattedCurrentPeriod() -> String {
        let dateFormatter = period.dateFormatter
        if period == .week, let week = StatsPeriodHelper().weekIncludingDate(date) {
            return "\(dateFormatter.string(from: week.weekStart)) - \(dateFormatter.string(from: week.weekEnd))"
        } else {
            return dateFormatter.string(from: date)
        }
    }

    func track(isNext: Bool) {
        WPAppAnalytics.track(
            isNext ? .statsDateTappedForward : .statsDateTappedBackward,
            withProperties: [StatsPeriodUnit.analyticsPeriodKey: period.description as Any],
            withBlogID: SiteStatsInformation.sharedInstance.siteID)
    }
}

private extension StatsPeriodUnit {
    var dateFormatter: DateFormatter {
        let format: String
        switch self {
        case .day:
            format = "MMMM d"
        case .week:
            format = "MMM d"
        case .month:
            format = "MMMM"
        case .year:
            format = "yyyy"
        }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate(format)
        return formatter
    }

    var event: WPAnalyticsStat {
        switch self {
        case .day:
            return .statsPeriodDaysAccessed
        case .week:
            return .statsPeriodWeeksAccessed
        case .month:
            return .statsPeriodMonthsAccessed
        case .year:
            return .statsPeriodYearsAccessed
        }
    }

    func track() {
        WPAppAnalytics.track(event, withBlogID: SiteStatsInformation.sharedInstance.siteID)
    }
}
