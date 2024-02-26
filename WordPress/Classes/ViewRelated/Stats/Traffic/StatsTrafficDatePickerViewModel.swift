import Foundation

class StatsTrafficDatePickerViewModel: ObservableObject {

    @Published var selectedPeriod: StatsPeriodUnit {
        didSet {
            selectedPeriod.track()
        }
    }
    @Published var selectedDate: Date

    init(selectedPeriod: StatsPeriodUnit, selectedDate: Date) {
        self.selectedPeriod = selectedPeriod
        self.selectedDate = selectedDate
        selectedPeriod.track()
    }

    var isNextDateIntervalAvailable: Bool {
        return StatsPeriodHelper().dateAvailableAfterDate(selectedDate, period: selectedPeriod)
    }

    func goToPreviousDateInterval() {
        guard let newStartDate = StatsPeriodHelper().calculateEndDate(from: selectedDate, offsetBy: -1, unit: selectedPeriod) else {
            return
        }

        selectedDate = newStartDate

        WPAppAnalytics.track(
            .statsDateTappedBackward,
            withProperties: [StatsPeriodUnit.analyticsPeriodKey: selectedPeriod.description as Any],
            withBlogID: SiteStatsInformation.sharedInstance.siteID)
    }

    func goToNextDateInterval() {
        guard let newStartDate = StatsPeriodHelper().calculateEndDate(from: selectedDate, offsetBy: 1, unit: selectedPeriod) else {
            return
        }

        selectedDate = newStartDate

        WPAppAnalytics.track(
            .statsDateTappedForward,
            withProperties: [StatsPeriodUnit.analyticsPeriodKey: selectedPeriod.description as Any],
            withBlogID: SiteStatsInformation.sharedInstance.siteID)
    }

    func formattedCurrentInterval() -> String {
        let dateFormatter = selectedPeriod.dateFormatter
        if selectedPeriod == .week, let week = StatsPeriodHelper().weekIncludingDate(selectedDate) {
            return "\(dateFormatter.string(from: week.weekStart)) - \(dateFormatter.string(from: week.weekEnd))"
        } else {
            return dateFormatter.string(from: selectedDate)
        }
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
