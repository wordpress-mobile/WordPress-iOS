import Foundation

struct ChartCardConfiguration: Codable {
    let id: UUID
    var metrics: [SiteMetric]
    
    init(id: UUID = UUID(), metrics: [SiteMetric]) {
        self.id = id
        self.metrics = metrics
    }
}