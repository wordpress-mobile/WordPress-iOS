import Testing
import Foundation
import WordPressKit
@testable import JetpackStats

@Suite
struct PostLikeSeedTests {
    @Test func mapsAllFieldsFromRemoteLikeUser() {
        let dictionary: [String: Any] = [
            "ID": 101,
            "login": "testlogin",
            "name": "Test Name",
            "site_ID": 20,
            "avatar_URL": "https://example.com/avatar.jpg",
            "date_liked": "2026-01-24T04:02:42+0000"
        ]
        let remoteUser = RemoteLikeUser(dictionary: dictionary, postID: 55, siteID: 20)

        let seed = PostLikeSeed(remoteUser: remoteUser)

        #expect(seed.userID == 101)
        #expect(seed.displayName == "Test Name")
        #expect(seed.username == "testlogin")
        #expect(seed.avatarURL == "https://example.com/avatar.jpg")
        #expect(seed.dateLikedString == "2026-01-24T04:02:42+0000")
    }

    @Test func fallsBackToUsernameWhenDisplayNameMissing() {
        let dictionary: [String: Any] = [
            "ID": 101,
            "login": "testlogin"
        ]
        let remoteUser = RemoteLikeUser(dictionary: dictionary, postID: 55, siteID: 20)

        let seed = PostLikeSeed(remoteUser: remoteUser)

        #expect(seed.displayName == "testlogin")
        #expect(seed.avatarURL == nil)
        #expect(seed.dateLikedString == nil)
    }
}
