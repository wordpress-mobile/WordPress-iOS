import Foundation

struct WordAdsMetricsResponse: Sendable {
    var total: WordAdsMetricsSet

    /// Data points with the requested granularity.
    ///
    /// - note: The dates are in the site reporting time zone.
    ///
    /// - warning: Hourly data is not available for some metrics, but total
    /// metrics still are.
    var metrics: [WordAdsMetric: [DataPoint]]
}
