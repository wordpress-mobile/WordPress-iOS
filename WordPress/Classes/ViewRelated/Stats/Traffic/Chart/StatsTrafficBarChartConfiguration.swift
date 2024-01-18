struct StatsTrafficBarChartConfiguration {
    let data: BarChartDataConvertible
    let styling: TrafficBarChartStyling
    let analyticsGranularity: BarChartAnalyticsPropertyGranularityValue?

    init(data: BarChartDataConvertible, styling: TrafficBarChartStyling, analyticsGranularity: BarChartAnalyticsPropertyGranularityValue? = nil) {
        self.data = data
        self.styling = styling
        self.analyticsGranularity = analyticsGranularity
    }
}
