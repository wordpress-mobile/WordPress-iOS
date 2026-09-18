@testable import WordPressComments

/// In-memory draft store recording every save/delete call, so composer VM
/// tests can assert on draft lifecycle without touching `UserDefaults`.
@MainActor
final class FakeCommentDraftStore: CommentDraftStoring {
    private var drafts: [Int64: String] = [:]
    private(set) var saved: [Int64: String] = [:]
    private(set) var deleted: [Int64] = []

    func preloadDraft(_ text: String, commentID: Int64) {
        drafts[commentID] = text
    }

    func loadDraft(commentID: Int64) -> String? {
        drafts[commentID]
    }

    func saveDraft(_ text: String, commentID: Int64) {
        saved[commentID] = text
        drafts[commentID] = text
    }

    func deleteDraft(commentID: Int64) {
        deleted.append(commentID)
        drafts[commentID] = nil
    }
}
