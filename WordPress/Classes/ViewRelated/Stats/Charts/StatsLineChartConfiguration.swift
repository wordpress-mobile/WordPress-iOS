
struct StatsLineChartConfiguration {
    let data: LineChartDataConvertible
    let styling: LineChartStyling
    let analyticsGranularity: LineChartAnalyticsPropertyGranularityValue?
    let indexToHighlight: Int?
    let xAxisDates: [Date]
}
