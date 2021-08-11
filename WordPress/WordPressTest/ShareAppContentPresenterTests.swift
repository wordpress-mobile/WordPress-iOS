import XCTest
import OHHTTPStubs

@testable import WordPress

final class ShareAppContentPresenterTests: XCTestCase {

    private var contextManager: TestContextManager!
    private var account: WPAccount!
    private var presenter: ShareAppContentPresenter!
    private var viewController: MockViewController!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        account = AccountBuilder(contextManager).build()
        presenter = ShareAppContentPresenter(account: account)
        viewController = MockViewController()
        presenter.delegate = viewController
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()

        contextManager = nil
        account = nil
        presenter = nil
        viewController = nil
    }

    // MARK: Tests

    func test_present_givenValidResponse_presentsShareSheet() {
        stubShareAppLinkResponse(success: true)

        let expectation = expectation(description: "Present share sheet success")
        presenter.present(for: .wordpress, in: viewController) {
            XCTAssertNotNil(self.viewController.viewControllerToPresent)
            XCTAssertTrue(self.viewController.viewControllerToPresent! is UIActivityViewController)
            XCTAssertEqual(self.viewController.stateHistory, [true, false])
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_present_givenFailedResponse_displaysFailureNotice() {
        stubShareAppLinkResponse(success: false)

        let expectation = expectation(description: "Present failure notice success")
        presenter.present(for: .wordpress, in: viewController) {
            XCTAssertNotNil(self.viewController.noticeTitle)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_present_givenCachedContent_immediatelyPresentsShareSheet() {
        stubShareAppLinkResponse(success: true)

        let firstExpectation = expectation(description: "Present share sheet success")
        presenter.present(for: .wordpress, in: viewController) {
            firstExpectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)
        viewController.stateHistory = [] // reset state

        // present the share sheet again.
        let secondExpectation = expectation(description: "Second present share sheet success")
        presenter.present(for: .wordpress, in: viewController) {
            XCTAssertNotNil(self.viewController.viewControllerToPresent)
            XCTAssertTrue(self.viewController.viewControllerToPresent! is UIActivityViewController)
            XCTAssertTrue(self.viewController.stateHistory.isEmpty) // state should still be empty since there should be no more loading state changes.
            secondExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)
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
