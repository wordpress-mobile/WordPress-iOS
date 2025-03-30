import Foundation
import WordPressShared

typealias SiteCurrentDateGetter = () -> Date

class StatsTrafficDatePickerViewModel: ObservableObject {

    @Published var period: StatsPeriodUnit {
        didSet {
            updateDate(getCurrentDateForSite())
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

    var isPreviousPeriodAvailable: Bool {
        let backLimit = -(SiteStatsTableHeaderView.defaultPeriodCount - 1)
        return StatsPeriodHelper().dateAvailableBeforeDate(date, period: period, backLimit: backLimit)
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
            let weekEndFormatter = DateFormatter()
            weekEndFormatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
            return "\(dateFormatter.string(from: week.weekStart)) - \(weekEndFormatter.string(from: week.weekEnd))"
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

    func updateDate(_ date: Date) {
        self.date = StatsPeriodHelper().endDate(from: date, period: period)
    }
}

private extension StatsPeriodUnit {
    var dateFormatter: DateFormatter {
        let format: String
        switch self {
        case .day:
            format = "MMMM d, yyyy"
        case .week:
            format = "MMM d"
        case .month:
            format = "MMMM, yyyy"
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
