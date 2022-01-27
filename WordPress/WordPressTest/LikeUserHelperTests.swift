@testable import WordPress
import XCTest

class LikeUserHelperTests: XCTestCase {

    func createTestRemoteUserDictionary(withPreferredBlog hasPreferredBlog: Bool) -> [String: Any] {
        var remoteUserDictionary: [String: Any] = [
            "ID": 15,
            "login": "testlogin",
            "name": "testname",
            "site_ID": 20,
            "avatar_URL": "wordpress.org/test2",
            "bio": "testbio",
            "date_liked": "2021-11-24T04:02:42+0000",
        ]

        if hasPreferredBlog {
            remoteUserDictionary["preferred_blog"] = [
                "id": 1,
                "url": "wordpress.org/test1",
                "name": "testblog",
                "icon": [
                    "img": "someimage.jpg",
                ]
            ]
        }

        return remoteUserDictionary
    }

    func testNewLikeUserWithPreferredBlog() {
        let completionExpectation = expectation(description: "We expect the context to save successfully")
        let contextManager = TestContextManager()
        let context = contextManager.mainContext

        let remoteUserDictionary = createTestRemoteUserDictionary(withPreferredBlog: true)
        let remoteUser = RemoteLikeUser(dictionary: remoteUserDictionary, commentID: 25, siteID: 30)
        let likeUser = LikeUserHelper.createOrUpdateFrom(remoteUser: remoteUser, context: context)
        XCTAssertNotNil(likeUser)

        // TODO: The save crashes when it fails, interrupting all other tests.
        contextManager.save(context, withCompletionBlock: {
            completionExpectation.fulfill()
        })

        waitForExpectations(timeout: 5)
    }

    func testUpdatingExistingUserToRemovePreferredBlog() {
        let completionExpectation = expectation(description: "We expect the context to save successfully")
        let contextManager = TestContextManager()
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
        contextManager.save(context, withCompletionBlock: {
            completionExpectation.fulfill()
        })

        waitForExpectations(timeout: 5)
    }
}
