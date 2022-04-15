import XCTest
import AutomatticTracks
@testable import WordPress

class SiteCreationNameTracksEventTests: XCTestCase {

    private var siteNameStep: SiteNameStep!
    private let siteNameEventPropertyKey = "site_name"

    override func setUpWithError() throws {
        let mockSiteCreator = SiteCreator()
        siteNameStep = SiteNameStep(creator: mockSiteCreator)
        TestAnalyticsTracker.setup()
    }

    override func tearDownWithError() throws {
        siteNameStep = nil
        TestAnalyticsTracker.tearDown()
    }

    func testSiteNameTracksEventFiresWhenViewed() throws {

        // Given
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationSiteNameViewed.value

        // When
        siteNameStep.didView()

        // Then
        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)
        let trackedEvent = try XCTUnwrap(TestAnalyticsTracker.tracked.first?.event)
        XCTAssertEqual(trackedEvent, expectedEvent)
    }

    func testSiteNameTracksEventFiresWhenSkipped() throws {

        // Given
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationSiteNameSkipped.value

        // When
        siteNameStep.didSkip()

        // Then
        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)
        let trackedEvent = try XCTUnwrap(TestAnalyticsTracker.tracked.last?.event)
        XCTAssertEqual(expectedEvent, trackedEvent)
    }

    func testSiteNameTracksEventFiresWhenCanceled() throws {

        // Given
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationSiteNameCanceled.value

        // When
        siteNameStep.didCancel()

        // Then
        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)
        let trackedEvent = try XCTUnwrap(TestAnalyticsTracker.tracked.first?.event)
        XCTAssertEqual(expectedEvent, trackedEvent)
    }

    func testSiteNameTracksEventFiresWhenStringEntered() throws {

        // Given
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationSiteNameEntered.value
        let expectedProperty = "My Test Site"

        // When
        siteNameStep.didSet(siteName: expectedProperty)

        // Then
        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)
        let tracked = try XCTUnwrap(TestAnalyticsTracker.tracked.first)
        XCTAssertEqual(expectedEvent, tracked.event)
        let siteTitle = try XCTUnwrap(tracked.properties[siteNameEventPropertyKey] as? String)
        XCTAssertEqual(siteTitle, expectedProperty)
    }

    func testSiteNameTracksEventDoesNotFireWhenNilEntered() throws {

        // When
        siteNameStep.didSet(siteName: nil)

        // Then
        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 0)
    }
}
