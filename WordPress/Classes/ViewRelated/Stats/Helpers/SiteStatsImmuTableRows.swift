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
                                          siteStatsInsightsDelegate: SiteStatsInsightsDelegate?,
                                          viewsAndVisitorsDelegate: StatsInsightsViewsAndVisitorsDelegate?) -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()

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
                siteStatsInsightsDelegate: siteStatsInsightsDelegate,
                viewsAndVisitorsDelegate: viewsAndVisitorsDelegate,
                xAxisDates: xAxisDates,
                statSection: .insightsViewsVisitors
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
        static let viewsHigher = NSLocalizedString("stats.insights.label.views.sevenDays.higher",
                                                   value: "Your views in the last 7-days are %@ higher than the previous 7-days.\n",
                                                   comment: "Stats insights views higher than previous 7 days")
        static let viewsLower = NSLocalizedString("stats.insights.label.views.sevenDays.lower",
                                                  value: "Your views in the last 7-days are %@ lower than the previous 7-days.\n",
                                                  comment: "Stats insights views lower than previous 7 days")
        static let visitorsHigher = NSLocalizedString("stats.insights.label.visitors.sevenDays.higher",
                                                      value: "Your visitors in the last 7-days are %@ higher than the previous 7-days.\n",
                                                      comment: "Stats insights visitors higher than previous 7 days")
        static let visitorsLower = NSLocalizedString("stats.insights.label.visitors.sevenDays.lower",
                                                     value: "Your visitors in the last 7-days are %@ lower than the previous 7-days.\n",
                                                     comment: "Stats insights visitors lower than previous 7 days")
        static let viewsNoDifference = NSLocalizedString("stats.insights.label.views.sevenDays.same",
                                                         value: "Your views in the last 7-days are the same as the previous 7-days.\n",
                                                         comment: "Stats insights label shown when the user's view count is the same as the previous 7 days.")
        static let visitorsNoDifference = NSLocalizedString("stats.insights.label.visitors.sevenDays.same",
                                                            value: "Your visitors in the last 7-days are the same as the previous 7-days.\n",
                                                            comment: "Stats insights label shown when the user's visitor count is the same as the previous 7 days.")
    }
}
