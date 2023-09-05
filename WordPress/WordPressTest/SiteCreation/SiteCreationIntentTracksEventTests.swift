import XCTest
@testable import WordPress

class SiteCreationIntentTracksEventTests: XCTestCase {

    let featureFlags = FeatureFlagOverrideStore()
    let variationEventPropertyKey = "variation"

    override func setUpWithError() throws {
        TestAnalyticsTracker.setup()
    }

    override func tearDownWithError() throws {
        TestAnalyticsTracker.tearDown()
    }

    func siteIntentViewControllerMaker() throws -> SiteIntentViewController {
        let mockSiteCreator = SiteCreator()
        let siteIntentStep = SiteIntentStep(creator: mockSiteCreator)
        let siteIntentViewController = try XCTUnwrap(siteIntentStep.content as? SiteIntentViewController)
        return siteIntentViewController
    }

    func load(_ siteIntentViewController: SiteIntentViewController) {
        siteIntentViewController.loadViewIfNeeded()
        siteIntentViewController.viewDidLoad()
    }

    func tap(_ barButtonItem: UIBarButtonItem?) throws {
        let action = try XCTUnwrap(barButtonItem?.action)
        UIApplication.shared.sendAction(action, to: barButtonItem?.target, from: nil, for: nil)
    }

    func testSiteIntentTracksEventFiresWhenViewed() throws {

        // Given
        let siteIntentViewController = try siteIntentViewControllerMaker()
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationIntentQuestionViewed.value

        // When
        load(siteIntentViewController)

        // Then
        let lastTrackedEvent = try XCTUnwrap(TestAnalyticsTracker.tracked.last?.event)
        XCTAssertEqual(lastTrackedEvent, expectedEvent)
    }

    func testSiteIntentTracksEventFiresWhenCancelled() throws {

        // Given
        let siteIntentViewController = try siteIntentViewControllerMaker()
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationIntentQuestionCanceled.value

        // When
        load(siteIntentViewController)
        try tap(siteIntentViewController.navigationItem.leftBarButtonItem)

        // Then
        let lastTrackedEvent = try XCTUnwrap(TestAnalyticsTracker.tracked.last?.event)
        XCTAssertEqual(lastTrackedEvent, expectedEvent)
    }

    func testSiteIntentTracksEventFiresWhenSkipped() throws {

        // Given
        let siteIntentViewController = try siteIntentViewControllerMaker()
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationIntentQuestionSkipped.value

        // When
        load(siteIntentViewController)
        try tap(siteIntentViewController.navigationItem.rightBarButtonItem)

        // Then
        let lastEventTracked = try XCTUnwrap(TestAnalyticsTracker.tracked.last?.event)
        XCTAssertEqual(lastEventTracked, expectedEvent)
    }
}
