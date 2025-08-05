import Foundation

/// A memory-efficient collection of metrics with direct memory layout and no
/// heap allocations.
struct SiteMetricsSet: Codable {
    var views: Int?
    var visitors: Int?
    var likes: Int?
    var comments: Int?
    var posts: Int?
    var bounceRate: Int?
    var timeOnSite: Int?
    var downloads: Int?

    subscript(metric: SiteMetric) -> Int? {
        get {
            switch metric {
            case .views: views
            case .visitors: visitors
            case .likes: likes
            case .comments: comments
            case .posts: posts
            case .bounceRate: bounceRate
            case .timeOnSite: timeOnSite
            case .downloads: downloads
            }
        }
        set {
            switch metric {
            case .views: views = newValue
            case .visitors: visitors = newValue
            case .likes: likes = newValue
            case .comments: comments = newValue
            case .posts: posts = newValue
            case .bounceRate: bounceRate = newValue
            case .timeOnSite: timeOnSite = newValue
            case .downloads: downloads = newValue
            }
        }
    }

    static var mock: SiteMetricsSet {
        SiteMetricsSet(
            views: Int.random(in: 10...10000),
            visitors: Int.random(in: 10...1000),
            likes: Int.random(in: 10...1000),
            comments: Int.random(in: 10...1000),
            posts: Int.random(in: 10...100),
            bounceRate: Int.random(in: 50...80),
            timeOnSite: Int.random(in: 10...200),
            downloads: Int.random(in: 10...500)
        )
    }
}
