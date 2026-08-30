import Foundation
import Testing
import WordPressAPI
@testable import WordPressComments

struct CommentListItemTests {
    @Test func mapsBasicFields() {
        let item = CommentListItem(comment: makeComment(id: 7, authorName: "Priya", post: 42, status: .hold))
        #expect(item.id == 7)
        #expect(item.authorName == "Priya")
        #expect(item.postID == 42)
        #expect(item.status == .pending)
        #expect(item.avatarURL == URL(string: "https://example.com/avatar.png"))
    }

    @Test func stripsHTMLIntoSingleLineSnippet() {
        let item = CommentListItem(
            comment: makeComment(content: "<p>Line one</p>\n<p>Line &amp; two</p>")
        )
        #expect(item.snippet == "Line one Line & two")
    }

    @Test func emptyAuthorNameFallsBackToAnonymous() {
        let item = CommentListItem(comment: makeComment(authorName: ""))
        #expect(!item.authorName.isEmpty)
    }

    @Test func missingAvatarMapsToNil() {
        let item = CommentListItem(comment: makeComment(avatar: nil))
        #expect(item.avatarURL == nil)
    }

    @Test func statusMapping() {
        #expect(CommentListItem(comment: makeComment(status: .approved)).status == .approved)
        #expect(CommentListItem(comment: makeComment(status: .spam)).status == .spam)
        #expect(CommentListItem(comment: makeComment(status: .trash)).status == .trash)
        #expect(CommentListItem(comment: makeComment(status: .custom("weird"))).status == .other)
    }
}
