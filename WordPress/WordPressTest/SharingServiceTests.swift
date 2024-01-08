import XCTest
import WordPressKit
import OHHTTPStubs

@testable import WordPress

class SharingServiceTests: CoreDataTestCase {

    private let userID = 101
    private let blogID = 10

    private lazy var account: WPAccount = {
        AccountBuilder(contextManager.mainContext)
            .with(id: Int64(userID))
            .with(username: "username")
            .with(authToken: "authToken")
            .build()
    }()

    private lazy var blog: Blog = {
        let blog = BlogBuilder(mainContext).with(blogID: blogID).build()
        blog.account = account

        // ensure that the changes are persisted to the stack.
        contextManager.saveContextAndWait(mainContext)
        return blog
    }()

    // MARK: Sync Publicize Connections

    func testSyncingPublicizeConnectionsForNonDotComBlogCallsACompletionBlock() throws {
        let blog = Blog.createBlankBlog(in: mainContext)
        blog.account = nil

        let expect = expectation(description: "Sharing service completion block called.")

        let sharingService = SharingSyncService(coreDataStack: contextManager)
        sharingService.syncPublicizeConnectionsForBlog(blog) {
            expect.fulfill()
        } failure: { (error) in
            expect.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSyncingPublicizeConnectionsExcludesUnsharedConnections() async throws {
        // Given
        let service = SharingSyncService(coreDataStack: contextManager)

        stub(condition: isPath("/rest/v1.1/sites/\(blogID)/publicize-connections") && isMethodGET()) { _ in
            HTTPStubsResponse(jsonObject: [
                "connections": [
                    ["ID": 1000, "shared": "0", "user_ID": 101] as [String: Any], // owned connection
                    ["ID": 1001, "shared": "1", "user_ID": 201] as [String: Any], // shared connection
                    ["ID": 1002, "shared": "0", "user_ID": 301] as [String: Any], // private connection from others
                ]
            ], statusCode: 200, headers: nil)
        }

        // When
        try await withCheckedThrowingContinuation { continuation in
            service.syncPublicizeConnectionsForBlog(blog) {
                continuation.resume()
            } failure: { error in
                continuation.resume(throwing: error!)
            }
        }

        // Then
        let connections = try XCTUnwrap(blog.connections as? Set<PublicizeConnection>)

        // the one with ID `1002` should be skipped since it's an unshared private connection from another user.
        XCTAssertEqual(connections.count, 2)

        // connections owned by the user should be available.
        XCTAssertTrue(connections.contains(where: { $0.connectionID.isEqual(to: NSNumber(value: 1000)) }))

        // shared connections owned by others should also be available.
        XCTAssertTrue(connections.contains(where: { $0.connectionID.isEqual(to: NSNumber(value: 1001)) }))
    }
}
