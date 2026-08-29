import Testing
import WordPressAPI
@testable import WordPressComments

struct CommentsServiceStatusMappingTests {
    @Test func updateStatusValues() {
        #expect(CommentsService.updateStatus(for: .approved).description == "approved")
        #expect(CommentsService.updateStatus(for: .pending).description == "hold")
        #expect(CommentsService.updateStatus(for: .spam).description == "spam")
        #expect(CommentsService.updateStatus(for: .trash).description == "trash")
        #expect(CommentsService.updateStatus(for: .other("weird")).description == "weird")
    }

    @Test func restoreStatusValues() {
        #expect(CommentsService.restoreStatus(from: .spam).description == "unspam")
        #expect(CommentsService.restoreStatus(from: .trash).description == "untrash")
    }
}
