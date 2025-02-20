import Foundation
import CoreData

final class CommentCreateViewModel {
    var title: String {
        replyToComment == nil ? Strings.comment : Strings.reply
    }

    var placeholder: String {
        replyToComment == nil ? Strings.leaveComment : Strings.leaveReply
    }

    /// Comment you are replying it.
    private(set) var replyToComment: Comment?

    /// - note: It's a temporary solution until the respective save logic
    /// can be moved from the view controllers.
    var save: (String) async throws -> Void = { _ in
        wpAssertionFailure("must be specified")
    }

    let suggestionsViewModel: SuggestionsListViewModel?

    private let siteID: NSNumber
    private let context = ContextManager.shared.mainContext

    var isGutenbergEnabled: Bool {
        FeatureFlag.readerGutenbergCommentComposer.enabled
    }

    /// Create a new top-level comment to the given post.
    init(post: ReaderPost) {
        self.siteID = post.siteID ?? 0
        wpAssert(siteID != 0, "missing required parameter siteID")

        self.suggestionsViewModel = SuggestionsListViewModel.make(siteID: post.siteID)
        self.suggestionsViewModel?.enableProminentSuggestions(postAuthorID: post.authorID)
    }

    /// Create a reply to the given comment.
    init(replyingTo comment: Comment) {
        let siteID = comment.associatedSiteID ?? 0
        wpAssert(siteID != 0, "missing required parameter siteID")

        self.siteID = siteID
        self.replyToComment = comment

        self.suggestionsViewModel = SuggestionsListViewModel.make(siteID: siteID)
        self.suggestionsViewModel?.enableProminentSuggestions(
            postAuthorID: comment.post?.authorID,
            commentAuthorID: comment.commentID as NSNumber
        )
    }

    static var leaveCommentLocalizedPlaceholder: String {
        Strings.leaveComment
    }

    // MARK: Drafts

    func restoreDraft() -> String? {
         guard let key = makeDraftKey() else { return nil }
         return UserDefaults.standard.string(forKey: key)
     }

    var canSaveDraft: Bool {
        makeDraftKey() != nil
    }

    func saveDraft(_ content: String) {
        guard let key = makeDraftKey() else { return }
        return UserDefaults.standard.set(content, forKey: key)
    }

    func deleteDraft() {
        guard let key = makeDraftKey() else { return }
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func makeDraftKey() -> String? {
        guard let userID = (try? WPAccount.lookupDefaultWordPressComAccount(in: context))?.userID else {
            return nil
        }
        return "CommentDraft-\(userID),\(siteID),\(replyToComment?.commentID ?? 0)"
    }
}

private enum Strings {
    static let reply = NSLocalizedString("commentCreate.navigationTitleReply", value: "Reply", comment: "Navigation bar title when leaving a reply to a comment")
    static let comment = NSLocalizedString("commentCreate.navigationTitleComment", value: "Comment", comment: "Navigation bar title when leaving a reply to a comment")
    static let leaveReply = NSLocalizedString("commentCreate.placeholderLeaveReply", value: "Leave a reply…", comment: "Navigation bar title when leaving a reply to a comment")
    static let leaveComment = NSLocalizedString("commentCreate.placeholderLeaveComment", value: "Leave a comment…", comment: "Navigation bar title when leaving a reply to a comment")
}
