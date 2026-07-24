@testable import WordPressShared
import Testing

struct DashboardDynamicCardAnalyticsEventTests {

    @Test func testNamesAndProperties() {
        // Given
        let (id, url) = ("123", "https://wordpress.com")

        // When
        let cardShownEvent = DashboardDynamicCardAnalyticsEvent.cardShown(id: id)
        let cardTappedEvent = DashboardDynamicCardAnalyticsEvent.cardTapped(id: id, url: url)
        let cardCTATappedEvent = DashboardDynamicCardAnalyticsEvent.cardCtaTapped(id: id, url: url)

        // Then
        #expect(cardShownEvent.name == "dynamic_dashboard_card_shown")
        #expect(cardTappedEvent.name == "dynamic_dashboard_card_tapped")
        #expect(cardCTATappedEvent.name == "dynamic_dashboard_card_cta_tapped")
        #expect(cardShownEvent.properties == ["id": id])
        #expect(cardTappedEvent.properties == ["id": id, "url": url])
        #expect(cardCTATappedEvent.properties == ["id": id, "url": url])
    }
}
