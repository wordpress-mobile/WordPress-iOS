import Foundation

final class BlogDashboardDynamicCardCoordinator {

    // MARK: - Dependencies

    private let analyticsTracker: AnalyticsEventTracking.Type
    private let model: DashboardDynamicCardModel

    private weak var viewController: UIViewController?

    // MARK: - Init

    init(viewController: UIViewController?,
         model: DashboardDynamicCardModel,
         analyticsTracker: AnalyticsEventTracking.Type = WPAnalytics.self) {
        self.viewController = viewController
        self.model = model
        self.analyticsTracker = analyticsTracker
    }

    // MARK: - API

    func didAppear() {
        self.track(.cardShown(id: model.payload.id), frequency: .oncePerSession)
    }

    func didTapCard() {
        let payload = model.payload
        self.track(.cardTapped(id: payload.id, url: payload.url))
    }

    func didTapCardCTA() {
        let payload = model.payload
        self.track(.cardCtaTapped(id: payload.id, url: payload.url))
    }
}

// MARK: - Analytics

private extension BlogDashboardDynamicCardCoordinator {

    private static var firedAnalyticEvents = Set<DashboardDynamicCardAnalyticsEvent>()

    func track(_ event: DashboardDynamicCardAnalyticsEvent, frequency: DashboardDynamicCardAnalyticsTrackingFrequency = .multipleTimesPerSession) {
        guard frequency == .multipleTimesPerSession || (frequency == .oncePerSession && !Self.firedAnalyticEvents.contains(event)) else {
            return
        }
        self.analyticsTracker.track(.init(name: event.name, properties: event.properties))
        Self.firedAnalyticEvents.insert(event)
    }

    enum DashboardDynamicCardAnalyticsTrackingFrequency {
        case oncePerSession
        case multipleTimesPerSession
    }
}
