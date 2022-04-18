import XCTest
@testable import WordPress
import Nimble

class PostListFilterTests: XCTestCase {
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
    }

    override func tearDown() {
        super.tearDown()
        context = nil
        contextManager = nil
    }

    func testSortDescriptorForPublished() {
        let filter = PostListFilter.publishedFilter()
        let descriptors = filter.sortDescriptors
        XCTAssertEqual(descriptors.count, 1)
        XCTAssertEqual(descriptors[0].key, "date_created_gmt")
        XCTAssertFalse(descriptors[0].ascending)
    }

    func testSortDescriptorForDrafs() {
        let filter = PostListFilter.draftFilter()
        let descriptors = filter.sortDescriptors
        XCTAssertEqual(descriptors.count, 1)
        XCTAssertEqual(descriptors[0].key, "dateModified")
        XCTAssertFalse(descriptors[0].ascending)
    }

    func testSortDescriptorForScheduled() {
        let filter = PostListFilter.scheduledFilter()
        let descriptors = filter.sortDescriptors
        XCTAssertEqual(descriptors.count, 1)
        XCTAssertEqual(descriptors[0].key, "date_created_gmt")
        XCTAssertTrue(descriptors[0].ascending)
    }

    func testSortDescriptorForTrashed() {
        let filter = PostListFilter.trashedFilter()
        let descriptors = filter.sortDescriptors
        XCTAssertEqual(descriptors.count, 1)
        XCTAssertEqual(descriptors[0].key, "date_created_gmt")
        XCTAssertFalse(descriptors[0].ascending)
    }

    func testSectionIdentifiersMatchSortDescriptors() {
        // Every filter must use the same field as the base for the sort
        // descriptor and the sectionIdentifier.
        //
        // See https://github.com/wordpress-mobile/WordPress-iOS/issues/6476 for
        // more background on the issue.
        //
        // This doesn't test anything that the above tests haven't tested before
        // in theory, but is added as a safeguard, in case we add new filters.
        for filter in PostListFilter.postListFilters() {
            let descriptors = filter.sortDescriptors
            XCTAssertEqual(descriptors.count, 1)
            XCTAssertEqual(descriptors[0].key, filter.sortField.keyPath)
        }
    }

    func testDraftFilterIncludesLocalDraftsAndExistingDraftAndPendingPosts() {
        // Arrange
        let predicate = PostListFilter.draftFilter().predicateForFetchRequest
        let matchingPosts = [
            createPost(.draft),
            createPost(.publish),
            createPost(.scheduled),
            createPost(.publishPrivate),
            createPost(.pending),
            createPost(.draft, hasRemote: true),
            createPost(.pending, hasRemote: true),
            createPost(.draft, hasRemote: true, statusAfterSync: .draft),
            createPost(.pending, hasRemote: true, statusAfterSync: .pending),
        ]
        let nonMatchingPosts = [
            createPost(.trash),
            createPost(.deleted),

            createPost(.publish, hasRemote: true),
            createPost(.publishPrivate, hasRemote: true),
            createPost(.scheduled, hasRemote: true),
            createPost(.trash, hasRemote: true),
        ]

        // Assert
        expect(matchingPosts).to(allPass { predicate.evaluate(with: $0!) == true })
        expect(nonMatchingPosts).to(allPass { predicate.evaluate(with: $0!) == false })
    }

    func testDraftFilterIncludesExistingDraftsAndPendingPostsTransitionedToOtherStatuses() {
        // Arrange
        let predicate = PostListFilter.draftFilter().predicateForFetchRequest
        let matchingPosts = [
            createPost(.publish, hasRemote: true, statusAfterSync: .draft),
            createPost(.publishPrivate, hasRemote: true, statusAfterSync: .draft),
            createPost(.scheduled, hasRemote: true, statusAfterSync: .draft),
            createPost(.pending, hasRemote: true, statusAfterSync: .draft),
            createPost(.trash, hasRemote: true, statusAfterSync: .draft),

            createPost(.publish, hasRemote: true, statusAfterSync: .pending),
            createPost(.publishPrivate, hasRemote: true, statusAfterSync: .pending),
            createPost(.scheduled, hasRemote: true, statusAfterSync: .pending),
            createPost(.pending, hasRemote: true, statusAfterSync: .pending),
            createPost(.trash, hasRemote: true, statusAfterSync: .pending),
        ]

        // Assert
        expect(matchingPosts).to(allPass { predicate.evaluate(with: $0!) == true })
    }

    func testPublishedFilterIncludesExistingPrivateAndRemotePublishedPosts() {
        // Arrange
        let predicate = PostListFilter.publishedFilter().predicateForFetchRequest
        let matchingPosts = [
            createPost(.publish, hasRemote: true),
            createPost(.publishPrivate, hasRemote: true),
            createPost(.publish, hasRemote: true, statusAfterSync: .publish),
            createPost(.publishPrivate, hasRemote: true, statusAfterSync: .publishPrivate),
        ]
        let nonMatchingPosts = [
            createPost(.draft),
            createPost(.publish),
            createPost(.publishPrivate),
            createPost(.scheduled),
            createPost(.trash),
            createPost(.deleted),

            createPost(.draft, hasRemote: true),
            createPost(.scheduled, hasRemote: true),
            createPost(.trash, hasRemote: true),
        ]

        // Assert
        expect(matchingPosts).to(allPass { predicate.evaluate(with: $0!) == true })
        expect(nonMatchingPosts).to(allPass { predicate.evaluate(with: $0!) == false })
    }

    func testPublishedFilterIncludesExistingPublishedAndPrivatePostsTransitionedToOtherStatuses() {
        // Arrange
        let predicate = PostListFilter.publishedFilter().predicateForFetchRequest
        let matchingPosts = [
            createPost(.draft, hasRemote: true, statusAfterSync: .publish),
            createPost(.publishPrivate, hasRemote: true, statusAfterSync: .publish),
            createPost(.scheduled, hasRemote: true, statusAfterSync: .publish),
            createPost(.pending, hasRemote: true, statusAfterSync: .publish),
            createPost(.trash, hasRemote: true, statusAfterSync: .publish),

            createPost(.draft, hasRemote: true, statusAfterSync: .publishPrivate),
            createPost(.publishPrivate, hasRemote: true, statusAfterSync: .publishPrivate),
            createPost(.scheduled, hasRemote: true, statusAfterSync: .publishPrivate),
            createPost(.pending, hasRemote: true, statusAfterSync: .publishPrivate),
            createPost(.trash, hasRemote: true, statusAfterSync: .publishPrivate),
        ]

        // Assert
        expect(matchingPosts).to(allPass { predicate.evaluate(with: $0!) == true })
    }

    func testScheduledFilterIncludesExistingScheduledPostsOnly() {
        // Arrange
        let predicate = PostListFilter.scheduledFilter().predicateForFetchRequest
        let matchingPosts = [
            createPost(.scheduled, hasRemote: true),
            createPost(.scheduled, hasRemote: true, statusAfterSync: .scheduled),
        ]
        let nonMatchingPosts = [
            createPost(.draft),
            createPost(.scheduled),
            createPost(.publish),
            createPost(.publishPrivate),
            createPost(.trash),
            createPost(.deleted),

            createPost(.trash, hasRemote: true),
            createPost(.draft, hasRemote: true),
            createPost(.publish, hasRemote: true),
            createPost(.publishPrivate, hasRemote: true),
        ]

        // Assert
        expect(matchingPosts).to(allPass { predicate.evaluate(with: $0!) == true })
        expect(nonMatchingPosts).to(allPass { predicate.evaluate(with: $0!) == false })
    }

    func testScheduledFilterIncludesExistingScheduledPostsTransitionedToOtherStatuses() {
        // Arrange
        let predicate = PostListFilter.scheduledFilter().predicateForFetchRequest
        let matchingPosts = [
            createPost(.draft, hasRemote: true, statusAfterSync: .scheduled),
            createPost(.publish, hasRemote: true, statusAfterSync: .scheduled),
            createPost(.publishPrivate, hasRemote: true, statusAfterSync: .scheduled),
            createPost(.pending, hasRemote: true, statusAfterSync: .scheduled),
            createPost(.trash, hasRemote: true, statusAfterSync: .scheduled),
        ]

        // Assert
        expect(matchingPosts).to(allPass { predicate.evaluate(with: $0!) == true })
    }
}

private extension PostListFilterTests {
    func createPost(_ status: BasePost.Status,
                    hasRemote: Bool = false,
                    statusAfterSync: BasePost.Status? = nil) -> Post {
        let post = Post(context: context)
        post.status = status
        post.statusAfterSync = statusAfterSync

        if hasRemote {
            post.postID = NSNumber(value: Int.random(in: 1...Int.max))
        }

        return post
    }
}
