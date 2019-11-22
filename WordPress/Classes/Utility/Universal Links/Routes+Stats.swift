import Foundation

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
}

extension StatsRoute: Route {
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
        }
    }
}

extension StatsRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil) {
        guard let coordinator = WPTabBarController.sharedInstance().mySitesCoordinator else {
            return
        }

        switch self {
        case .root:
            if let blog = defaultBlog() {
                coordinator.showStats(for: blog)
            }
        case .site:
            if let blog = blog(from: values) {
                coordinator.showStats(for: blog)
            } else {
                showStatsForDefaultBlog(from: values, with: coordinator)
            }
        case .daySite:
            showStatsForBlog(from: values, timePeriod: .days, using: coordinator)
        case .weekSite:
            showStatsForBlog(from: values, timePeriod: .weeks, using: coordinator)
        case .monthSite:
            showStatsForBlog(from: values, timePeriod: .months, using: coordinator)
        case .yearSite:
            showStatsForBlog(from: values, timePeriod: .years, using: coordinator)
        case .insights:
            showStatsForBlog(from: values, timePeriod: .insights, using: coordinator)
        case .dayCategory:
            showStatsForBlog(from: values, timePeriod: .days, using: coordinator)
        case .annualStats:
            showStatsForBlog(from: values, timePeriod: .years, using: coordinator)
        case .activityLog:
            if let blog = blog(from: values) {
                coordinator.showActivityLog(for: blog)
            } else {
                showMySitesAndFailureNotice(using: coordinator,
                                            values: values)
            }
        }
    }

    private func showStatsForBlog(from values: [String: String],
                                  timePeriod: StatsPeriodType,
                                  using coordinator: MySitesCoordinator) {
        if let blog = blog(from: values) {
            coordinator.showStats(for: blog,
                                  timePeriod: timePeriod)
        } else {
            showMySitesAndFailureNotice(using: coordinator,
                                        values: values)
        }
    }

    private func showMySitesAndFailureNotice(using coordinator: MySitesCoordinator,
                                             values: [String: String]) {
        WPAppAnalytics.track(.deepLinkFailed, withProperties: ["route": path])

        if failAndBounce(values) == false {
            coordinator.showMySites()
            postFailureNotice(title: NSLocalizedString("Site not found",
                                                       comment: "Error notice shown if the app can't find a specific site belonging to the user"))
        }
    }

    private func showStatsForDefaultBlog(from values: [String: String],
                                         with coordinator: MySitesCoordinator) {
        // It's possible that the stats route can come in without a domain
        // as the last component, if the user is viewing stats for "All My Sites" in Calypso.
        // In this case, we'll check whether the last component is actually a
        // time period, and if so we'll show that time period for the default site.
        guard let component = values["domain"],
            let timePeriod = StatsPeriodType.fromString(component),
            let blog = defaultBlog() else {
            return
        }

        coordinator.showStats(for: blog, timePeriod: timePeriod)
    }
}

private extension StatsPeriodType {
    static func fromString(_ string: String) -> StatsPeriodType? {
        switch string {
        case "day":
            return .days
        case "week":
            return .weeks
        case "month":
            return .months
        case "year":
            return .years
        case "insights":
            return .insights
        default:
            return nil
        }
    }
}
