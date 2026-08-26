import Testing
import WordPressAPI
@testable import WordPressComments

struct CommentsListFilterTests {
    // The serialized query value is what goes on the wire as `status=...`.
    // WP_Comment_Query only recognizes the literal values `approve` and `all`;
    // `approved` (the response spelling) silently returns an empty set.
    @Test func queryStatusSerializesToWireValues() {
        #expect(CommentsListFilter.all.queryStatus.description == "all")
        #expect(CommentsListFilter.pending.queryStatus.description == "hold")
        #expect(CommentsListFilter.approved.queryStatus.description == "approve")
        #expect(CommentsListFilter.spam.queryStatus.description == "spam")
        #expect(CommentsListFilter.trash.queryStatus.description == "trash")
    }

    @Test func tabOrderMatchesDesign() {
        #expect(
            CommentsListFilter.allCases == [.all, .pending, .approved, .spam, .trash]
        )
    }
}
