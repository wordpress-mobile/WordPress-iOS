import Foundation

struct StatsLineChartConfiguration {
    enum StatType {
        case viewsAndVisitors(StatsInsightsFilterDimension)
        case subscribers
    }

    let type: StatType
    let data: LineChartDataConvertible
    let styling: LineChartStyling
    let analyticsGranularity: LineChartAnalyticsPropertyGranularityValue?
    let xAxisDates: [Date]
}
