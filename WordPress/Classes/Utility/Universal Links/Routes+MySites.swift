import Foundation

enum MySitesRoute: CaseIterable {
    case pages
    case posts
    case media
    case comments
    case sharing
    case people
    case plugins
    case managePlugins
    case siteMonitoring
    case phpLogs
    case webServerLogs
}

extension MySitesRoute: Route {
    var section: DeepLinkSection? {
        return .mySite
    }

    var action: NavigationAction {
        return self
    }

    var path: String {
        switch self {
        case .pages:
            return "/pages/:domain"
        case .posts:
            return "/posts/:domain"
        case .media:
            return "/media/:domain"
        case .comments:
            return "/comments/:domain"
        case .sharing:
            return "/sharing/:domain"
        case .people:
            return "/people/:domain"
        case .plugins:
            return "/plugins/:domain"
        case .managePlugins:
            return "/plugins/manage/:domain"
        case .siteMonitoring:
            return "/site-monitoring/:domain"
        case .phpLogs:
            return "/site-monitoring/:domain/php"
        case .webServerLogs:
            return "/site-monitoring/:domain/web"
        }
    }

    var jetpackPowered: Bool {
        switch self {
        case .pages:
            return false
        case .posts:
            return false
        case .media:
            return false
        case .comments:
            return false
        case .sharing:
            return true
        case .siteMonitoring:
            return true
        case .phpLogs:
            return true
        case .webServerLogs:
            return true
        case .people:
            return true
        case .plugins:
            return false
        case .managePlugins:
            return false
        }
    }
}

extension MySitesRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil, router: LinkRouter) {
        let coordinator = RootViewCoordinator.sharedPresenter.mySitesCoordinator
        let campaign = AppBannerCampaign.getCampaign(from: values)

        guard let blog = blog(from: values) else {
            var properties: [AnyHashable: Any] = [
                "route": path,
                "error": "invalid_site_id"
            ]
            if let campaign {
                properties["campaign"] = campaign
            }
            WPAppAnalytics.track(.deepLinkFailed, withProperties: properties)

            if failAndBounce(values) == false {
                coordinator.showRootViewController()
                postFailureNotice(title: NSLocalizedString("Site not found",
                                                           comment: "Error notice shown if the app can't find a specific site belonging to the user"))
            }
            return
        }

        switch self {
        case .pages:
            coordinator.showPages(for: blog)
        case .posts:
            coordinator.showPosts(for: blog)
        case .media:
            if campaign.flatMap(AppBannerCampaign.init) == .qrCodeMedia {
                coordinator.showMediaPicker(for: blog)
            } else {
                coordinator.showMedia(for: blog)
            }
        case .comments:
            coordinator.showComments(for: blog)
        case .sharing:
            coordinator.showSharing(for: blog)
        case .people:
            coordinator.showPeople(for: blog)
        case .plugins:
            coordinator.showPlugins(for: blog)
        case .managePlugins:
            coordinator.showManagePlugins(for: blog)
        case .siteMonitoring:
            coordinator.showSiteMonitoring(for: blog, selectedTab: .metrics)
        case .phpLogs:
            coordinator.showSiteMonitoring(for: blog, selectedTab: .phpLogs)
        case .webServerLogs:
            coordinator.showSiteMonitoring(for: blog, selectedTab: .webServerLogs)
        }
    }
}
