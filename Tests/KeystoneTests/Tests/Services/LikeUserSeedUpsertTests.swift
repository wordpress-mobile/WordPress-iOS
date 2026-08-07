@testable import WordPress
import WordPressData
import WordPressKit
import XCTest

class LikeUserSeedUpsertTests: CoreDataTestCase {

    private let siteID: Int64 = 20
    private let postID: Int64 = 55

    private func makeSeed(userID: Int64, displayName: String = "Seed Name") -> LikeUserSeed {
        LikeUserSeed(
            userID: userID,
            displayName: displayName,
            username: "seedlogin",
            avatarUrl: "https://example.com/avatar.jpg",
            dateLikedString: "2026-01-24T04:02:42+0000"
        )
    }

    // Creates a full-fidelity cached row (bio + preferred blog) via the existing write path.
    private func insertExistingLikeUser(userID: Int64) -> LikeUser {
        let dictionary: [String: Any] = [
            "ID": Int(userID),
            "login": "existinglogin",
            "name": "Existing Name",
            "site_ID": Int(siteID),
            "avatar_URL": "https://example.com/old-avatar.jpg",
            "bio": "existing bio",
            "date_liked": "2025-11-24T04:02:42+0000",
            "preferred_blog": [
                "id": 1,
                "url": "https://example.com",
                "name": "Existing Blog",
                "icon": ["img": "someimage.jpg"]
            ] as [String: Any]
        ]
        let remoteUser = RemoteLikeUser(
            dictionary: dictionary,
            postID: NSNumber(value: postID),
            siteID: NSNumber(value: siteID)
        )
        return LikeUserHelper.createOrUpdateFrom(remoteUser: remoteUser, context: mainContext)
    }

    private func fetchAllLikeUsers() -> [LikeUser] {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>
        return (try? mainContext.fetch(request)) ?? []
    }

    func testUpsertInsertsNewRows() throws {
        LikeUserHelper.upsert(
            seeds: [makeSeed(userID: 1), makeSeed(userID: 2)],
            siteID: siteID,
            postID: postID,
            in: mainContext
        )
        try mainContext.save()

        let users = fetchAllLikeUsers()
        XCTAssertEqual(users.count, 2)
        let user = try XCTUnwrap(users.first { $0.userID == 1 })
        XCTAssertEqual(user.displayName, "Seed Name")
        XCTAssertEqual(user.username, "seedlogin")
        XCTAssertEqual(user.avatarUrl, "https://example.com/avatar.jpg")
        XCTAssertEqual(user.dateLikedString, "2026-01-24T04:02:42+0000")
        XCTAssertNotNil(user.dateLiked)
        XCTAssertNotNil(user.dateFetched)
        XCTAssertEqual(user.likedSiteID, siteID)
        XCTAssertEqual(user.likedPostID, postID)
        XCTAssertEqual(user.likedCommentID, 0)
    }

    func testUpsertUpdatesExistingRowPreservingRicherFields() throws {
        let existing = insertExistingLikeUser(userID: 1)
        try mainContext.save()

        LikeUserHelper.upsert(
            seeds: [makeSeed(userID: 1, displayName: "Updated Name")],
            siteID: siteID,
            postID: postID,
            in: mainContext
        )
        try mainContext.save()

        XCTAssertEqual(fetchAllLikeUsers().count, 1)
        XCTAssertEqual(existing.displayName, "Updated Name")
        XCTAssertEqual(existing.username, "seedlogin")
        // Fields the seed does not carry keep their richer cached values.
        XCTAssertEqual(existing.bio, "existing bio")
        XCTAssertNotNil(existing.preferredBlog)
    }

    func testUpsertDoesNotTouchOtherRows() throws {
        let otherPostUser = insertExistingLikeUser(userID: 9)
        otherPostUser.likedPostID = postID + 1
        try mainContext.save()

        LikeUserHelper.upsert(
            seeds: [makeSeed(userID: 1)],
            siteID: siteID,
            postID: postID,
            in: mainContext
        )
        try mainContext.save()

        // The row for the other post is neither deleted nor modified.
        XCTAssertEqual(fetchAllLikeUsers().count, 2)
        XCTAssertEqual(otherPostUser.displayName, "Existing Name")
    }

    func testDeleteLikesRemovesOnlyThePostsRows() throws {
        _ = insertExistingLikeUser(userID: 1)
        let otherPost = insertExistingLikeUser(userID: 2)
        otherPost.likedPostID = postID + 1
        try mainContext.save()
        XCTAssertEqual(fetchAllLikeUsers().count, 2)

        LikeUserHelper.deleteLikes(forPost: postID, siteID: siteID, in: mainContext)
        try mainContext.save()

        // Only the target post's rows are removed; the other post survives.
        let remaining = fetchAllLikeUsers()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.userID, 2)
        XCTAssertEqual(remaining.first?.likedPostID, postID + 1)
    }
}
