import XCTest
import OHHTTPStubs
import WordPressKit

@testable import WordPress

final class ShareAppContentPresenterTests: CoreDataTestCase {

    private var account: WPAccount!
    private var presenter: ShareAppContentPresenter!
    private var viewController: MockViewController!
    private var mockRemote: MockShareAppContentServiceRemote!
    private lazy var mockContent: RemoteShareAppContent? = {
        let bundle = Bundle(for: type(of: self))
        guard let file = bundle.url(forResource: "share-app-link-success", withExtension: "json"),
              let data = try? Data(contentsOf: file) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(RemoteShareAppContent.self, from: data)
    }()

    override func setUp() {
        super.setUp()

        TestAnalyticsTracker.setup()
        account = AccountBuilder(contextManager).build()
        mockRemote = MockShareAppContentServiceRemote()
        presenter = ShareAppContentPresenter(remote: mockRemote, account: account)
        viewController = MockViewController()
        presenter.delegate = viewController
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        TestAnalyticsTracker.tearDown()

        account = nil
        presenter = nil
        viewController = nil
    }

    // MARK: Tests

    func test_present_givenValidResponse_presentsShareSheet() {
        // Given
        stubShareAppLinkResponse(success: true)

        // When
        presenter.present(for: .wordpress, in: viewController, source: .me)

        // Then
        XCTAssertNotNil(self.viewController.viewControllerToPresent)
        XCTAssertTrue(self.viewController.viewControllerToPresent! is UIActivityViewController)
        XCTAssertEqual(self.viewController.stateHistory, [true, false])
    }

    func test_present_givenFailedResponse_displaysFailureNotice() {
        // Given
        stubShareAppLinkResponse(success: false)

        // When
        presenter.present(for: .wordpress, in: viewController, source: .me)

        // Then
        XCTAssertNotNil(self.viewController.noticeTitle)
    }

    func test_present_givenCachedContent_immediatelyPresentsShareSheet() {
        // Given
        stubShareAppLinkResponse(success: true)

        // When
        presenter.present(for: .wordpress, in: viewController, source: .me)
        viewController.stateHistory = [] // reset state
        // present the share sheet again.
        presenter.present(for: .wordpress, in: viewController, source: .me)

        // Then
        XCTAssertNotNil(self.viewController.viewControllerToPresent)
        XCTAssertTrue(self.viewController.viewControllerToPresent! is UIActivityViewController)
        XCTAssertTrue(self.viewController.stateHistory.isEmpty) // state should still be empty since there should be no more loading state changes.
    }

    // MARK: Tracking

    func test_givenValidResponse_tracksEngagement() {
        // Given
        stubShareAppLinkResponse(success: true)

        // When
        presenter.present(for: .wordpress, in: viewController, source: .me)

        // Then
        XCTAssertEqual(TestAnalyticsTracker.trackedEventsCount(), 1)
        let tracked = TestAnalyticsTracker.tracked.first!
        XCTAssertEqual(tracked.event, WPAnalyticsEvent.recommendAppEngaged.value)
        XCTAssertEqual(tracked.properties["source"]! as! String, ShareAppEventSource.me.rawValue)
    }

    func test_givenCachedContent_tracksEngagement() {
        // Given
        stubShareAppLinkResponse(success: true)
        let expectedEvents: [WPAnalyticsEvent] = [.recommendAppEngaged, .recommendAppEngaged]
        let expectedSources: [ShareAppEventSource] = [.about, .me]

        // When
        presenter.present(for: .wordpress, in: viewController, source: .about)
        // present the share sheet again. the second event should be fired even though cached content is returned.
        presenter.present(for: .wordpress, in: viewController, source: .me)

        // Then
        XCTAssertEqual(TestAnalyticsTracker.trackedEventsCount(), 2)
        XCTAssertEqual(TestAnalyticsTracker.tracked.map { $0.event }, expectedEvents.map { $0.value })
        XCTAssertEqual(TestAnalyticsTracker.tracked.compactMap { $0.properties["source"] as? String }, expectedSources.map { $0.rawValue })
    }

    func test_givenFailedResponse_tracksContentFetchFailure() {
        // Given
        stubShareAppLinkResponse(success: false)

        // When
        presenter.present(for: .wordpress, in: viewController, source: .me)

        // Then
        XCTAssertEqual(TestAnalyticsTracker.trackedEventsCount(), 1)
        let tracked = TestAnalyticsTracker.tracked.first!
        XCTAssertEqual(tracked.event, WPAnalyticsEvent.recommendAppContentFetchFailed.value)
    }
}

private extension ShareAppContentPresenterTests {

    func stubShareAppLinkResponse(success: Bool) {
        if success {
            guard let content = mockContent else {
                XCTFail("Failed to load mock `RemoteShareAppContent`")
                return
            }

            mockRemote.configure(with: .success(content))
        } else {
            mockRemote.configure(with: .failure(NSError()))
        }
    }
}

// MARK: - MockViewController

private class MockViewController: UIViewController, ShareAppContentPresenterDelegate {
    var noticeTitle: String? = nil
    var noticeMessage: String? = nil
    var stateHistory = [Bool]()
    var viewControllerToPresent: UIViewController? = nil

    @objc override func displayNotice(title: String, message: String? = nil) {
        noticeTitle = title
        noticeMessage = message
    }

    // pretend to present the view, to shave off test time.
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        self.viewControllerToPresent = viewControllerToPresent
    }

    func didUpdateLoadingState(_ loading: Bool) {
        stateHistory.append(loading)
    }
}

// MARK: - MockShareAppContentServiceRemote

private class MockShareAppContentServiceRemote: ShareAppContentServiceRemote {

    private var result: Result<RemoteShareAppContent, Error>?

    func configure(with result: Result<RemoteShareAppContent, Error>) {
        self.result = result
    }

    override func getContent(for appName: ShareAppName, completion: @escaping (Result<RemoteShareAppContent, Error>) -> Void) {
        guard let result = result else {
            return
        }

        completion(result)
    }

}
