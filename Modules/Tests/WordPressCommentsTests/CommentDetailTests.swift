import Testing
import WordPressAPI
@testable import WordPressComments

struct CommentDetailTests {
    @Test func viewContextHasNoEditFields() {
        let detail = CommentDetail(comment: .detailBuilder(id: 5, parent: 0, status: .approved))
        #expect(!detail.hasEditContext)
        #expect(detail.authorEmail == nil)
        #expect(detail.authorIP == nil)
        #expect(detail.parentID == nil)
    }

    @Test func editContextNormalizesEmptyStringsToNil() {
        let detail = CommentDetail(comment: .editDetailBuilder(id: 5, email: "", ip: "203.0.113.9"))
        #expect(detail.hasEditContext)
        #expect(detail.authorEmail == nil)
        #expect(detail.authorIP == "203.0.113.9")
    }

    @Test func parentAndCustomStatusMapping() {
        let detail = CommentDetail(comment: .detailBuilder(id: 6, parent: 3, status: .custom("post-trashed")))
        #expect(detail.parentID == 3)
        #expect(detail.status == .other("post-trashed"))
    }

    @Test func emptyAuthorNameFallsBackToAnonymous() {
        let detail = CommentDetail(comment: .detailBuilder(authorName: ""))
        #expect(detail.authorName == Strings.anonymousAuthor)
    }
}
