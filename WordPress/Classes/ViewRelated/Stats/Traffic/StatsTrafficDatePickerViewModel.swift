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
        if selectedPeriod == .week, let endDate = StatsPeriodHelper().calculateEndDate(from: selectedDate, offsetBy: 1, unit: .week) {
            return "\(dateFormatter.string(from: selectedDate)) - \(dateFormatter.string(from: endDate))"
        } else {
            return dateFormatter.string(from: selectedDate)
        }
    }
}

private extension StatsPeriodUnit {
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch self {
        case .day:
            formatter.dateFormat = "MMMM d"
        case .week:
            formatter.dateFormat = "MMM d"
        case .month:
            formatter.dateFormat = "MMMM"
        case .year:
            formatter.dateFormat = "yyyy"
        }
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
