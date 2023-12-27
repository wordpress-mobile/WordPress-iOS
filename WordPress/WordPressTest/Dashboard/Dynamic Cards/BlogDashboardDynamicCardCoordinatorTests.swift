import Nimble
@testable import WordPress
import XCTest

final class BlogDashboardDynamicCardCoordinatorTests: XCTestCase {

    override func setUp() {
        super.setUp()

        // Because AnalyticsEventTrackingSpy logs events in a static var, we need to reset it between tests
        AnalyticsEventTrackingSpy.reset()
    }

    func test_trackAnalyticEventWhenDidAppearIsCalled() {
        // Given
        let id = "123"
        let event = DashboardDynamicCardAnalyticsEvent.cardShown(id: id)
        let coordinator = makeCoordinator(id: id)

        // When
        coordinator.didAppear()
        coordinator.didAppear()
        coordinator.didAppear()

        // Then
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(haveCount(1))
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(containElementSatisfying({ firedEvent in
            firedEvent.name == event.name && firedEvent.properties == event.properties
        }))
    }

    func test_trackAnalyticEventWhenDidTapCardIsCalled() {
        // Given
        let (id, url) = ("123", "https://wordpress.com")
        let event = DashboardDynamicCardAnalyticsEvent.cardTapped(id: id, url: url)
        let coordinator = makeCoordinator(id: id, url: url)

        // When
        coordinator.didTapCard()
        coordinator.didTapCard()
        coordinator.didTapCard()

        // Then
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(haveCount(3))
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(containElementSatisfying({ firedEvent in
            firedEvent.name == event.name && firedEvent.properties == event.properties
        }))
    }

    func test_trackAnalyticEventWhenDidTapCardCtaIsCalled() {
        // Given
        let (id, url) = ("123", "https://wordpress.com")
        let event = DashboardDynamicCardAnalyticsEvent.cardCtaTapped(id: id, url: url)
        let coordinator = makeCoordinator(id: id, url: url)

        // When
        coordinator.didTapCardCTA()
        coordinator.didTapCardCTA()
        coordinator.didTapCardCTA()

        // Then
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(haveCount(3))
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(containElementSatisfying({ firedEvent in
            firedEvent.name == event.name && firedEvent.properties == event.properties
        }))
    }

    // MARK: - Helpers

    private func makeCoordinator(id: String, url: String? = nil) -> BlogDashboardDynamicCardCoordinator {
        let payload = DashboardDynamicCardModel.Payload(
            id: id,
            remoteFeatureFlag: "default",
            title: "Domain Management",
            featuredImage: "https://wordpress.com",
            url: url,
            action: "Read more",
            order: .top,
            rows: nil
        )
        return .init(
            viewController: UIViewController(),
            model: .init(payload: payload, dotComID: 1),
            analyticsTracker: AnalyticsEventTrackingSpy.self
        )
    }
}
