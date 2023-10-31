import XCTest
@testable import WordPress

final class BlazeCreateCampaignWebViewModelTests: CoreDataTestCase {

    // MARK: Private Variables

    private var view: BlazeWebViewMock!
    private var externalURLHandler: ExternalURLHandlerMock!
    private var remoteConfigStore = RemoteConfigStoreMock()
    private var blog: Blog!
    private static let blogURL = "test.blog.com"

    // MARK: Setup

    override func setUp() {
        super.setUp()
        view = BlazeWebViewMock()
        externalURLHandler = ExternalURLHandlerMock()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        blog = BlogBuilder(mainContext).with(url: Self.blogURL).build()
        remoteConfigStore.blazeNonDismissibleStep = "step-4"
        remoteConfigStore.blazeFlowCompletedStep = "step-5"
    }

    // MARK: Tests

    func testPostsListStep() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testPostsListStepWithPostsPath() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testCampaignsStep() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/campaigns?source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "campaigns-list")
    }

    func testDefaultWidgetStep() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?blazepress-widget=post-2&source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "step-1")
    }

    func testDefaultWidgetStepWithPostsPath() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2&source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "step-1")
    }

    func testExtractStepFromFragment() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?blazepress-widget=post-2&source=menu_item#step-2"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "step-2")
    }

    func testExtractStepFromFragmentPostsPath() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2&source=menu_item#step-3"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "step-3")
    }

    func testPostsListStepWithoutQuery() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testPostsListStepWithPostsPathWithoutQuery() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testCampaignsStepWithoutQuery() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/campaigns"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "campaigns-list")
    }

    func testDefaultWidgetStepWithoutQuery() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?blazepress-widget=post-2"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "step-1")
    }

    func testDefaultWidgetStepWithPostsPathWithoutQuery() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "step-1")
    }

    func testExtractStepFromFragmentWithoutQuery() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?blazepress-widget=post-2#step-2"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "step-2")
    }

    func testExtractStepFromFragmentPostsPathWithoutQuery() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-3"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "step-3")
    }

    func testInitialStep() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)

        // Then
        XCTAssertEqual(viewModel.currentStep, "unspecified")
    }

    func testCurrentStepMaintainedIfExtractionFails() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let postsListURL = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?source=menu_item"))
        let postsListRequest = URLRequest(url: postsListURL)
        let invalidURL = try XCTUnwrap(URL(string: "https://test.com/test?example=test"))
        let invalidRequest = URLRequest(url: invalidURL)

        // When
        let _ = viewModel.shouldNavigate(to: postsListRequest, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "posts-list")

        // When
        let _ = viewModel.shouldNavigate(to: invalidRequest, with: .linkActivated)

        // Then
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testInternalURLsAllowed() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
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
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
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

    func testCallingShouldNavigateReloadsTheNavBar() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertTrue(view.reloadNavBarCalled)
    }

    func testCallingDismissTappedDismissesTheView() {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)

        // When
        viewModel.dismissTapped()

        // Then
        XCTAssertTrue(view.dismissViewCalled)
    }

    func testCallingStartBlazeSiteFlowLoadsTheView() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, externalURLHandler: externalURLHandler)

        // When
        viewModel.startBlazeFlow()

        // Then
        XCTAssertTrue(view.loadCalled)
        XCTAssertEqual(view.requestLoaded?.url?.absoluteString, "https://wordpress.com/advertising/test.blog.com?source=menu_item")
    }

    func testCallingStartBlazePostFlowLoadsTheView() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: 1, view: view, externalURLHandler: externalURLHandler)

        // When
        viewModel.startBlazeFlow()

        // Then
        XCTAssertTrue(view.loadCalled)
        XCTAssertEqual(view.requestLoaded?.url?.absoluteString, "https://wordpress.com/advertising/test.blog.com?blazepress-widget=post-1&source=menu_item")
    }

    func testIsCurrentStepDismissible() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, remoteConfigStore: remoteConfigStore, externalURLHandler: externalURLHandler)

        // When
        var url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-1"))
        var request = URLRequest(url: url)
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertTrue(viewModel.isCurrentStepDismissible())

        // When
        url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-4"))
        request = URLRequest(url: url)
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertFalse(viewModel.isCurrentStepDismissible())

        // When
        url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-5"))
        request = URLRequest(url: url)
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertTrue(viewModel.isCurrentStepDismissible())
    }

    func testIsFlowCompleted() throws {
        // Given
        let viewModel = BlazeCreateCampaignWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, remoteConfigStore: remoteConfigStore, externalURLHandler: externalURLHandler)

        // When
        var url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-1"))
        var request = URLRequest(url: url)
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertFalse(viewModel.isFlowCompleted)

        // When
        url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-5"))
        request = URLRequest(url: url)
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertTrue(viewModel.isFlowCompleted)

        // When
        url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-1"))
        request = URLRequest(url: url)
        let _ = viewModel.shouldNavigate(to: request, with: .linkActivated)

        // Then
        XCTAssertFalse(viewModel.isFlowCompleted)
    }
}

private class BlazeWebViewMock: NSObject, BlazeWebView {

    var loadCalled = false
    var requestLoaded: URLRequest?
    var reloadNavBarCalled = false
    var dismissViewCalled = false

    func load(request: URLRequest) {
        loadCalled = true
        requestLoaded = request
    }

    func reloadNavBar() {
        reloadNavBarCalled = true
    }

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
