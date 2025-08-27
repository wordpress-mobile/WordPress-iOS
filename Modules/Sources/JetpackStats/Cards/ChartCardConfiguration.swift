import Foundation

struct ChartCardConfiguration: Codable {
    let id: UUID
    var metrics: [SiteMetric]
    var chartType: ChartType

    init(id: UUID = UUID(), metrics: [SiteMetric], chartType: ChartType = .columns) {
        self.id = id
        self.metrics = metrics
        self.chartType = chartType
    }
}
