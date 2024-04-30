
struct StatsLineChartConfiguration {
    let data: LineChartDataConvertible
    let areDataValuesIdentical: Bool
    let styling: LineChartStyling
    let analyticsGranularity: LineChartAnalyticsPropertyGranularityValue?
    let indexToHighlight: Int?
    let xAxisDates: [Date]
}
