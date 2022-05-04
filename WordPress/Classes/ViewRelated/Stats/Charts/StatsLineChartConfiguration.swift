
struct StatsLineChartConfiguration {
    let data: LineChartDataConvertible
    let styling: LineChartStyling
    let analyticsGranularity: LineChartAnalyticsPropertyGranularityValue?
    let indexToHighlight: Int?
    let xAxisDates: [Date]
}

extension StatsLineChartConfiguration {
    init(data: LineChartDataConvertible, styling: LineChartStyling, xAxisDates: [Date]) {
        self.init(data: data, styling: styling, analyticsGranularity: nil, indexToHighlight: nil, xAxisDates: xAxisDates)
    }

    init(data: LineChartDataConvertible, styling: LineChartStyling, analyticsGranularity: LineChartAnalyticsPropertyGranularityValue?, xAxisDates: [Date]) {
        self.init(data: data, styling: styling, analyticsGranularity: analyticsGranularity, indexToHighlight: nil, xAxisDates: xAxisDates)
    }
}
