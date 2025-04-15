import Nimble
@testable import WordPress
import XCTest

final class DashboardDynamicCardAnalyticsEventTests: XCTestCase {

    func testNamesAndProperties() {
        // Given
        let (id, url) = ("123", "https://wordpress.com")

        // When
        let cardShownEvent = DashboardDynamicCardAnalyticsEvent.cardShown(id: id)
        let cardTappedEvent = DashboardDynamicCardAnalyticsEvent.cardTapped(id: id, url: url)
        let cardCTATappedEvent = DashboardDynamicCardAnalyticsEvent.cardCtaTapped(id: id, url: url)

        // Then
        XCTAssertEqual(cardShownEvent.name, "dynamic_dashboard_card_shown")
        XCTAssertEqual(cardTappedEvent.name, "dynamic_dashboard_card_tapped")
        XCTAssertEqual(cardCTATappedEvent.name, "dynamic_dashboard_card_cta_tapped")
        XCTAssertEqual(cardShownEvent.properties, ["id": id])
        XCTAssertEqual(cardTappedEvent.properties, ["id": id, "url": url])
        XCTAssertEqual(cardCTATappedEvent.properties, ["id": id, "url": url])
    }
}
