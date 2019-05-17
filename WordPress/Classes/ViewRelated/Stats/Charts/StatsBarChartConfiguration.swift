
struct StatsBarChartConfiguration {
    let data: BarChartDataConvertible
    let styling: BarChartStyling
    let analyticsGranularity: BarChartAnalyticsPropertyGranularityValue?
    let delegate: StatsBarChartViewDelegate?
    let indexToHighlight: Int?
}

extension StatsBarChartConfiguration {
    init(data: BarChartDataConvertible, styling: BarChartStyling) {
        self.init(data: data, styling: styling, analyticsGranularity: nil, delegate: nil, indexToHighlight: nil)
    }

    init(data: BarChartDataConvertible, styling: BarChartStyling, analyticsGranularity: BarChartAnalyticsPropertyGranularityValue?) {
        self.init(data: data, styling: styling, analyticsGranularity: analyticsGranularity, delegate: nil, indexToHighlight: nil)
    }
}
