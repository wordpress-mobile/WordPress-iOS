import XCTest
@testable import WordPress

class SiteCreationIntentTracksEventTests: XCTestCase {

    let featureFlags = FeatureFlagOverrideStore()
    let treatmentVariant = SiteIntentAB.Variant.treatment

    let controlVariant = SiteIntentAB.Variant.control
    let variationEventPropertyKey = "variation"

    override func setUpWithError() throws {
        TestAnalyticsTracker.setup()
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
    }

    override func tearDownWithError() throws {
        TestAnalyticsTracker.tearDown()
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: false)
    }

    func siteIntentViewControllerMaker() throws -> SiteIntentViewController {
        let mockABTestForTreatment = SiteIntentABMock(variant: treatmentVariant)
        let mockSiteCreator = SiteCreator()
        let siteIntentStep = SiteIntentStep(siteIntentAB: mockABTestForTreatment, creator: mockSiteCreator)
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

    func testSiteIntentTracksEventFiresForTreatmentGroup() throws {

        // Given
        let mockABTestForTreatment = SiteIntentABMock(variant: treatmentVariant)
        let mockSiteCreator = SiteCreator()
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationIntentQuestionExperiment.value
        let expectedProperty = treatmentVariant.tracksProperty

        // When
        let _ = SiteIntentStep(siteIntentAB: mockABTestForTreatment, creator: mockSiteCreator)

        // Then
        let firstTracked = try XCTUnwrap(TestAnalyticsTracker.tracked.first)
        XCTAssertEqual(firstTracked.event, expectedEvent)
        let variation = try XCTUnwrap(firstTracked.properties[variationEventPropertyKey] as? String)
        XCTAssertEqual(variation, expectedProperty)
    }

    func testSiteIntentTracksEventFiresForControlGroup() throws {

        // Given
        let mockABTestForControl = SiteIntentABMock(variant: controlVariant)
        let mockSiteCreator = SiteCreator()
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationIntentQuestionExperiment.value
        let expectedProperty = controlVariant.tracksProperty

        // When
        let _ = SiteIntentStep(siteIntentAB: mockABTestForControl, creator: mockSiteCreator)

        // Then
        let firstTracked = try XCTUnwrap(TestAnalyticsTracker.tracked.first)
        XCTAssertEqual(firstTracked.event, expectedEvent)
        let variation = try XCTUnwrap(firstTracked.properties[variationEventPropertyKey] as? String)
        XCTAssertEqual(variation, expectedProperty)
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

    struct SiteIntentABMock: SiteIntentABTestable {
        let variant: SiteIntentAB.Variant
    }
}
