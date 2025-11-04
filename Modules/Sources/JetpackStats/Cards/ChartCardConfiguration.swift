import Foundation

public struct ChartCardConfiguration: Codable {
    let id: UUID
    var metrics: [SiteMetric]
    var chartType: ChartType

    init(id: UUID = UUID(), metrics: [SiteMetric], chartType: ChartType = Self.defaultChartType) {
        self.id = id
        self.metrics = metrics
        self.chartType = chartType
    }

    nonisolated(unsafe) public static var defaultChartType: ChartType = .columns
}
