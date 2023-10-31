@testable import WordPress
import XCTest

class LikeUserHelperTests: CoreDataTestCase {

    var siteID: NSNumber = 20

    func createTestRemoteUserDictionary(
        withPreferredBlog hasPreferredBlog: Bool,
        siteID: Int? = nil,
        year: Int = 2021
    ) -> [String: Any] {
        var remoteUserDictionary: [String: Any] = [
            "ID": Int.random(in: 0...Int.max),
            "login": "testlogin",
            "name": "testname",
            "site_ID": siteID ?? self.siteID.intValue,
            "avatar_URL": "wordpress.org/test2",
            "bio": "testbio",
            "date_liked": "\(year)-11-24T04:02:42+0000",
        ]

        if hasPreferredBlog {
            remoteUserDictionary["preferred_blog"] = [
                "id": 1,
                "url": "wordpress.org/test1",
                "name": "testblog",
                "icon": [
                    "img": "someimage.jpg",
                ]
            ] as [String: Any]
        }

        return remoteUserDictionary
    }

    func testNewLikeUserWithPreferredBlog() {
        let completionExpectation = expectation(description: "We expect the context to save successfully")
        let context = contextManager.mainContext

        let remoteUserDictionary = createTestRemoteUserDictionary(withPreferredBlog: true)
        let remoteUser = RemoteLikeUser(dictionary: remoteUserDictionary, commentID: 25, siteID: 30)
        let likeUser = LikeUserHelper.createOrUpdateFrom(remoteUser: remoteUser, context: context)
        XCTAssertNotNil(likeUser)

        // TODO: The save crashes when it fails, interrupting all other tests.
        contextManager.save(context, completion: {
            completionExpectation.fulfill()
        }, on: .main)

        waitForExpectations(timeout: 5)
    }

    func testUpdatingExistingUserToRemovePreferredBlog() {
        let completionExpectation = expectation(description: "We expect the context to save successfully")
        let context = contextManager.mainContext

        // First we create the pre-existing user, so we can later modify it to remove the preferred blog

        let remoteUserDictionary = createTestRemoteUserDictionary(withPreferredBlog: true)
        let remoteUser = RemoteLikeUser(dictionary: remoteUserDictionary, commentID: 25, siteID: 30)
        let existingLikeUser = LikeUserHelper.createOrUpdateFrom(remoteUser: remoteUser, context: context)
        guard let existingPreferredBlog = existingLikeUser.preferredBlog else {
            XCTFail()
            return
        }

        XCTAssertNotNil(existingLikeUser)
        // TODO: The save crashes when it fails, interrupting all other tests.
        contextManager.save(context)

        // Then we remove the preferred blog from the remote user, so we can save it again and make sure
        // the preferred blog deletion works fine.
        remoteUser.preferredBlog = nil
        let updatedLikeUser = LikeUserHelper.createOrUpdateFrom(remoteUser: remoteUser, context: context)
        XCTAssertNotNil(updatedLikeUser)
        XCTAssertTrue(existingPreferredBlog.isDeleted)

        // TODO: The save crashes when it fails, interrupting all other tests.
        contextManager.save(context, completion: {
            completionExpectation.fulfill()
        }, on: .main)

        waitForExpectations(timeout: 5)
    }

    func testFetchingLikedUser() {
        XCTAssertEqual(mainContext.countObjects(ofType: LikeUser.self), 0)

        let commentID: NSNumber = 1
        let otherCommentID: NSNumber = 2
        // Insert likes with a recent date
        for _ in 1...10 {
            let dict = createTestRemoteUserDictionary(withPreferredBlog: false, year: 2010)
            let user = RemoteLikeUser(dictionary: dict, commentID: commentID, siteID: siteID)
            _ = LikeUserHelper.createOrUpdateFrom(remoteUser: user, context: mainContext)
        }
        // Insert likes with an older date
        for _ in 1...5 {
            let dict = createTestRemoteUserDictionary(withPreferredBlog: false, year: 1990)
            let user = RemoteLikeUser(dictionary: dict, commentID: commentID, siteID: siteID)
            _ = LikeUserHelper.createOrUpdateFrom(remoteUser: user, context: mainContext)
        }
        // Insert likes on another comment
        for _ in 1...3 {
            let dict = createTestRemoteUserDictionary(withPreferredBlog: false)
            let user = RemoteLikeUser(dictionary: dict, commentID: otherCommentID, siteID: siteID)
            _ = LikeUserHelper.createOrUpdateFrom(remoteUser: user, context: mainContext)
        }

        // There are 18 like saved in the database in total
        XCTAssertEqual(mainContext.countObjects(ofType: LikeUser.self), 18)

        // There are 15 likes on the comment with `commentID`
        XCTAssertEqual(LikeUserHelper.likeUsersFor(commentID: commentID, siteID: siteID, in: mainContext).count, 15)

        // There are 10 likes since 2001 and 5 likes before.
        // How the `after` argument should behave might be confusing. See https://github.com/wordpress-mobile/WordPress-iOS/pull/21028#issuecomment-1624661943
        XCTAssertEqual(LikeUserHelper.likeUsersFor(commentID: commentID, siteID: siteID, after: Date(timeIntervalSinceReferenceDate: 0), in: mainContext).count, 5)
    }
}
