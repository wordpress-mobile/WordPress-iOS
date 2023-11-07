import Foundation
import XCTest
import OHHTTPStubs

@testable import WordPress

class PostRepositoryPostsListTests: CoreDataTestCase {

    var repository: PostRepository!
    var blogID: TaggedManagedObjectID<Blog>!

    override func setUp() async throws {
        repository = PostRepository(coreDataStack: contextManager)

        let loggedIn = try await signIn()
        blogID = try await contextManager.performAndSave {
            let blog = try BlogBuilder($0)
                .with(dotComID: 42)
                .withAccount(id: loggedIn)
                .build()
            return TaggedManagedObjectID(blog)
        }
    }

    override func tearDown() async throws {
        HTTPStubs.removeAllStubs()
    }

    func testPagination() async throws {
        // Given there are 15 published posts on the site
        stubGetPostsList(type: "post", total: 15)

        // When fetching all of the posts
        let firstPage = try await repository.paginate(type: Post.self, statuses: [.publish], offset: 0, number: 10, in: blogID)
        let secondPage = try await repository.paginate(type: Post.self, statuses: [.publish], offset: 10, number: 10, in: blogID)

        XCTAssertEqual(firstPage.count, 10)
        XCTAssertEqual(secondPage.count, 5)

        // All of the posts are saved
        let total = await contextManager.performQuery { $0.countObjects(ofType: Post.self) }
        XCTAssertEqual(total, 15)
    }

    func testSearching() async throws {
        // Given there are 15 published posts on the site
        stubGetPostsList(type: "post", total: 15)

        // When fetching all of the posts
        let _ = try await repository.paginate(type: Post.self, statuses: [.publish], offset: 0, number: 15, in: blogID)

        // There should 15 posts saved locally before performing search
        var total = await contextManager.performQuery { $0.countObjects(ofType: Post.self) }
        XCTAssertEqual(total, 15)

        // Perform search
        let postIDs: [TaggedManagedObjectID<Post>] = try await repository.search(input: "1", statuses: [.publish], tag: nil, offset: 0, limit: 1, orderBy: .byDate, descending: true, in: blogID)
        XCTAssertEqual(postIDs.count, 1)

        // There should still be 15 posts after the search: no local posts should be deleted
        total = await contextManager.performQuery { $0.countObjects(ofType: Post.self) }
        XCTAssertEqual(total, 15)
    }

    func testFetchingAllPages() async throws {
        stubGetPostsList(type: "page", total: 1_120)

        let pages = try await repository.fetchAllPages(statuses: [], in: blogID).value
        XCTAssertEqual(pages.count, 1_120)

        // There should still be 15 posts after the search: no local posts should be deleted
        let total = await contextManager.performQuery { $0.countObjects(ofType: Page.self) }
        XCTAssertEqual(total, 1_120)
    }

}

extension CoreDataTestCase {

    func signIn() async throws -> NSManagedObjectID {
        let loggedIn = await contextManager.performQuery {
            try? WPAccount.lookupDefaultWordPressComAccount(in: $0)?.objectID
        }
        if let loggedIn {
            return loggedIn
        }

        let service = AccountService(coreDataStack: contextManager)
        return service.createOrUpdateAccount(withUsername: "test-user", authToken: "test-token")
    }

}
