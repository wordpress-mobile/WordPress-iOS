
@testable import WordPress
import Nimble

class PostCoordinatorFailedPostsFetcherTests: XCTestCase {
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    private var fetcher: PostCoordinator.FailedPostsFetcher!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
        fetcher = PostCoordinator.FailedPostsFetcher(context)
    }

    override func tearDown() {
        super.tearDown()
        fetcher = nil
        context = nil
        contextManager = nil
    }

    func testItOnlyReturnsLocalDrafts() {
        // Arrange
        let localDrafts = [createPost(), createPost(), createPost()]
        let unexpectedPosts = [
            // Draft from remote
            createPost(hasRemote: true),
            createPost(status: .publish),
            createPost(status: .publishPrivate),
            createPost(status: .scheduled),
            createPost(status: .trash),
            // Local draft that we never attempted to upload
            createPost(remoteStatus: .local)
        ]

        // Act
        let posts = fetcher.getPostsToRetrySync()

        // Assert
        expect(posts).to(haveCount(localDrafts.count))
        expect(posts).to(contain(localDrafts))
        expect(posts).notTo(contain(unexpectedPosts))
    }
}

private extension PostCoordinatorFailedPostsFetcherTests {
    func createPost(status: BasePost.Status = .draft,
                    remoteStatus: AbstractPostRemoteStatus = .failed,
                    hasRemote: Bool = false) -> Post {
        let post = Post(context: context)
        post.status = status
        post.remoteStatus = remoteStatus

        if hasRemote {
            post.postID = NSNumber(value: Int.random(in: 1...Int.max))
        }

        return post
    }
}

private extension PostCoordinator.FailedPostsFetcher {
    func getPostsToRetrySync() -> [AbstractPost] {
        var result = [AbstractPost]()
        waitUntil(timeout: 5) { done in
            self.getPostsToRetry { posts in
                result = posts
                done()
            }
        }
        return result
    }
}

