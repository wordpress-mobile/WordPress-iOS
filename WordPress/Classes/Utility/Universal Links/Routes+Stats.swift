import UIKit

enum StatsRoute {
    case root
    case site
    case daySite
    case weekSite
    case monthSite
    case yearSite
    case insights
    case dayCategory
    case annualStats
    case activityLog
    case subscribers
    case daySubscribers

    var tab: StatsTabType? {
        switch self {
        case .daySite:
            return .traffic
        case .weekSite:
            return .traffic
        case .monthSite:
            return .traffic
        case .yearSite:
            return .traffic
        case .insights:
            return .insights
        case .subscribers:
            return .subscribers
        case .daySubscribers:
            return .subscribers
        default:
            return nil
        }
    }
}

extension StatsRoute: Route {
    var section: DeepLinkSection? {
        return .stats
    }

    var action: NavigationAction {
        return self
    }

    var path: String {
        switch self {
        case .root:
            return "/stats"
        case .site:
            return "/stats/:domain"
        case .daySite:
            return "/stats/day/:domain"
        case .weekSite:
            return "/stats/week/:domain"
        case .monthSite:
            return "/stats/month/:domain"
        case .yearSite:
            return "/stats/year/:domain"
        case .insights:
            return "/stats/insights/:domain"
        case .dayCategory:
            return "/stats/day/:category/:domain"
        case .annualStats:
            return "/stats/annualstats/:domain"
        case .activityLog:
            return "/stats/activity/:domain"
        case .subscribers:
            return "/stats/subscribers/:domain"
        case .daySubscribers:
            return "/stats/subscribers/day/:domain"
        }
    }

    var jetpackPowered: Bool {
        return true
    }
}

extension StatsRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil, router: LinkRouter) {
        let presenter = RootViewCoordinator.sharedPresenter
        switch self {
        case .root:
            if let blog = defaultBlog() {
                presenter.showStats(for: blog)
            }
        case .site:
            if let blog = blog(from: values) {
                presenter.showStats(for: blog)
            } else {
                showStatsForDefaultBlog(from: values, with: presenter)
            }
        case .daySite:
            showStatsForBlog(from: values, tab: .traffic, unit: .day, using: presenter)
        case .weekSite:
            showStatsForBlog(from: values, tab: .traffic, unit: .week, using: presenter)
        case .monthSite:
            showStatsForBlog(from: values, tab: .traffic, unit: .month, using: presenter)
        case .yearSite:
            showStatsForBlog(from: values, tab: .traffic, unit: .year, using: presenter)
        case .insights:
            showStatsForBlog(from: values, tab: .insights, using: presenter)
        case .dayCategory:
            showStatsForBlog(from: values, tab: .traffic, unit: .day, using: presenter)
        case .annualStats:
            showStatsForBlog(from: values, tab: .traffic, unit: .year, using: presenter)
        case .activityLog:
            if let blog = blog(from: values) {
                presenter.showBlogDetails(for: blog, then: .activity)
            } else {
                showMySitesAndFailureNotice(values: values)
            }
        case .subscribers, .daySubscribers:
            showStatsForBlog(from: values, tab: .subscribers, using: presenter)
        }
    }

    private func showStatsForBlog(from values: [String: String],
                                  tab: StatsTabType,
                                  unit: StatsPeriodUnit? = nil,
                                  using presenter: RootViewPresenter) {
        if let blog = blog(from: values) {
            presenter.showStats(for: blog,
                                  source: source(from: values),
                                  tab: tab,
                                  unit: unit)
        } else {
            showMySitesAndFailureNotice(values: values)
        }
    }

    private func showMySitesAndFailureNotice(values: [String: String]) {
        WPAppAnalytics.track(.deepLinkFailed, withProperties: ["route": path])

        if failAndBounce(values) == false {
            postFailureNotice(title: NSLocalizedString("Site not found", comment: "Error notice shown if the app can't find a specific site belonging to the user"))
        }
    }

    private func showStatsForDefaultBlog(from values: [String: String],
                                         with presenter: RootViewPresenter) {
        // It's possible that the stats route can come in without a domain
        // as the last component, if the user is viewing stats for "All My Sites" in Calypso.
        // In this case, we'll check whether the last component is actually a
        // time period, and if so we'll show that time period for the default site.
        guard let component = values["domain"],
              let timePeriod = StatsTabType(from: component),
              let blog = defaultBlog() else {
            return
        }
        presenter.showStats(for: blog, source: source(from: values), tab: timePeriod)
    }

    private func source(from values: [String: String]) -> BlogDetailsNavigationSource {
        if values["matched-route-source"] != nil {
            return .widget
        } else {
            return .link
        }
    }
}
