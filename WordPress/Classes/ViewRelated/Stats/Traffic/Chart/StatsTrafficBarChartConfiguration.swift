struct StatsTrafficBarChartConfiguration {
    let data: BarChartDataConvertible
    let styling: TrafficBarChartStyling

    init(data: BarChartDataConvertible, styling: TrafficBarChartStyling) {
        self.data = data
        self.styling = styling
    }
}
