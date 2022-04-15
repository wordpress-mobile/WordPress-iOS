import XCTest
import AutomatticTracks
@testable import WordPress

class SiteCreationNameTracksEventTests: XCTestCase {

    private let siteNameEventPropertyKey = "site_name"

    override func setUpWithError() throws {
        TestAnalyticsTracker.setup()
    }

    override func tearDownWithError() throws {
        TestAnalyticsTracker.tearDown()
    }

    func siteNameViewControllerMaker() throws -> SiteNameViewController {
        let mockSiteCreator = SiteCreator()
        let siteNameStep = SiteNameStep(creator: mockSiteCreator)
        let siteIntentViewController = try XCTUnwrap(siteNameStep.content as? SiteNameViewController)
        return siteIntentViewController
    }

    class MockSiteNameStep: WizardStep {
        weak var delegate: WizardDelegate?
        private let creator: SiteCreator

        var expectedProperty = ""

        var content: UIViewController {
            SiteNameViewController(siteNameViewFactory: makeSiteNameView) { [weak self] in
                SiteCreationAnalyticsHelper.trackSiteNameSkipped()
                self?.didSet(siteName: nil)
            }
        }

        init(creator: SiteCreator) {
            self.creator = creator
        }

        private func didSet(siteName: String?) {
            if let siteName = siteName {
                SiteCreationAnalyticsHelper.trackSiteNameEntered(siteName)
            }

            creator.information = SiteInformation(title: siteName, tagLine: creator.information?.tagLine)
            delegate?.nextStep()
        }

        private func makeSiteNameView() -> UIView {
            SiteNameView(siteVerticalName: creator.vertical?.localizedTitle ?? "") { [weak self] _ in
                self?.didSet(siteName: self?.expectedProperty ?? "")
            }
        }
    }

    func mockSiteNameViewControllerMaker(expectedProperty: String) throws -> SiteNameViewController {
        let siteCreator = SiteCreator()
        let mockSiteNameStep = MockSiteNameStep(creator: siteCreator)
        mockSiteNameStep.expectedProperty = expectedProperty
        let siteIntentViewController = try XCTUnwrap(mockSiteNameStep.content as? SiteNameViewController)
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
        let expectedProperty = "My Test Site"
        let siteNameViewController = try mockSiteNameViewControllerMaker(expectedProperty: expectedProperty)
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationSiteNameEntered.value
        siteNameViewController.loadViewIfNeeded()

        guard let button = getContinueButton(from: siteNameViewController.view) else {
            XCTFail("Unable to find continue button")
            return
        }
        // When
        button.sendActions(for: .touchUpInside)

        // Then
        let lastTracked = try XCTUnwrap(TestAnalyticsTracker.tracked.last)
        XCTAssertEqual(expectedEvent, lastTracked.event)
        let siteTitle = try XCTUnwrap(lastTracked.properties[siteNameEventPropertyKey] as? String)
        XCTAssertEqual(siteTitle, expectedProperty)
    }

    /// Gets a reference to the `Continue` button in a `SiteNameView` instance
    private func getContinueButton(from view: UIView) -> UIButton? {
        var continueButton: UIButton?

        for subview in view.subviews {
            continueButton = getContinueButton(from: subview)

            if let searchBar = subview as? UISearchBar,
                let button = searchBar.inputAccessoryView?.subviews.first as? UIButton {
                continueButton = button
            }
        }
        return continueButton
    }
}
