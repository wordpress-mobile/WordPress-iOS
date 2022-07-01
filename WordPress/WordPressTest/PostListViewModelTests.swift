import XCTest
@testable import WordPress

final class PostListViewModelTests: XCTestCase {
    private let mockContextManager = ContextManagerMock()

    func testFilterSettingsIsPostType() {
        let sut = PostListViewModel(blog: makeBlog(), postCoordinator: PostCoordinator())
        XCTAssertEqual(sut.filterSettings.postType, .post)
    }

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
        sut.edit(PostBuilder().build())

        XCTAssertEqual(postFailedCounter, 1)
    }

    func makeBlog() -> Blog {
        return BlogBuilder(mockContextManager.mainContext).isHostedAtWPcom().build()
    }
}
