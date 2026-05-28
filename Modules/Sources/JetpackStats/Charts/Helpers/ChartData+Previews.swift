import Foundation

#if DEBUG
extension ChartData {
    struct PreviewExample: Identifiable {
        let id = UUID()
        let title: String
        let data: ChartData
        let showComparison: Bool

        init(title: String, data: ChartData, showComparison: Bool = false) {
            self.title = title
            self.data = data
            self.showComparison = showComparison
        }
    }

    static var previewExamples: [PreviewExample] {
        let calendar = Calendar.demo

        return [
            // 1. Standard: 7 days with day granularity
            PreviewExample(
                title: "Last 7 Days",
                data: ChartData.mock(
                    metric: .visitors,
                    granularity: .day,
                    range: calendar.makeDateRange(for: .last7Days)
                )
            ),

            // 2. Standard: 30 days with day granularity
            PreviewExample(
                title: "Last 30 Days",
                data: ChartData.mock(
                    metric: .views,
                    granularity: .day,
                    range: calendar.makeDateRange(for: .last30Days)
                )
            ),

            // 3. Standard: 12 months with month granularity
            PreviewExample(
                title: "Last 12 Months",
                data: ChartData.mock(
                    metric: .likes,
                    granularity: .month,
                    range: calendar.makeDateRange(for: .thisYear)
                )
            ),

            // 4. Edge case: 1 year data point for week period
            PreviewExample(
                title: "Last 7 Days with Yearly Granularity",
                data: {
                    let year2026 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
                    let year2025 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!

                    return ChartData(
                        metric: .views,
                        granularity: .year,
                        dateInterval: calendar.makeDateRange(for: .last7Days).dateInterval,
                        currentTotal: 5000,
                        currentData: [
                            DataPoint(date: year2026, value: 5000)
                        ],
                        previousTotal: 4500,
                        previousData: [
                            DataPoint(date: year2025, value: 4500)
                        ],
                        mappedPreviousData: [
                            DataPoint(date: year2026, value: 4500)
                        ]
                    )
                }()
            ),

            // 5. Edge case: month granularity for week period
            PreviewExample(
                title: "Last 7 Days with Monthly Granularity",
                data: {
                    let dateRange = calendar.makeDateRange(for: .last7Days)
                    let jan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
                    let feb = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!

                    return ChartData(
                        metric: .comments,
                        granularity: .month,
                        dateInterval: dateRange.dateInterval,
                        currentTotal: 250,
                        currentData: [
                            DataPoint(date: jan, value: 150),
                            DataPoint(date: feb, value: 100)
                        ],
                        previousTotal: 220,
                        previousData: [],
                        mappedPreviousData: []
                    )
                }()
            ),

            // 6. Few data points: 3 days
            PreviewExample(
                title: "This Week Middle of the Week",
                data: {
                    let today = calendar.startOfDay(for: Date())
                    return ChartData(
                        metric: .visitors,
                        granularity: .day,
                        dateInterval: calendar.makeDateRange(for: .last7Days).dateInterval,
                        currentTotal: 450,
                        currentData: [
                            DataPoint(date: calendar.date(byAdding: .day, value: -5, to: today)!, value: 150),
                            DataPoint(date: calendar.date(byAdding: .day, value: -6, to: today)!, value: 120),
                            DataPoint(date: calendar.date(byAdding: .day, value: -7, to: today)!, value: 180)
                        ],
                        previousTotal: 400,
                        previousData: [],
                        mappedPreviousData: []
                    )
                }()
            ),

            // 7. Comparison Enabled
            PreviewExample(
                title: "With Comparison",
                data: ChartData.mock(
                    metric: .views,
                    granularity: .day,
                    range: calendar.makeDateRange(for: .last7Days)
                ),
                showComparison: true
            ),

            // 8. Hour Granularity (Today)
            PreviewExample(
                title: "Today (Hourly)",
                data: {
                    let dateRange = calendar.makeDateRange(for: .today)
                    let startOfDay = dateRange.dateInterval.start

                    // Generate hourly data for today (12 hours)
                    let hourlyData = (0..<12).map { hour in
                        let date = calendar.date(byAdding: .hour, value: hour, to: startOfDay)!
                        let value = Int.random(in: 50...200)
                        return DataPoint(date: date, value: value)
                    }

                    return ChartData(
                        metric: .views,
                        granularity: .hour,
                        dateInterval: dateRange.dateInterval,
                        currentTotal: hourlyData.reduce(0) { $0 + $1.value },
                        currentData: hourlyData,
                        previousTotal: 0,
                        previousData: [],
                        mappedPreviousData: []
                    )
                }()
            ),

            // 9. Data with Large Spike
            PreviewExample(
                title: "With Large Spike",
                data: {
                    let dateRange = calendar.makeDateRange(for: .last7Days)
                    let startDate = dateRange.dateInterval.start

                    let dataPoints = (0..<7).map { day in
                        let date = calendar.date(byAdding: .day, value: day, to: startDate)!
                        // Day 3 has a large spike
                        let value = day == 3 ? 5000 : Int.random(in: 100...300)
                        return DataPoint(date: date, value: value)
                    }

                    return ChartData(
                        metric: .visitors,
                        granularity: .day,
                        dateInterval: dateRange.dateInterval,
                        currentTotal: dataPoints.reduce(0) { $0 + $1.value },
                        currentData: dataPoints,
                        previousTotal: 0,
                        previousData: [],
                        mappedPreviousData: []
                    )
                }()
            ),

            // 10. Empty data
            PreviewExample(
                title: "Empty Data",
                data: ChartData(
                    metric: .views,
                    granularity: .day,
                    dateInterval: calendar.makeDateRange(for: .last7Days).dateInterval,
                    currentTotal: 0,
                    currentData: [],
                    previousTotal: 0,
                    previousData: [],
                    mappedPreviousData: []
                )
            )
        ]
    }
}
#endif
