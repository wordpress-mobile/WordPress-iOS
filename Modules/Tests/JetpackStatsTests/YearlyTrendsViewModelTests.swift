import Testing
import Foundation
@testable import JetpackStats

@MainActor @Suite
struct YearlyTrendsViewModelTests {
    let calendar = Calendar.mock(timeZone: TimeZone(secondsFromGMT: 0)!)

    @Test
    func initWithEmptyDataPoints() {
        let viewModel = YearlyTrendsViewModel(
            dataPoints: [],
            calendar: calendar
        )

        #expect(viewModel.sortedYears.isEmpty)
        #expect(viewModel.maxMonthlyViews == 1) // Should default to 1 to avoid division by zero
    }

    @Test
    func initWithSingleMonthData() {
        let dataPoints = [
            DataPoint(date: Date("2025-01-15T10:00:00Z"), value: 100),
            DataPoint(date: Date("2025-01-20T10:00:00Z"), value: 200)
        ]

        let viewModel = YearlyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar
        )

        #expect(viewModel.sortedYears == [2025])
        #expect(viewModel.maxMonthlyViews == 300) // Sum of January values

        let monthlyData = viewModel.getMonthlyData(for: 2025)
        #expect(monthlyData.count == 12)

        // January should have the sum of values
        #expect(monthlyData[0].value == 300)

        // Other months should have 0
        for month in 1..<12 {
            #expect(monthlyData[month].value == 0)
        }
    }

    @Test
    func initWithMultipleMonthsData() {
        let dataPoints = [
            // January data
            DataPoint(date: Date("2025-01-15T10:00:00Z"), value: 100),
            DataPoint(date: Date("2025-01-20T10:00:00Z"), value: 200),
            // March data
            DataPoint(date: Date("2025-03-10T10:00:00Z"), value: 400),
            // December data
            DataPoint(date: Date("2025-12-25T10:00:00Z"), value: 500)
        ]

        let viewModel = YearlyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar
        )

        #expect(viewModel.maxMonthlyViews == 500) // December has the highest value

        let monthlyData = viewModel.getMonthlyData(for: 2025)
        #expect(monthlyData[0].value == 300)  // January
        #expect(monthlyData[1].value == 0)    // February
        #expect(monthlyData[2].value == 400)  // March
        #expect(monthlyData[11].value == 500) // December
    }

    @Test
    func initWithMultipleYearsData() {
        let dataPoints = [
            // 2024 data
            DataPoint(date: Date("2024-06-15T10:00:00Z"), value: 100),
            DataPoint(date: Date("2024-12-15T10:00:00Z"), value: 200),
            // 2025 data
            DataPoint(date: Date("2025-01-15T10:00:00Z"), value: 300),
            DataPoint(date: Date("2025-03-15T10:00:00Z"), value: 400),
            // 2023 data
            DataPoint(date: Date("2023-09-15T10:00:00Z"), value: 150)
        ]

        let viewModel = YearlyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar
        )

        // Years should be sorted in descending order
        #expect(viewModel.sortedYears == [2025, 2024, 2023])
        #expect(viewModel.maxMonthlyViews == 400) // March 2025 has the highest

        // Check 2025 data
        let data2025 = viewModel.getMonthlyData(for: 2025)
        #expect(data2025[0].value == 300)  // January
        #expect(data2025[2].value == 400)  // March

        // Check 2024 data
        let data2024 = viewModel.getMonthlyData(for: 2024)
        #expect(data2024[5].value == 100)   // June
        #expect(data2024[11].value == 200)  // December

        // Check 2023 data
        let data2023 = viewModel.getMonthlyData(for: 2023)
        #expect(data2023[8].value == 150)   // September
    }

    @Test
    func monthlyDataDatesAreCorrect() {
        let dataPoints = [
            DataPoint(date: Date("2025-01-15T10:00:00Z"), value: 100)
        ]

        let viewModel = YearlyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar
        )

        let monthlyData = viewModel.getMonthlyData(for: 2025)

        // Check that each month has the correct date (1st of each month)
        for (index, dataPoint) in monthlyData.enumerated() {
            let components = calendar.dateComponents([.year, .month, .day], from: dataPoint.date)
            #expect(components.year == 2025)
            #expect(components.month == index + 1)
            #expect(components.day == 1)
        }
    }

    @Test
    func aggregationWithDifferentMetrics() {
        let dataPoints = [
            // Multiple values in same month to test aggregation
            DataPoint(date: Date("2025-01-10T10:00:00Z"), value: 300),
            DataPoint(date: Date("2025-01-15T10:00:00Z"), value: 600),
            DataPoint(date: Date("2025-01-20T10:00:00Z"), value: 900)
        ]

        // Test with views (sum strategy)
        let viewsViewModel = YearlyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .views
        )

        let viewsData = viewsViewModel.getMonthlyData(for: 2025)
        #expect(viewsData[0].value == 1800) // Sum: 300 + 600 + 900

        // Test with timeOnSite (average strategy)
        let timeViewModel = YearlyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            metric: .timeOnSite
        )

        let timeData = timeViewModel.getMonthlyData(for: 2025)
        #expect(timeData[0].value == 600) // Average: (300 + 600 + 900) / 3
    }

    @Test
    func formatValue() {
        let dataPoints = [
            DataPoint(date: Date("2025-01-15T10:00:00Z"), value: 1234)
        ]

        let viewModel = YearlyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar
        )

        #expect(viewModel.formatValue(1234) == "1.2K")
        #expect(viewModel.formatValue(0) == "0")
        #expect(viewModel.formatValue(999) == "999")
        #expect(viewModel.formatValue(1000) == "1K")
    }

    @Test
    func getMonthlyDataForNonExistentYear() {
        let dataPoints = [
            DataPoint(date: Date("2025-01-15T10:00:00Z"), value: 100)
        ]

        let viewModel = YearlyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar
        )

        // This should return empty array after the assertionFailure
        let data = viewModel.getMonthlyData(for: 2024)
        #expect(data.isEmpty)
    }

    @Test
    func handlesLeapYearCorrectly() {
        // Test with February data in leap year
        let dataPoints = [
            DataPoint(date: Date("2024-02-29T10:00:00Z"), value: 100) // 2024 is a leap year
        ]

        let viewModel = YearlyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar
        )

        let monthlyData = viewModel.getMonthlyData(for: 2024)
        #expect(monthlyData[1].value == 100) // February

        // Verify the date is set to Feb 1st
        let febComponents = calendar.dateComponents([.year, .month, .day], from: monthlyData[1].date)
        #expect(febComponents.year == 2024)
        #expect(febComponents.month == 2)
        #expect(febComponents.day == 1)
    }

    @Test
    func handlesTimeZoneCorrectly() {
        // Create calendar with different timezone
        let pstCalendar = Calendar.mock(timeZone: TimeZone(identifier: "America/Los_Angeles")!)

        // This date is late evening PST, which is next day in UTC
        let dataPoints = [
            DataPoint(date: Date("2025-01-31T23:00:00-08:00"), value: 100) // Jan 31, 11 PM PST = Feb 1 UTC
        ]

        let viewModel = YearlyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: pstCalendar
        )

        let monthlyData = viewModel.getMonthlyData(for: 2025)
        // In PST timezone, this should still be January
        #expect(monthlyData[0].value == 100) // January
        #expect(monthlyData[1].value == 0)   // February should be empty
    }
}
