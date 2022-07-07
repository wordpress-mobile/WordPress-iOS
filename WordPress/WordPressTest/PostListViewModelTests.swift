import XCTest
@testable import WordPress

final class PostListViewModelTests: XCTestCase {
    private let mockContextManager = ContextManagerMock()

    // MARK: - FilterSettings
    func testFilterSettingsIsPostType() {
        let sut = PostListViewModel(blog: makeBlog(), postCoordinator: PostCoordinator())
        XCTAssertEqual(sut.filterSettings.postType, .post)
    }

    // MARK: - Edit
    func testEditInvokesFailureWhenPostIsUploading() {
        class MockPostCoordinator: PostCoordinator {
            override func isUploading(post: AbstractPost) -> Bool {
                true
            }
        }

        let sut = PostListViewModel(blog: makeBlog(), postCoordinator: MockPostCoordinator())

        var postFailedCounter = 0
        sut.editingPostUploadFailed = {
            postFailedCounter += 1
        }
        sut.edit(PostBuilder().build())

        XCTAssertEqual(postFailedCounter, 1)
    }

    func testEditInvokesSuccessWhenPostIsUploading() {
        class MockPostCoordinator: PostCoordinator {
            override func isUploading(post: AbstractPost) -> Bool {
                true
            }
        }

        let sut = PostListViewModel(blog: makeBlog(), postCoordinator: MockPostCoordinator())

        var postFailedCounter = 0
        sut.editingPostUploadFailed = {
            postFailedCounter += 1
        }
        sut.edit(PostBuilder(mockContextManager.mainContext).build())

        XCTAssertEqual(postFailedCounter, 1)
    }

    // MARK: - Stats
    func testStatsDoesNotInvokeStatsConfiguredWhenBlogAccountIsNil() {
        let blog = BlogBuilder(mockContextManager.mainContext).withJetpack().build()
        let sut = PostListViewModel(
            blog: blog,
            postCoordinator: PostCoordinator(),
            reachabilityUtility: MockReachabilityUtility()
        )

        var statsConfiguredCallCount = 0
        sut.statsConfigured = { (_, _, _) in
            statsConfiguredCallCount += 1
        }

        sut.stats(for: PostBuilder(mockContextManager.mainContext, blog: blog).build())
        XCTAssertEqual(statsConfiguredCallCount, 0)
    }

    func testStatsDoesNotInvokeStatsConfiguredWhenPostHasNoID() {
        let blog = makeBlog()

        let sut = PostListViewModel(
            blog: blog,
            postCoordinator: PostCoordinator(),
            reachabilityUtility: MockReachabilityUtility()
        )

        var statsConfiguredCallCount = 0
        sut.statsConfigured = { (_, _, _) in
            statsConfiguredCallCount += 1
        }

        sut.stats(for: PostBuilder(mockContextManager.mainContext, blog: blog).with(id: nil).build())
        XCTAssertEqual(statsConfiguredCallCount, 0)
    }

    func testStatsDoesNotInvokeStatsConfiguredWhenPostPermaLinkIsNil() {
        let blog = makeBlog()

        let sut = PostListViewModel(
            blog: blog,
            postCoordinator: PostCoordinator(),
            reachabilityUtility: MockReachabilityUtility()
        )

        var statsConfiguredCallCount = 0
        sut.statsConfigured = { (_, _, _) in
            statsConfiguredCallCount += 1
        }

        sut.stats(for: PostBuilder(mockContextManager.mainContext, blog: blog)
            .with(id: 1239)
            .with(permaLink: nil)
            .build())
        XCTAssertEqual(statsConfiguredCallCount, 0)
    }

    func testStatsInvokesStatsConfiguredWhenAccountIsNotNilAndPostHasID() {
        let blog = makeBlog()

        let sut = PostListViewModel(
            blog: blog,
            postCoordinator: PostCoordinator(),
            reachabilityUtility: MockReachabilityUtility()
        )

        var statsConfiguredCallCount = 0
        sut.statsConfigured = { (_, _, _) in
            statsConfiguredCallCount += 1
        }

        sut.stats(for: PostBuilder(mockContextManager.mainContext, blog: blog)
            .with(id: 1239)
            .with(permaLink: "https://wordpress.com")
            .build())
        XCTAssertEqual(statsConfiguredCallCount, 1)
    }

    func testStatsDoesNotInvokeStatsConfiguredWhenRequirementsAreMetButNoReachability() {
        class _MockReachabilityUtility: PostListReachabilityProvider {
            func performActionIfConnectionAvailable(_ action: (() -> Void)) {
                // No reachability so action is not called.
            }
        }

        let blog = makeBlog()

        let sut = PostListViewModel(
            blog: blog,
            postCoordinator: PostCoordinator(),
            reachabilityUtility: _MockReachabilityUtility()
        )

        var statsConfiguredCallCount = 0
        sut.statsConfigured = { (_, _, _) in
            statsConfiguredCallCount += 1
        }

        sut.stats(for: PostBuilder(mockContextManager.mainContext, blog: blog)
            .with(id: 1239)
            .with(permaLink: "https://wordpress.com")
            .build())
        XCTAssertEqual(statsConfiguredCallCount, 0)
    }

    private func makeBlog() -> Blog {
        return BlogBuilder(mockContextManager.mainContext).withAnAccount().withJetpack().build()
    }
}

private class MockReachabilityUtility: PostListReachabilityProvider {
    func performActionIfConnectionAvailable(_ action: (() -> Void)) {
        action()
    }
}
