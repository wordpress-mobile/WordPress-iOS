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
        /// same as SiteNameViewController, but simulates moving from parent
        class MockSiteNameViewController: SiteNameViewController {
            override var isMovingFromParent: Bool {
                true
            }
        }
        let siteNameViewController = MockSiteNameViewController(
            siteNameViewFactory: { SiteNameView(siteVerticalName: "",
                                               onContinue: {_ in }) },
            onSkip: { })

        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationSiteNameCanceled.value

        // When
        siteNameViewController.viewWillDisappear(false)

        // Then
        let trackedEvent = try XCTUnwrap(TestAnalyticsTracker.tracked.last?.event)
        XCTAssertEqual(expectedEvent, trackedEvent)
    }

    func testSiteNameTracksEventFiresWhenEntered() throws {

        // Given
        let expectedProperty = "My Test Site"
        let siteNameViewController = try siteNameViewControllerMaker()
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationSiteNameEntered.value
        siteNameViewController.loadViewIfNeeded()

        guard let button = getContinueButton(from: siteNameViewController.view) else {
            XCTFail("Unable to find continue button")
            return
        }
        guard let searchBar = getSearchBar(from: siteNameViewController.view) else {
            XCTFail("Unable to find search bar")
            return
        }
        searchBar.text = expectedProperty

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

        view.subviews.forEach {
            continueButton = getContinueButton(from: $0)

            if let searchBar = $0 as? UISearchBar,
                let button = searchBar.inputAccessoryView?.subviews.first as? UIButton {
                continueButton = button
            }
        }
        return continueButton
    }

    /// Gets a reference to the search bar in a `SiteNameView` instance
    private func getSearchBar(from view: UIView) -> UISearchBar? {
        var searchBar: UISearchBar?

        view.subviews.forEach {
            searchBar = getSearchBar(from: $0)

            if let bar = $0 as? UISearchBar {
                searchBar = bar
            }
        }
        return searchBar
    }
}
