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

    func testDraftFilterOnlyIncludesDraftsAndLocalPublishedPosts() {
        // Arrange
        let predicate = PostListFilter.draftFilter().predicateForFetchRequest
        let matchingPosts = [
            createPost(.draft),
            createPost(.draft, hasRemote: true),
            createPost(.publish),
        ]
        let nonMatchingPosts = [
            createPost(.publish, hasRemote: true),
            createPost(.publishPrivate),
            createPost(.publishPrivate, hasRemote: true),
            createPost(.scheduled),
            createPost(.scheduled, hasRemote: true),
            createPost(.trash),
            createPost(.trash, hasRemote: true)
        ]

        // Assert
        expect(matchingPosts).to(allPass { predicate.evaluate(with: $0!) == true })
        expect(nonMatchingPosts).to(allPass { predicate.evaluate(with: $0!) == false })
    }

    func testPublishedFilterOnlyIncludesPrivateAndRemotePublishedPosts() {
        // Arrange
        let predicate = PostListFilter.publishedFilter().predicateForFetchRequest
        let matchingPosts = [
            createPost(.publish, hasRemote: true),
            createPost(.publishPrivate),
            createPost(.publishPrivate, hasRemote: true),
        ]
        let nonMatchingPosts = [
            createPost(.draft),
            createPost(.draft, hasRemote: true),
            createPost(.publish),
            createPost(.scheduled),
            createPost(.scheduled, hasRemote: true),
            createPost(.trash),
            createPost(.trash, hasRemote: true)
        ]

        // Assert
        expect(matchingPosts).to(allPass { predicate.evaluate(with: $0!) == true })
        expect(nonMatchingPosts).to(allPass { predicate.evaluate(with: $0!) == false })
    }
}

private extension PostListFilterTests {
    func createPost(_ status: BasePost.Status, hasRemote: Bool = false) -> Post {
        let post = Post(context: context)
        post.status = status

        if hasRemote {
            post.postID = NSNumber(value: Int.random(in: 1...Int.max))
        }

        return post
    }
}
