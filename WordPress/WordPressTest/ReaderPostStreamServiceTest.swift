import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPress

final class ReaderPostStreamServiceTest: CoreDataTestCase {

    lazy var service: ReaderPostStreamService = {
        return .init(coreDataStack: contextManager)
    }()

    override func tearDown() {
        HTTPStubs.removeAllStubs()

        super.tearDown()
    }

    // MARK: Tests

    func testFetchPostsNotRemovingPostsInUseOrSaved() async throws {
        // Given
        let slug = "test"
        let postCount = 5
        let postIDInUse = 1
        let postIDSaved = 3

        stubFetchPostsReturningEmptyResults()

        // Seed tag locally
        let tag = try makeTag(slug, in: mainContext)
        let posts = try seedPosts(for: tag, count: postCount)

        // Mark a post as in use
        let postInUse = try XCTUnwrap(posts.first { $0.postID?.intValue == postIDInUse })
        postInUse.inUse = true

        // Mark a post as saved
        let savedPost = try XCTUnwrap(posts.first { $0.postID?.intValue == postIDSaved })
        savedPost.isSavedForLater = true

        try mainContext.save()

        // When
        try await withCheckedThrowingContinuation { continuation in
            service.fetchPosts(for: tag, isFirstPage: true) { _, _ in
                continuation.resume()
            } failure: { error in
                continuation.resume(throwing: error!)
            }
        }

        // Then
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderPost.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "topic == %@", tag)
        let count = try mainContext.count(for: request)

        // Ensure that posts in use or saved are not wiped
        XCTAssertEqual(count, 2)
    }

    func testFetchPostsWithNonExistentTag() async throws {
        // Given
        stubFetchPostsReturningEmptyResults()

        // Create a "non-existent" tag
        let secondaryStack = coreDataStackForTesting()
        let tag = try makeTag("test", in: secondaryStack.mainContext)

        // When
        let (count, hasMore) = try await withCheckedThrowingContinuation { continuation in
            service.fetchPosts(for: tag, isFirstPage: true) { count, hasMore in
                // the use of checkedThrowingContinuation ensures that the success block should only be called once.
                continuation.resume(returning: (count, hasMore))
            } failure: { error in
                continuation.resume(throwing: error!)
            }
        }

        // Then
        XCTAssertEqual(count, 0)
        XCTAssertFalse(hasMore)
    }

}

// MARK: - Private helpers

private extension ReaderPostStreamServiceTest {

    @discardableResult
    func makeTag(_ slug: String, in context: NSManagedObjectContext) throws -> ReaderTagTopic {
        let topic = ReaderTagTopic(context: context)
        topic.title = slug
        topic.path = "/tags/\(slug)"
        topic.type = ReaderTagTopic.TopicType

        try context.save()
        return topic
    }

    @discardableResult
    func seedPosts(for topic: ReaderAbstractTopic, count: Int = 3) throws -> [ReaderPost] {
        var posts = [ReaderPost]()
        for i in 0..<count {
            let post = ReaderPost(context: mainContext)
            post.postID = NSNumber(value: i)
            post.postTitle = "post\(i)"
            post.content = "post\(i)"
            post.topic = topic
            posts.append(post)
        }

        try mainContext.save()
        return posts
    }

    func stubFetchPostsReturningEmptyResults() {
        stub(condition: isPath("read/tags/posts")) { _ in
            let responseObject: [String: Any] = [
                "success": true,
                "tags": [],
                "sort": "date",
                "lang": "en",
                "page": 1,
                "posts": []
            ]

            return HTTPStubsResponse(jsonObject: responseObject, statusCode: 200, headers: nil)
        }
    }

}
