import XCTest
import AutomatticTracks
@testable import WordPress

class SiteCreationNameTracksEventTests: XCTestCase {

    let featureFlags = FeatureFlagOverrideStore()

    private let controlVariant = Variation.control
    private let treatmentVariant = Variation.treatment(nil)

    private let siteNameEventPropertyKey = "site_name"

    override func setUpWithError() throws {
        TestAnalyticsTracker.setup()
        try featureFlags.override(FeatureFlag.siteName, withValue: true)
    }

    override func tearDownWithError() throws {
        TestAnalyticsTracker.tearDown()
        try featureFlags.override(FeatureFlag.siteName, withValue: false)
    }

    func siteNameViewControllerMaker() throws -> SiteNameViewController {
        let mockSiteCreator = SiteCreator()
        let siteNameStep = SiteNameStep(creator: mockSiteCreator)
        let siteIntentViewController = try XCTUnwrap(siteNameStep.content as? SiteNameViewController)
        return siteIntentViewController
    }

    func load(_ siteNameViewController: SiteNameViewController) {
        siteNameViewController.loadViewIfNeeded()
        siteNameViewController.viewDidLoad()
    }

    func tap(_ barButtonItem: UIBarButtonItem?) throws {
        let action = try XCTUnwrap(barButtonItem?.action)
        UIApplication.shared.sendAction(action, to: barButtonItem?.target, from: nil, for: nil)
    }

    func testSiteNameTracksEventFiresWhenViewed() throws {

        // Given
        let siteNameViewController = try siteNameViewControllerMaker()
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationSiteNameViewed.value

        // When
        load(siteNameViewController)

        // Then
        let lastTrackedEvent = try XCTUnwrap(TestAnalyticsTracker.tracked.last?.event)
        XCTAssertEqual(lastTrackedEvent, expectedEvent)
    }

    func testSiteNameTracksEventFiresWhenSkipped() throws {

        // Given
        let siteNameViewController = try siteNameViewControllerMaker()
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationSiteNameSkipped.value

        // When
        load(siteNameViewController)
        try tap(siteNameViewController.navigationItem.rightBarButtonItem)

        // Then
        let trackedEvent = try XCTUnwrap(TestAnalyticsTracker.tracked.last?.event)
        XCTAssertEqual(expectedEvent, trackedEvent)
    }

    func testSiteNameTracksEventFiresWhenCanceled() throws {

        // Given
        let siteNameViewController = try siteNameViewControllerMaker()
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationSiteNameCanceled.value

        // When
        siteNameViewController.viewMovingFromParent()

        // Then
        let trackedEvent = try XCTUnwrap(TestAnalyticsTracker.tracked.last?.event)
        XCTAssertEqual(expectedEvent, trackedEvent)
    }

    func testSiteNameTracksEventFiresWhenEntered() throws {

        // Given
        let siteNameViewController = try siteNameViewControllerMaker()
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationSiteNameEntered.value
        let expectedProperty = "My Test Site"
        let siteNameView = try XCTUnwrap(siteNameViewController.view as? SiteNameView)

        // When
        siteNameView.onContinue(expectedProperty)

        // Then
        let lastTracked = try XCTUnwrap(TestAnalyticsTracker.tracked.last)
        XCTAssertEqual(expectedEvent, lastTracked.event)
        let siteTitle = try XCTUnwrap(lastTracked.properties[siteNameEventPropertyKey] as? String)
        XCTAssertEqual(siteTitle, expectedProperty)
    }
}
