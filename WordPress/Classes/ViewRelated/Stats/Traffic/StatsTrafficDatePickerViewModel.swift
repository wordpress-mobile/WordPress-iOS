import Foundation

class StatsTrafficDatePickerViewModel: ObservableObject {

    @Published var selectedPeriod: StatsPeriodUnit {
        didSet {
            currentDateInterval = StatsTrafficDatePickerViewModel.calculateDateInterval(for: selectedPeriod, oldDateInterval: currentDateInterval)
        }
    }

    @Published var currentDateInterval: DateInterval
    private let now: Date
    private static let calendar: Calendar = .current

    var isNextDateIntervalAvailable: Bool {
        let nextDateInterval = nextDateInterval()
        return nextDateInterval.start <= now
    }

    init(now: Date = Date()) {
        self.now = now
        let defaultPeriod: StatsPeriodUnit = .day
        selectedPeriod = defaultPeriod
        let defaultDateInterval = DateInterval(start: now, end: now) // Use today by default
        currentDateInterval = StatsTrafficDatePickerViewModel.calculateDateInterval(for: defaultPeriod, oldDateInterval: defaultDateInterval)
    }

    func goToPreviousDateInterval() {
        guard let newStartDate = StatsTrafficDatePickerViewModel.calendar.date(byAdding: selectedPeriod.calendarComponent, value: -1, to: currentDateInterval.start),
              let newEndDate = StatsTrafficDatePickerViewModel.calendar.date(byAdding: selectedPeriod.calendarComponent, value: -1, to: currentDateInterval.end) else {
            return
        }
        currentDateInterval = DateInterval(start: newStartDate, end: newEndDate)
    }

    func goToNextDateInterval() {
        currentDateInterval = nextDateInterval()
    }

    func nextDateInterval() -> DateInterval {
        guard let newStartDate = StatsTrafficDatePickerViewModel.calendar.date(byAdding: selectedPeriod.calendarComponent, value: 1, to: currentDateInterval.start),
              let newEndDate = StatsTrafficDatePickerViewModel.calendar.date(byAdding: selectedPeriod.calendarComponent, value: 1, to: currentDateInterval.end) else {
            return currentDateInterval
        }
        return DateInterval(start: newStartDate, end: newEndDate)
    }

    private static func calculateDateInterval(for period: StatsPeriodUnit, oldDateInterval: DateInterval) -> DateInterval {
        let anchorDate = oldDateInterval.start // The date in the date interval which stays fixed when the period changes

        switch period {
        case .day:
            return DateInterval(start: anchorDate, end: anchorDate)
        case .week:
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: anchorDate),    // Spans 8 days since end date is exclusive
                  let inclusiveEndDate = calendar.date(byAdding: .second, value: -1, to: weekInterval.end) else {
                return oldDateInterval
            }
            return DateInterval(start: anchorDate, end: inclusiveEndDate)
        case .month:
            guard let monthInterval = calendar.dateInterval(of: .month, for: anchorDate),
                  let inclusiveEndDate = calendar.date(byAdding: .second, value: -1, to: monthInterval.end) else {
                return oldDateInterval
            }
            return DateInterval(start: monthInterval.start, end: inclusiveEndDate)
        case .year:
            guard let yearInterval = calendar.dateInterval(of: .year, for: anchorDate),
                  let inclusiveEndDate = calendar.date(byAdding: .second, value: -1, to: yearInterval.end) else {
                return oldDateInterval
            }
            return DateInterval(start: yearInterval.start, end: inclusiveEndDate)
        }
    }

    func formattedCurrentInterval() -> String {
        let dateFormatter = selectedPeriod.dateFormatter
        if selectedPeriod == .week {
            return "\(dateFormatter.string(from: currentDateInterval.start)) - \(dateFormatter.string(from: currentDateInterval.end))"
        } else {
            return dateFormatter.string(from: currentDateInterval.start)
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
}
