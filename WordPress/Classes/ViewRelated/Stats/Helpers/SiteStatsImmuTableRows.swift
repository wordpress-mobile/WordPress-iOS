import Foundation

/// Helper class to encapsulate ImmuTableRows creation
/// Stats Revamp results in the same ImmuTableRows created in different screens
///
class SiteStatsImmuTableRows {

    /// Helper method to create the rows for the Views and Visitors section
    ///
    static func viewVisitorsImmuTableRows(_ statsSummaryTimeIntervalData: StatsSummaryTimeIntervalData?,
                                          selectedSegment: StatsSegmentedControlData.Segment,
                                          periodDate: Date,
                                          periodEndDate: Date? = nil,
                                          statsLineChartViewDelegate: StatsLineChartViewDelegate?,
                                          siteStatsInsightsDelegate: SiteStatsInsightsDelegate?) -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()

        let viewsData = SiteStatsInsightsViewModel.intervalData(statsSummaryTimeIntervalData, summaryType: .views, periodEndDate: periodEndDate)
        let viewsSegmentData = StatsSegmentedControlData(segmentTitle: StatSection.periodOverviewViews.tabTitle,
                segmentData: viewsData.count,
                segmentPrevData: viewsData.prevCount,
                difference: viewsData.difference,
                differenceText: viewsDifferenceText(with: viewsData.count, difference: viewsData.difference),
                date: periodDate,
                period: StatsPeriodUnit.week,
                analyticsStat: .statsOverviewTypeTappedViews,
                accessibilityHint: StatSection.periodOverviewViews.tabAccessibilityHint,
                differencePercent: viewsData.percentage)

        let visitorsData = SiteStatsInsightsViewModel.intervalData(statsSummaryTimeIntervalData, summaryType: .visitors, periodEndDate: periodEndDate)
        let visitorsSegmentData = StatsSegmentedControlData(segmentTitle: StatSection.periodOverviewVisitors.tabTitle,
                segmentData: visitorsData.count,
                segmentPrevData: visitorsData.prevCount,
                difference: visitorsData.difference,
                differenceText: visitorsDifferenceText(with: visitorsData.count, difference: visitorsData.difference),
                date: periodDate,
                period: StatsPeriodUnit.week,
                analyticsStat: .statsOverviewTypeTappedViews,
                accessibilityHint: StatSection.periodOverviewViews.tabAccessibilityHint,
                differencePercent: visitorsData.percentage)

        var lineChartData = [LineChartDataConvertible]()
        var lineChartStyling = [LineChartStyling]()

        if let chartData = statsSummaryTimeIntervalData {
            let splitSummaryTimeIntervalData = SiteStatsInsightsViewModel.splitStatsSummaryTimeIntervalData(chartData, periodEndDate: periodEndDate)
            let viewsChart = InsightsLineChart(data: splitSummaryTimeIntervalData, filterDimension: .views)
            lineChartData.append(contentsOf: viewsChart.lineChartData)
            lineChartStyling.append(contentsOf: viewsChart.lineChartStyling)

            let visitorsChart = InsightsLineChart(data: splitSummaryTimeIntervalData, filterDimension: .visitors)
            lineChartData.append(contentsOf: visitorsChart.lineChartData)
            lineChartStyling.append(contentsOf: visitorsChart.lineChartStyling)

            var xAxisDates = [Date]()
            splitSummaryTimeIntervalData.forEach { week in
                switch week {
                case .thisWeek(let data):
                    xAxisDates = data.summaryData.map { $0.periodStartDate }
                default:
                    break
                }
            }

            let row = ViewsVisitorsRow(
                segmentsData: [viewsSegmentData, visitorsSegmentData],
                selectedSegment: selectedSegment,
                chartData: lineChartData,
                chartStyling: lineChartStyling,
                period: StatsPeriodUnit.day,
                statsLineChartViewDelegate: statsLineChartViewDelegate,
                siteStatsInsightsDelegate: siteStatsInsightsDelegate, xAxisDates: xAxisDates
            )
            tableRows.append(row)
        }

        return tableRows
    }

    private static func viewsDifferenceText(with count: Int, difference: Int) -> String {
        if difference == 0 && count != 0 {
            return Constants.viewsNoDifference
        }

        return difference < 0 ? Constants.viewsLower : Constants.viewsHigher
    }

    private static func visitorsDifferenceText(with count: Int, difference: Int) -> String {
        if difference == 0 && count != 0 {
            return Constants.visitorsNoDifference
        }

        return difference < 0 ? Constants.visitorsLower : Constants.visitorsHigher
    }

    enum Constants {
        static let viewsHigher = NSLocalizedString("Your views this week are %@ higher than the previous week.\n", comment: "Stats insights views higher than previous week")
        static let viewsLower = NSLocalizedString("Your views this week are %@ lower than the previous week.\n", comment: "Stats insights views lower than previous week")
        static let visitorsHigher = NSLocalizedString("Your visitors this week are %@ higher than the previous week.\n", comment: "Stats insights visitors higher than previous week")
        static let visitorsLower = NSLocalizedString("Your visitors this week are %@ lower than the previous week.\n", comment: "Stats insights visitors lower than previous week")
        static let viewsNoDifference = NSLocalizedString("Your views this week are the same as the previous week.\n", comment: "Stats insights label shown when the user's view count is the same as the previous week.")
        static let visitorsNoDifference = NSLocalizedString("Your visitors this week are the same as the previous week.\n", comment: "Stats insights label shown when the user's visitor count is the same as the previous week.")
    }
}
