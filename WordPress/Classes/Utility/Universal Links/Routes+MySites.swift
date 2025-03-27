import UIKit

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

            if campaign.flatMap(AppBannerCampaign.init) == .qrCodeMedia {
                postFailureNotice(title: Strings.siteNotFound, message: Strings.checkAccount)
                return
            }

            if failAndBounce(values) == false {
                postFailureNotice(title: NSLocalizedString("Site not found",
                                                           comment: "Error notice shown if the app can't find a specific site belonging to the user"))
            }
            return
        }

        let presenter = RootViewCoordinator.sharedPresenter

        switch self {
        case .pages:
            presenter.showBlogDetails(for: blog, then: .pages)
        case .posts:
            presenter.showBlogDetails(for: blog, then: .posts)
        case .media:
            if campaign.flatMap(AppBannerCampaign.init) == .qrCodeMedia {
                presenter.showMediaPicker(for: blog)
            } else {
                presenter.showBlogDetails(for: blog, then: .media)
            }
        case .comments:
            presenter.showBlogDetails(for: blog, then: .comments)
        case .sharing:
            presenter.showBlogDetails(for: blog, then: .sharing)
        case .people:
            presenter.showBlogDetails(for: blog, then: .people)
        case .plugins:
            presenter.showBlogDetails(for: blog, then: .plugins)
        case .managePlugins:
            presenter.showBlogDetails(for: blog, then: .plugins, userInfo: [
                BlogDetailsViewController.userInfoShowManagemenetScreenKey(): true
            ])
        case .siteMonitoring:
            presenter.showSiteMonitoring(for: blog, selectedTab: .metrics)
        case .phpLogs:
            presenter.showSiteMonitoring(for: blog, selectedTab: .phpLogs)
        case .webServerLogs:
            presenter.showSiteMonitoring(for: blog, selectedTab: .webServerLogs)
        }
    }
}

private extension RootViewPresenter {
    func showMediaPicker(for blog: Blog) {
        showBlogDetails(for: blog, then: .media, userInfo: [
            BlogDetailsViewController.userInfoShowPickerKey(): true
        ])
    }

    func showSiteMonitoring(for blog: Blog, selectedTab: SiteMonitoringTab) {
        showBlogDetails(for: blog, then: .siteMonitoring, userInfo: [
            BlogDetailsViewController.userInfoSiteMonitoringTabKey(): selectedTab.rawValue
        ])
    }
}

private enum Strings {
    static let siteNotFound = NSLocalizedString(
        "universalLink.qrCodeMedia.error.title",
        value: "Site not found",
        comment: "Title for error notice shown if the app can't find a specific site belonging to the user"
    )
    static let checkAccount = NSLocalizedString(
        "universalLink.qrCodeMedia.error.message",
        value: "Check that you are logged into the correct account",
        comment: "Message for error notice shown if the app can't find a specific site belonging to the user"
    )
}
