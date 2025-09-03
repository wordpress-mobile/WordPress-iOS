import Foundation
import XCTest
@testable import WordPressKit

class SubscribersServiceRemoteTests: RemoteTestCase, RESTTestable {
    func testDecodeSubscribersResponse() throws {
        let data = try JSONLoader.data(named: "site-subscribers-response")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.supportMultipleDateFormats

        let response = try decoder.decode(SubscribersServiceRemote.GetSubscribersResponse.self, from: data)

        XCTAssertEqual(response.total, 1)

        let subscriber = try XCTUnwrap(response.subscribers.first)
        XCTAssertEqual(subscriber.dotComUserID, 1)
    }

    func testDecoderSubscriberDetailsResponse() throws {
        let data = try JSONLoader.data(named: "site-subscriber-get-details-response")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.supportMultipleDateFormats

        let response = try decoder.decode(SubscribersServiceRemote.GetSubscriberDetailsResponse.self, from: data)

        XCTAssertEqual(response.country?.code, "US")
        XCTAssertEqual(response.country?.name, "United States")

        let plan = try XCTUnwrap(response.plans?.first)
        XCTAssertFalse(plan.isGift)
        XCTAssertEqual(plan.status, "active")
        XCTAssertEqual(plan.paidSubscriptionId, "12422686")
    }

    func testDecoderSubscriberDetailsInvalidCountry() throws {
        let data = try JSONLoader.data(named: "site-subscriber-get-details-response-invalid-country")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.supportMultipleDateFormats

        let response = try decoder.decode(SubscribersServiceRemote.GetSubscriberDetailsResponse.self, from: data)

        XCTAssertNil(response.country)
    }

    func testDecoderSubscriberStatsResponse() throws {
        let data = try JSONLoader.data(named: "site-subscriber-stats-response")

        let decoder = JSONDecoder.apiDecoder
        let response = try decoder.decode(SubscribersServiceRemote.GetSubscriberStatsResponse.self, from: data)

        XCTAssertEqual(response.emailsSent, 1)
        XCTAssertEqual(response.uniqueOpens, 2)
        XCTAssertEqual(response.uniqueClicks, 3)
    }
}
