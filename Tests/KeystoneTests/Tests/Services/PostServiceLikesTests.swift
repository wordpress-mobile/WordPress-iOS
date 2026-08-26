@testable import WordPress
@testable import WordPressData
@testable import WordPressKit
import XCTest

class PostServiceLikesTests: CoreDataTestCase {

    private let siteID: NSNumber = 20
    private let postID: NSNumber = 55

    override func setUp() {
        super.setUp()
        // createNewUsers persists via ContextManager.shared; route it to the test stack.
        contextManager.useAsSharedInstance(untilTestFinished: self)
    }

    private func makeService(returning remote: PostServiceRemoteREST) -> PostService {
        let factory = PostServiceRemoteFactoryMock()
        factory.remoteToReturn = remote
        return PostService(managedObjectContext: mainContext, postServiceRemoteFactory: factory)
    }

    private func insertCachedLikeUser() {
        let dictionary: [String: Any] = [
            "ID": 1,
            "login": "testlogin",
            "name": "Test Name",
            "site_ID": siteID.intValue,
            "date_liked": "2025-11-24T04:02:42+0000"
        ]
        let remoteUser = RemoteLikeUser(dictionary: dictionary, postID: postID, siteID: siteID)
        _ = LikeUserHelper.createOrUpdateFrom(remoteUser: remoteUser, context: mainContext)
        // Save synchronously so the row is committed to the store before the
        // purge's background context fetches it. `contextManager.save(_:)` is
        // asynchronous, which would let the empty-page purge run against a store
        // that does not yet contain the seeded row.
        contextManager.saveContextAndWait(mainContext)
    }

    private func fetchCachedLikeUsers() -> [LikeUser] {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>
        return (try? mainContext.fetch(request)) ?? []
    }

    func testEmptyFirstPagePurgesCachedLikes() {
        insertCachedLikeUser()
        XCTAssertEqual(fetchCachedLikeUsers().count, 1)

        let service = makeService(returning: EmptyLikesRemoteMock())
        let completion = expectation(description: "getLikesFor completes")
        service.getLikesFor(
            postID: postID,
            siteID: siteID,
            success: { users, totalLikes, _ in
                XCTAssertEqual(users.count, 0)
                XCTAssertEqual(totalLikes, 0)
                completion.fulfill()
            },
            failure: { _ in
                XCTFail("The request should succeed")
            }
        )
        waitForExpectations(timeout: 5)

        // A successful empty first page means the post has no likes; the cache must be cleared.
        XCTAssertEqual(fetchCachedLikeUsers().count, 0)
    }

    func testEmptyLaterPageDoesNotPurge() {
        insertCachedLikeUser()

        let service = makeService(returning: EmptyLikesRemoteMock())
        let completion = expectation(description: "getLikesFor completes")
        service.getLikesFor(
            postID: postID,
            siteID: siteID,
            purgeExisting: false,
            success: { _, _, _ in
                completion.fulfill()
            },
            failure: { _ in
                XCTFail("The request should succeed")
            }
        )
        waitForExpectations(timeout: 5)

        // An empty non-first page just means pagination ended; the cache stays.
        XCTAssertEqual(fetchCachedLikeUsers().count, 1)
    }
}

private class PostServiceRemoteFactoryMock: PostServiceRemoteFactory {
    var remoteToReturn: PostServiceRemoteREST?

    override func restRemoteFor(siteID: NSNumber, context: NSManagedObjectContext) -> PostServiceRemoteREST? {
        remoteToReturn
    }
}

// Simulates a successful likes response with zero users ("found": 0).
private class EmptyLikesRemoteMock: PostServiceRemoteREST {
    override func getLikesForPostID(
        _ postID: NSNumber,
        count: NSNumber,
        before: String?,
        excludeUserIDs: [NSNumber]?,
        success: (([RemoteLikeUser], NSNumber) -> Void)?,
        failure: ((Error?) -> Void)?
    ) {
        success?([], 0)
    }
}
