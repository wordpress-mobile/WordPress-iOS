import SwiftUI

enum SiteMetric: String, CaseIterable, Identifiable, Sendable, Codable, MetricType {
    case views
    case visitors
    case likes
    case comments
    case posts
    case timeOnSite
    case bounceRate
    case downloads

    var id: SiteMetric { self }

    var localizedTitle: String {
        switch self {
        case .views: Strings.SiteMetrics.views
        case .visitors: Strings.SiteMetrics.visitors
        case .likes: Strings.SiteMetrics.likes
        case .comments: Strings.SiteMetrics.comments
        case .posts: Strings.SiteMetrics.posts
        case .timeOnSite: Strings.SiteMetrics.timeOnSite
        case .bounceRate: Strings.SiteMetrics.bounceRate
        case .downloads: Strings.SiteMetrics.downloads
        }
    }

    var systemImage: String {
        switch self {
        case .views: "eyeglasses"
        case .visitors: "person"
        case .likes: "star"
        case .comments: "bubble.left"
        case .posts: "text.page"
        case .timeOnSite: "clock"
        case .bounceRate: "rectangle.portrait.and.arrow.right"
        case .downloads: "arrow.down.circle"
        }
    }

    var primaryColor: Color {
        switch self {
        case .views: Constants.Colors.blue
        case .visitors: Constants.Colors.purple
        case .likes: Constants.Colors.pink
        case .comments: Constants.Colors.green
        case .posts: Constants.Colors.celadon
        case .timeOnSite: Constants.Colors.orange
        case .bounceRate: Constants.Colors.pink
        case .downloads: Constants.Colors.blue
        }
    }

    func backgroundColor(in colorScheme: ColorScheme) -> Color {
        primaryColor.opacity(colorScheme == .light ? 0.05 : 0.15)
    }
}

extension SiteMetric {
    var isHigherValueBetter: Bool {
        switch self {
        case .views, .visitors, .likes, .comments, .timeOnSite, .posts, .downloads:
            return true
        case .bounceRate:
            return false
        }
    }

    var aggregationStrategy: AggregationStrategy {
        switch self {
        case .views, .visitors, .likes, .comments, .posts, .downloads:
            return .sum
        case .timeOnSite, .bounceRate:
            return .average
        }
    }

    func makeValueFormatter() -> any ValueFormatterProtocol {
        StatsValueFormatter(metric: self)
    }
}
