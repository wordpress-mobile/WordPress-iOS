import Foundation

struct SiteStatsData: Sendable {
    var metrics: [SiteMetric: [DataPoint]]
}
