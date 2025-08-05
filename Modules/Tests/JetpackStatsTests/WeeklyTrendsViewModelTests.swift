import Testing
import Foundation
@testable import JetpackStats

@Suite("WeeklyTrendsViewModel Tests")
@MainActor
struct WeeklyTrendsViewModelTests {

    private let calendar = Calendar.mock(timeZone: TimeZone(secondsFromGMT: 0)!)

    // MARK: - Initialization Tests

    @Test("Initializes with data points")
    func initialization() {
        // Given
        let dataPoints = [
            DataPoint(date: Date("2025-01-01T00:00:00Z"), value: 100),
            DataPoint(date: Date("2025-01-02T00:00:00Z"), value: 150),
            DataPoint(date: Date("2025-01-08T00:00:00Z"), value: 200),
            DataPoint(date: Date("2025-01-09T00:00:00Z"), value: 250)
        ]

        // When
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        // Then
        #expect(viewModel.weeks.count == 2)
        #expect(viewModel.metric == .views)
        #expect(viewModel.calendar == calendar)
        #expect(viewModel.maxValue > 0)
    }

    @Test("Handles empty data points")
    func emptyDataPoints() {
        // Given
        let dataPoints: [DataPoint] = []

        // When
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        // Then
        #expect(viewModel.weeks.count == 0)
        #expect(viewModel.maxValue == 1)
    }

    // MARK: - Week Processing Tests

    @Test("Sorts weeks by most recent first")
    func weeksAreSortedByMostRecent() {
        // Given
        let dataPoints = [
            // Week 1: Dec 29, 2024 - Jan 4, 2025
            DataPoint(date: Date("2024-12-29T00:00:00Z"), value: 100),
            DataPoint(date: Date("2024-12-30T00:00:00Z"), value: 110),
            DataPoint(date: Date("2025-01-01T00:00:00Z"), value: 120),
            // Week 2: Jan 5-11, 2025
            DataPoint(date: Date("2025-01-05T00:00:00Z"), value: 130),
            DataPoint(date: Date("2025-01-06T00:00:00Z"), value: 140),
            DataPoint(date: Date("2025-01-07T00:00:00Z"), value: 150),
            // Week 3: Jan 12-18, 2025
            DataPoint(date: Date("2025-01-12T00:00:00Z"), value: 160),
            DataPoint(date: Date("2025-01-13T00:00:00Z"), value: 170),
            DataPoint(date: Date("2025-01-14T00:00:00Z"), value: 180)
        ]

        // When
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        // Then
        #expect(viewModel.weeks.count == 3)
        for i in 0..<viewModel.weeks.count - 1 {
            #expect(viewModel.weeks[i].startDate > viewModel.weeks[i + 1].startDate)
        }
    }

    @Test("Limits to five most recent weeks")
    func limitsToFiveMostRecentWeeks() {
        // Given
        var dataPoints: [DataPoint] = []
        let baseDate = Date("2025-01-15T00:00:00Z")

        // Create 8 weeks of data
        for weekOffset in 0..<8 {
            for dayOffset in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -(weekOffset * 7 + dayOffset), to: baseDate)!
                dataPoints.append(DataPoint(date: date, value: 100 + weekOffset * 10 + dayOffset))
            }
        }

        // When
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        // Then
        #expect(viewModel.weeks.count == 5)
        // Verify they are the most recent weeks
        for i in 0..<viewModel.weeks.count - 1 {
            #expect(viewModel.weeks[i].startDate > viewModel.weeks[i + 1].startDate)
        }
    }

    @Test("Sorts days within week")
    func daysWithinWeekAreSorted() {
        // Given - shuffled days within a single week
        let dataPoints = [
            DataPoint(date: Date("2025-01-08T00:00:00Z"), value: 130), // Wed
            DataPoint(date: Date("2025-01-06T00:00:00Z"), value: 110), // Mon
            DataPoint(date: Date("2025-01-10T00:00:00Z"), value: 150), // Fri
            DataPoint(date: Date("2025-01-05T00:00:00Z"), value: 100), // Sun
            DataPoint(date: Date("2025-01-07T00:00:00Z"), value: 120), // Tue
            DataPoint(date: Date("2025-01-09T00:00:00Z"), value: 140), // Thu
            DataPoint(date: Date("2025-01-11T00:00:00Z"), value: 160)  // Sat
        ]

        // When
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        // Then
        #expect(viewModel.weeks.count == 1)
        let week = viewModel.weeks[0]
        #expect(week.days.count == 7)
        for i in 0..<week.days.count - 1 {
            #expect(week.days[i].date < week.days[i + 1].date)
        }
    }

    // MARK: - Formatting Tests

    @Test("Formats week label correctly")
    func weekLabelFormatting() {
        // Given
        let dataPoints = [
            DataPoint(date: Date("2025-01-05T00:00:00Z"), value: 100),
            DataPoint(date: Date("2025-01-06T00:00:00Z"), value: 150)
        ]
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        // When
        let week = viewModel.weeks[0]
        let label = viewModel.weekLabel(for: week)

        // Then
        #expect(!label.isEmpty)
        #expect(label == "Jan 5") // Week starts on Sunday Jan 5, 2025
    }

    @Test("Formats values correctly")
    func valueFormatting() {
        // Given
        let dataPoints = [DataPoint(date: Date("2025-01-15T00:00:00Z"), value: 1500)]
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        // When
        let formatted = viewModel.formatValue(1500)

        // Then
        #expect(formatted == "1.5K")
    }

    // MARK: - Day Labels Tests

    @Test("Shows correct day labels for Sunday start")
    func dayLabelsForSundayStart() {
        // Given
        var sundayCalendar = Calendar.mock(timeZone: TimeZone(secondsFromGMT: 0)!)
        sundayCalendar.firstWeekday = 1 // Sunday
        let dataPoints = [DataPoint(date: Date("2025-01-15T00:00:00Z"), value: 100)]

        // When
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: sundayCalendar,
            metric: .views
        )

        // Then
        #expect(viewModel.dayLabels.count == 7)
        #expect(viewModel.dayLabels[0] == "S") // Sunday
        #expect(viewModel.dayLabels[6] == "S") // Saturday
    }

    @Test("Shows correct day labels for Monday start")
    func dayLabelsForMondayStart() {
        // Given
        var mondayCalendar = Calendar.mock(timeZone: TimeZone(secondsFromGMT: 0)!)
        mondayCalendar.firstWeekday = 2 // Monday
        let dataPoints = [DataPoint(date: Date("2025-01-15T00:00:00Z"), value: 100)]

        // When
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: mondayCalendar,
            metric: .views
        )

        // Then
        #expect(viewModel.dayLabels.count == 7)
        #expect(viewModel.dayLabels[0] == "M") // Monday
        #expect(viewModel.dayLabels[6] == "S") // Sunday
    }

    // MARK: - Previous Week Tests

    @Test("Gets previous week for first week")
    func previousWeekForFirstWeek() {
        // Given
        let dataPoints = [
            // Week 1: Jan 12-18, 2025 (more recent)
            DataPoint(date: Date("2025-01-12T00:00:00Z"), value: 200),
            DataPoint(date: Date("2025-01-13T00:00:00Z"), value: 210),
            // Week 2: Jan 5-11, 2025 (older)
            DataPoint(date: Date("2025-01-05T00:00:00Z"), value: 100),
            DataPoint(date: Date("2025-01-06T00:00:00Z"), value: 110)
        ]
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        // When
        let firstWeek = viewModel.weeks[0]
        let previousWeek = viewModel.previousWeek(for: firstWeek)

        // Then
        #expect(previousWeek != nil)
        #expect(previousWeek?.startDate == viewModel.weeks[1].startDate)
    }

    @Test("Returns nil for last week's previous week")
    func previousWeekForLastWeek() {
        // Given
        let dataPoints = [
            DataPoint(date: Date("2025-01-12T00:00:00Z"), value: 200),
            DataPoint(date: Date("2025-01-05T00:00:00Z"), value: 100)
        ]
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        // When
        let lastWeek = viewModel.weeks[1] // The older week
        let previousWeek = viewModel.previousWeek(for: lastWeek)

        // Then
        #expect(previousWeek == nil)
    }

    // MARK: - Max Value Tests

    @Test("Calculates max value correctly")
    func maxValueCalculation() {
        // Given
        let dataPoints = [
            DataPoint(date: Date("2025-01-01T00:00:00Z"), value: 100),
            DataPoint(date: Date("2025-01-02T00:00:00Z"), value: 500),
            DataPoint(date: Date("2025-01-03T00:00:00Z"), value: 300)
        ]

        // When
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        // Then
        #expect(viewModel.maxValue == 500)
    }

    // MARK: - Different Metrics Tests

    @Test("Handles views metric correctly")
    func viewsMetric() {
        // Given
        let dataPoints = [DataPoint(date: Date("2025-01-15T00:00:00Z"), value: 100)]

        // When
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        // Then
        #expect(viewModel.metric == .views)
        #expect(viewModel.metric.aggregationStrategy == .sum)
    }

    @Test("Handles time on site metric correctly")
    func timeOnSiteMetric() {
        // Given
        let dataPoints = [DataPoint(date: Date("2025-01-15T00:00:00Z"), value: 100)]

        // When
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .timeOnSite
        )

        // Then
        #expect(viewModel.metric == .timeOnSite)
        #expect(viewModel.metric.aggregationStrategy == .average)
    }

    // MARK: - Average Per Day Tests

    @Test("Calculates average per day for sum metric")
    func averagePerDayForSumMetric() {
        // Given - 7 consecutive days in the same week
        let dataPoints = [
            DataPoint(date: Date("2025-01-05T00:00:00Z"), value: 100), // Sun
            DataPoint(date: Date("2025-01-06T00:00:00Z"), value: 200), // Mon
            DataPoint(date: Date("2025-01-07T00:00:00Z"), value: 300), // Tue
            DataPoint(date: Date("2025-01-08T00:00:00Z"), value: 400), // Wed
            DataPoint(date: Date("2025-01-09T00:00:00Z"), value: 500), // Thu
            DataPoint(date: Date("2025-01-10T00:00:00Z"), value: 600), // Fri
            DataPoint(date: Date("2025-01-11T00:00:00Z"), value: 700)  // Sat
        ]

        // When
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views // Sum metric
        )

        // Then
        #expect(viewModel.weeks.count == 1)
        let week = viewModel.weeks[0]
        let expectedTotal = 2800 // Sum of all values
        let expectedAverage = expectedTotal / 7
        #expect(week.averagePerDay == expectedAverage)
    }

    @Test("Handles empty week for average calculation")
    func averagePerDayWithEmptyWeek() {
        // Given
        let dataPoints: [DataPoint] = []

        // When
        let viewModel = WeeklyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        // Then
        #expect(viewModel.weeks.count == 0)
    }
}
