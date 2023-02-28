//
//  BlazeWebViewModelTests.swift
//  WordPressTest
//
//  Created by Hassaan El-Garem on 28/02/2023.
//  Copyright © 2023 WordPress. All rights reserved.
//

import XCTest
@testable import WordPress

final class BlazeWebViewModelTests: CoreDataTestCase {

    // MARK: Private Variables

    private var remoteConfigStore = RemoteConfigStoreMock()
    private var blog: Blog!
    private static let blogURL  = "test.blog.com"

    // MARK: Setup

    override func setUp() {
        super.setUp()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        blog = BlogBuilder(mainContext).with(url: Self.blogURL).build()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: Tests

    func testPostsListStep() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testPostsListStepWithPostsPath() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testCampaignsStep() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/campaigns?source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "campaigns-list")
    }

    func testDefaultWidgetStep() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?blazepress-widget=post-2&source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "step-1")
    }

    func testDefaultWidgetStepWithPostsPath() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2&source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "step-1")
    }

    func testExtractStepFromFragment() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?blazepress-widget=post-2&source=menu_item#step-2"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "step-2")
    }

    func testExtractStepFromFragmentPostsPath() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2&source=menu_item#step-3"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "step-3")
    }

    func testPostsListStepWithoutQuery() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testPostsListStepWithPostsPathWithoutQuery() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testCampaignsStepWithoutQuery() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/campaigns"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "campaigns-list")
    }

    func testDefaultWidgetStepWithoutQuery() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?blazepress-widget=post-2"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "step-1")
    }

    func testDefaultWidgetStepWithPostsPathWithoutQuery() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "step-1")
    }

    func testExtractStepFromFragmentWithoutQuery() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?blazepress-widget=post-2#step-2"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "step-2")
    }

    func testExtractStepFromFragmentPostsPathWithoutQuery() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-3"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "step-3")
    }

    func testInitialStep() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)

        // Then
        XCTAssertEqual(viewModel.currentStep, "unspecified")
    }

    func testCurrentStepMaintainedIfExtractionFails() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let postsListURL = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?source=menu_item"))
        let postsListRequest = URLRequest(url: postsListURL)
        let invalidURL = try XCTUnwrap(URL(string: "https://test.com/test?example=test"))
        let invalidRequest = URLRequest(url: invalidURL)

        // When
        let _ = viewModel.shouldNavigate(request: postsListRequest)

        // Then
        XCTAssertEqual(viewModel.currentStep, "posts-list")

        // When
        let _ = viewModel.shouldNavigate(request: invalidRequest)
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }
}

private class BlazeWebViewMock: BlazeWebView {

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

// 14 tests
// Initial value is unspecified
// If value set then passed wrong url, value doesn't change
// TODO: Remove the above
// TODO: Remove file header
// TODO: Remove teardown
