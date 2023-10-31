import Nimble
import XCTest

@testable import WordPress

class PostCoordinatorFailedPostsFetcherTests: CoreDataTestCase {
    private var fetcher: PostCoordinator.FailedPostsFetcher!

    override func setUp() {
        super.setUp()

        fetcher = PostCoordinator.FailedPostsFetcher(mainContext)
    }

    override func tearDown() {
        super.tearDown()
        fetcher = nil
    }

    func testItReturnsPostsThatCanBeAutoUploadedOrAutoSaved() {
        // Arrange
        let expectedPosts = [
            createPost(status: .draft),
            createPost(status: .draft),
            createPost(status: .draft),
            createPost(status: .publish),
            createPost(status: .draft, hasRemote: true),
            createPost(status: .publish, hasRemote: true),
            createPost(status: .publishPrivate),
            createPost(status: .publishPrivate, hasRemote: true),
            createPost(status: .scheduled),
            createPost(status: .scheduled, hasRemote: true),
            createPost(status: .pending),
            createPost(status: .pending, hasRemote: true),
        ]
        let unexpectedPosts = [
            createPost(status: .trash),
            createPost(status: .trash, hasRemote: true),
            // Local draft that we never attempted to upload so it never failed
            createPost(status: .draft, remoteStatus: .local)
        ]

        // Act
        let posts = fetcher.getPostsToRetrySync()

        // Assert
        expect(posts).to(haveCount(expectedPosts.count))
        expect(posts).to(contain(expectedPosts))
        expect(posts).notTo(contain(unexpectedPosts))
    }
}

private extension PostCoordinatorFailedPostsFetcherTests {
    func createPost(status: BasePost.Status,
                    remoteStatus: AbstractPostRemoteStatus = .failed,
                    hasRemote: Bool = false,
                    blog: Blog? = nil) -> Post {
        let post = Post(context: mainContext)
        post.status = status
        post.remoteStatus = remoteStatus

        if hasRemote {
            post.postID = NSNumber(value: Int.random(in: 1...Int.max))
        }

        if let blog = blog {
            post.blog = blog
        } else {
            post.blog = createBlog(supportsWPComAPI: true)
        }

        return post
    }

    func createBlog(supportsWPComAPI: Bool) -> Blog {
        let blog = NSEntityDescription.insertNewObject(forEntityName: "Blog", into: mainContext) as! Blog

        if supportsWPComAPI {
            blog.supportsWPComAPI()
        }

        return blog
    }
}

private extension PostCoordinator.FailedPostsFetcher {
    func getPostsToRetrySync() -> [AbstractPost] {
        var result = [AbstractPost]()
        waitUntil(timeout: DispatchTimeInterval.seconds(5)) { done in
            self.postsAndRetryActions { postsAndActions in
                result = Array(postsAndActions.filter { $1 != .nothing }.keys)
                done()
            }
        }
        return result
    }
}
