import Foundation

/// A memory-efficient collection of WordAds metrics with direct memory layout.
struct WordAdsMetricsSet: Codable, Sendable {
    var impressions: Int?
    var cpm: Int?      // Stored in cents
    var revenue: Int?  // Stored in cents

    subscript(metric: WordAdsMetric) -> Int? {
        get {
            switch metric.id {
            case "impressions": impressions
            case "cpm": cpm
            case "revenue": revenue
            default: nil
            }
        }
        set {
            switch metric.id {
            case "impressions": impressions = newValue
            case "cpm": cpm = newValue
            case "revenue": revenue = newValue
            default: break
            }
        }
    }

    static var mock: WordAdsMetricsSet {
        WordAdsMetricsSet(
            impressions: Int.random(in: 1000...10000),
            cpm: Int.random(in: 100...500),      // $1.00 - $5.00 in cents
            revenue: Int.random(in: 1000...10000) // $10.00 - $100.00 in cents
        )
    }
}
