import XCTest
@testable import WordPress

final class BlazeCampaignDetailsWebViewModelTests: CoreDataTestCase {

    // MARK: Private Variables

    private var view: BlazeWebViewMock!
    private var externalURLHandler: ExternalURLHandlerMock!
    private var blog: Blog!
    private static let blogURL = "test.blog.com"

    // MARK: Setup

    override func setUp() {
        super.setUp()
        view = BlazeWebViewMock()
        externalURLHandler = ExternalURLHandlerMock()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        blog = BlogBuilder(mainContext).with(url: Self.blogURL).build()
    }

    // MARK: Tests

    func testInternalURLsAllowed() throws {
        // Given
        let viewModel = BlazeCampaignDetailsWebViewModel(source: .campaignList, blog: blog, campaignID: 0, view: view, externalURLHandler: externalURLHandler)
        let validURL = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?source=menu_item"))
        var validRequest = URLRequest(url: validURL)
        validRequest.mainDocumentURL = validURL

        // When
        let policy = viewModel.shouldNavigate(to: validRequest, with: .linkActivated)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertFalse(externalURLHandler.openURLCalled)
    }

    func testExternalURLsBlocked() throws {
        // Given
        let viewModel = BlazeCampaignDetailsWebViewModel(source: .campaignList, blog: blog, campaignID: 0, view: view, externalURLHandler: externalURLHandler)
        let invalidURL = try XCTUnwrap(URL(string: "https://test.com/test?example=test"))
        var invalidRequest = URLRequest(url: invalidURL)
        invalidRequest.mainDocumentURL = invalidURL

        // When
        let policy = viewModel.shouldNavigate(to: invalidRequest, with: .linkActivated)

        // Then
        XCTAssertEqual(policy, .cancel)
        XCTAssertTrue(externalURLHandler.openURLCalled)
        XCTAssertEqual(externalURLHandler.urlOpened?.absoluteString, invalidURL.absoluteString)
    }

    func testCallingDismissTappedDismissesTheView() {
        // Given
        let viewModel = BlazeCampaignDetailsWebViewModel(source: .campaignList, blog: blog, campaignID: 0, view: view, externalURLHandler: externalURLHandler)

        // When
        viewModel.dismissTapped()

        // Then
        XCTAssertTrue(view.dismissViewCalled)
    }

    func testCallingStartBlazeSiteFlowLoadsTheView() throws {
        // Given
        let viewModel = BlazeCampaignDetailsWebViewModel(source: .campaignList, blog: blog, campaignID: 0, view: view, externalURLHandler: externalURLHandler)

        // When
        viewModel.startBlazeFlow()

        // Then
        XCTAssertTrue(view.loadCalled)
        XCTAssertEqual(view.requestLoaded?.url?.absoluteString, "https://wordpress.com/advertising/campaigns/0/test.blog.com?source=campaign_list")
    }
}

private class BlazeWebViewMock: NSObject, BlazeWebView {

    var loadCalled = false
    var requestLoaded: URLRequest?
    var dismissViewCalled = false

    func load(request: URLRequest) {
        loadCalled = true
        requestLoaded = request
    }

    func reloadNavBar() {}

    func dismissView() {
        dismissViewCalled = true
    }

    var cookieJar: WordPress.CookieJar = MockCookieJar()
}

private class ExternalURLHandlerMock: ExternalURLHandler {

    var openURLCalled = false
    var urlOpened: URL?

    func open(_ url: URL) {
        self.openURLCalled = true
        self.urlOpened = url
    }
}
