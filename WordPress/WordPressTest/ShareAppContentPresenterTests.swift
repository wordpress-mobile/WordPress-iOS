import XCTest
import OHHTTPStubs

@testable import WordPress

final class ShareAppContentPresenterTests: XCTestCase {

    private let timeout: TimeInterval = 0.1
    private var contextManager: TestContextManager!
    private var account: WPAccount!
    private var presenter: ShareAppContentPresenter!
    private var viewController: MockViewController!

    override func setUp() {
        super.setUp()

        TestAnalyticsTracker.setup()
        contextManager = TestContextManager()
        account = AccountBuilder(contextManager).build()
        presenter = ShareAppContentPresenter(account: account)
        viewController = MockViewController()
        presenter.delegate = viewController
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        TestAnalyticsTracker.tearDown()

        contextManager = nil
        account = nil
        presenter = nil
        viewController = nil
    }

    // MARK: Tests

    func test_present_givenValidResponse_presentsShareSheet() {
        stubShareAppLinkResponse(success: true)

        let expectation = expectation(description: "Present share sheet success")
        presenter.present(for: .wordpress, in: viewController, source: .me) {
            XCTAssertNotNil(self.viewController.viewControllerToPresent)
            XCTAssertTrue(self.viewController.viewControllerToPresent! is UIActivityViewController)
            XCTAssertEqual(self.viewController.stateHistory, [true, false])
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_present_givenFailedResponse_displaysFailureNotice() {
        stubShareAppLinkResponse(success: false)

        let expectation = expectation(description: "Present failure notice success")
        presenter.present(for: .wordpress, in: viewController, source: .me) {
            XCTAssertNotNil(self.viewController.noticeTitle)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_present_givenCachedContent_immediatelyPresentsShareSheet() {
        stubShareAppLinkResponse(success: true)

        let firstExpectation = expectation(description: "Present share sheet success")
        presenter.present(for: .wordpress, in: viewController, source: .me) {
            firstExpectation.fulfill()
        }
        wait(for: [firstExpectation], timeout: timeout)
        viewController.stateHistory = [] // reset state

        // present the share sheet again.
        let secondExpectation = expectation(description: "Second present share sheet success")
        presenter.present(for: .wordpress, in: viewController, source: .me) {
            XCTAssertNotNil(self.viewController.viewControllerToPresent)
            XCTAssertTrue(self.viewController.viewControllerToPresent! is UIActivityViewController)
            XCTAssertTrue(self.viewController.stateHistory.isEmpty) // state should still be empty since there should be no more loading state changes.
            secondExpectation.fulfill()
        }

        wait(for: [secondExpectation], timeout: timeout)
    }

    // MARK: Tracking

    func test_givenValidResponse_tracksEngagement() {
        stubShareAppLinkResponse(success: true)

        let expectation = expectation(description: "Present share sheet success")
        presenter.present(for: .wordpress, in: viewController, source: .me) {
            XCTAssertEqual(TestAnalyticsTracker.trackedEventsCount(), 1)

            let tracked = TestAnalyticsTracker.tracked.first!
            XCTAssertEqual(tracked.event, WPAnalyticsEvent.recommendAppEngaged.value)
            XCTAssertEqual(tracked.properties["source"]! as! String, ShareAppEventSource.me.rawValue)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_givenCachedContent_tracksEngagement() {
        stubShareAppLinkResponse(success: true)
        let expectedEvents: [WPAnalyticsEvent] = [.recommendAppEngaged, .recommendAppEngaged]
        let expectedSources: [ShareAppEventSource] = [.about, .me]

        let firstExpectation = expectation(description: "Present share sheet success")
        presenter.present(for: .wordpress, in: viewController, source: .about) {
            firstExpectation.fulfill()
        }
        wait(for: [firstExpectation], timeout: timeout)

        // present the share sheet again. the second event should be fired even though cached content is returned.
        let secondExpectation = expectation(description: "Second present share sheet success")
        presenter.present(for: .wordpress, in: viewController, source: .me) {
            XCTAssertEqual(TestAnalyticsTracker.trackedEventsCount(), 2)
            XCTAssertEqual(TestAnalyticsTracker.tracked.map { $0.event }, expectedEvents.map { $0.value })
            XCTAssertEqual(TestAnalyticsTracker.tracked.compactMap { $0.properties["source"] as? String }, expectedSources.map { $0.rawValue })
            secondExpectation.fulfill()
        }

        wait(for: [secondExpectation], timeout: timeout)
    }

    func test_givenFailedResponse_tracksContentFetchFailure() {
        stubShareAppLinkResponse(success: false)

        let expectation = expectation(description: "Present failure notice success")
        presenter.present(for: .wordpress, in: viewController, source: .me) {
            XCTAssertEqual(TestAnalyticsTracker.trackedEventsCount(), 1)
            let tracked = TestAnalyticsTracker.tracked.first!
            XCTAssertEqual(tracked.event, WPAnalyticsEvent.recommendAppContentFetchFailed.value)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }
}

private extension ShareAppContentPresenterTests {

    func stubShareAppLinkResponse(success: Bool) {
        stub(condition: isMethodGET()) { _ in
            if success {
                let stubPath = OHPathForFile("share-app-link-success.json", type(of: self))
                return fixture(filePath: stubPath!, headers: ["Content-Type": "application/json"])
            }

            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }
    }
}

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
