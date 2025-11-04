import Foundation

struct TodayCardConfiguration: Codable {
    let id: UUID
    var metrics: [SiteMetric]

    init(id: UUID = UUID(), metrics: [SiteMetric]) {
        self.id = id
        self.metrics = metrics
    }

    init(supportedMetrics: Set<SiteMetric>) {
        // We have only so much space
        let preferredMetrics: [SiteMetric] = [.views, .visitors, .likes, .comments]
        self.id = UUID()
        self.metrics = preferredMetrics.filter(supportedMetrics.contains)
    }
}
