import Foundation
import WordPressComStatsiOS

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
    func perform(_ values: [String: String]?) {
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
            }
        case .daySite:
            if let blog = blog(from: values) {
                coordinator.showStats(for: blog,
                                      timePeriod: StatsPeriodType.days)
            }
        case .weekSite:
            if let blog = blog(from: values) {
                coordinator.showStats(for: blog,
                                      timePeriod: StatsPeriodType.weeks)
            }
        case .monthSite:
            if let blog = blog(from: values) {
                coordinator.showStats(for: blog,
                                      timePeriod: StatsPeriodType.months)
            }
        case .yearSite:
            if let blog = blog(from: values) {
                coordinator.showStats(for: blog,
                                      timePeriod: StatsPeriodType.years)
            }
        case .insights:
            if let blog = blog(from: values) {
                coordinator.showStats(for: blog,
                                      timePeriod: StatsPeriodType.insights)
            }
        case .dayCategory:
            if let blog = blog(from: values) {
                coordinator.showStats(for: blog,
                                      timePeriod: StatsPeriodType.days)
            }
        case .annualStats:
            if let blog = blog(from: values) {
                coordinator.showStats(for: blog,
                                      timePeriod: StatsPeriodType.years)
            }
        case .activityLog:
            if let blog = blog(from: values) {
                coordinator.showActivityLog(for: blog)
            }
        }
    }

    private func defaultBlog() -> Blog? {
        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)

        return service.lastUsedOrFirstBlog()
    }

    private func blog(from values: [String: String]?) -> Blog? {
        guard let domain = values?["domain"] else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)

        if let blog = service.blog(byHostname: domain) {
            return blog
        }

        // Some stats URLs use a site ID instead
        if let siteIDValue = Int(domain) {
            return service.blog(byBlogId: NSNumber(value: siteIDValue))
        }

        return nil
    }
}
