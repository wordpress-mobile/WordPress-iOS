import Foundation

final class BlogDashboardDynamicCardCoordinator {

    // MARK: - Dependencies

    private let analyticsTracker: AnalyticsEventTracking.Type
    private let model: DashboardDynamicCardModel
    private let linkRouter: LinkRouter

    private weak var viewController: UIViewController?

    // MARK: - Init

    init(viewController: UIViewController?,
         model: DashboardDynamicCardModel,
         linkRouter: LinkRouter = UniversalLinkRouter.shared,
         analyticsTracker: AnalyticsEventTracking.Type = WPAnalytics.self) {
        self.viewController = viewController
        self.model = model
        self.linkRouter = linkRouter
        self.analyticsTracker = analyticsTracker
    }

    // MARK: - API

    func didAppear() {
        self.track(.cardShown(id: model.payload.id), frequency: .oncePerSession)
    }

    func didTapCard() {
        let payload = model.payload
        if let urlString = payload.url,
           let url = URL(string: urlString) {
            routeToCardDestination(url: url)
        }
        self.track(.cardTapped(id: payload.id, url: payload.url))
    }

    func didTapCardCTA() {
        let payload = model.payload
        if let urlString = model.payload.url,
           let url = URL(string: urlString) {
            routeToCardDestination(url: url)
        }
        self.track(.cardCtaTapped(id: payload.id, url: payload.url))
    }

    private func routeToCardDestination(url: URL) {
        if linkRouter.canHandle(url: url) {
            routeToUniversalURL(url: url)
        } else {
            routeToWebView(url: url)
        }
    }

    private func routeToWebView(url: URL) {
        guard UIApplication.shared.canOpenURL(url) else {
            return
        }
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticateWithDefaultAccount()
        let controller = WebViewControllerFactory.controller(configuration: configuration, source: "dashboard")
        let navController = UINavigationController(rootViewController: controller)
        viewController?.present(navController, animated: true)
    }

    private func routeToUniversalURL(url: URL) {
        linkRouter.handle(url: url, shouldTrack: true, source: nil)
    }
}

// MARK: - Analytics

private extension BlogDashboardDynamicCardCoordinator {

    private static var firedAnalyticEvents = Set<DashboardDynamicCardAnalyticsEvent>()

    func track(_ event: DashboardDynamicCardAnalyticsEvent, frequency: TrackingFrequency = .multipleTimesPerSession) {
        guard frequency == .multipleTimesPerSession || (frequency == .oncePerSession && !Self.firedAnalyticEvents.contains(event)) else {
            return
        }
        self.analyticsTracker.track(.init(name: event.name, properties: event.properties))
        Self.firedAnalyticEvents.insert(event)
    }

    enum TrackingFrequency {
        case oncePerSession
        case multipleTimesPerSession
    }
}
