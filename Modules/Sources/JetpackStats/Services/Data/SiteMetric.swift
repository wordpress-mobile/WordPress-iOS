import SwiftUI

enum SiteMetric: CaseIterable, Identifiable {
    case views
    case visitors
    case likes
    case comments
    case timeOnSite
    case bounceRate

    var id: SiteMetric { self }

    var localizedTitle: String {
        switch self {
        case .views: Strings.SiteMetrics.views
        case .visitors: Strings.SiteMetrics.visitors
        case .likes: Strings.SiteMetrics.likes
        case .comments: Strings.SiteMetrics.comments
        case .timeOnSite: Strings.SiteMetrics.timeOnSite
        case .bounceRate: Strings.SiteMetrics.bounceRate
        }
    }

    var systemImage: String {
        switch self {
        case .views: "eyeglasses"
        case .visitors: "person.2"
        case .likes: "star"
        case .comments: "bubble.left"
        case .timeOnSite: "clock"
        case .bounceRate: "rectangle.portrait.and.arrow.right"
        }
    }

    var primaryColor: Color {
        switch self {
        case .views: Constants.Colors.blue
        case .visitors: Constants.Colors.purple
        case .likes: Constants.Colors.red
        case .comments: Constants.Colors.green
        case .timeOnSite: Constants.Colors.orange
        case .bounceRate: Constants.Colors.pink
        }
    }

    func backgroundColor(in colorScheme: ColorScheme) -> Color {
        primaryColor.opacity(colorScheme == .light ? 0.05 : 0.15)
    }
}

extension SiteMetric {
    var isHigherValueBetter: Bool {
        switch self {
        case .views, .visitors, .likes, .comments, .timeOnSite:
            return true
        case .bounceRate:
            return false
        }
    }

    var aggregarionStrategy: AggregationStrategy {
        switch self {
        case .views, .visitors, .likes, .comments:
            return .sum
        case .timeOnSite, .bounceRate:
            return .average
        }
    }

    enum AggregationStrategy {
        /// Simply sum the values for the given period.
        case sum
        /// Calculate the avarege value for the given period.
        case average
    }
}
