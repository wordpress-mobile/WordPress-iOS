struct StatsTrafficBarChartConfiguration {
    let data: BarChartDataConvertible
    let styling: StatsTrafficBarChartStyling

    init(data: BarChartDataConvertible, styling: StatsTrafficBarChartStyling) {
        self.data = data
        self.styling = styling
    }
}
