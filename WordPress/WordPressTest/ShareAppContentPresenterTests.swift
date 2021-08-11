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
        triggerLoadView(for: viewController!)
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
            XCTAssertNotNil(self.viewController.presentedViewController)
            XCTAssertTrue(self.viewController.presentedViewController! is UIActivityViewController)
            XCTAssertEqual(self.viewController.stateHistory, [true, false])
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.4, handler: nil)
    }

    func test_present_givenFailedResponse_displaysFailureNotice() {
        stubShareAppLinkResponse(success: false)

        let expectation = expectation(description: "Present failure notice success")
        presenter.present(for: .wordpress, in: viewController) {
            XCTAssertNotNil(self.viewController.noticeTitle)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.4, handler: nil)

    }

    func test_present_givenCachedContent_immediatelyPresentsShareSheet() {
        stubShareAppLinkResponse(success: true)

        let firstExpectation = expectation(description: "Present share sheet success")
        presenter.present(for: .wordpress, in: viewController) {
            firstExpectation.fulfill()
        }
        waitForExpectations(timeout: 0.4, handler: nil)
        viewController.presentedViewController?.dismiss(animated: false, completion: nil)
        viewController.stateHistory = [] // reset state

        // present the share sheet again.
        let secondExpectation = expectation(description: "Second present share sheet success")
        presenter.present(for: .wordpress, in: viewController) {
            XCTAssertNotNil(self.viewController.presentedViewController)
            XCTAssertTrue(self.viewController.presentedViewController! is UIActivityViewController)
            XCTAssertTrue(self.viewController.stateHistory.isEmpty)
            secondExpectation.fulfill()
        }
        waitForExpectations(timeout: 0.4, handler: nil)
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

    func triggerLoadView(for viewController: UIViewController) {
        UIWindow().addSubview(viewController.view)
        RunLoop.current.run(until: Date())
    }

}

private class MockViewController: UIViewController, ShareAppContentPresenterDelegate {
    var noticeTitle: String? = nil
    var noticeMessage: String? = nil
    var stateHistory = [Bool]()

    @objc override func displayNotice(title: String, message: String? = nil) {
        noticeTitle = title
        noticeMessage = message
    }

    func didUpdateLoadingState(_ loading: Bool) {
        stateHistory.append(loading)
    }
}
