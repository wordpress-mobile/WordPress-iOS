import Foundation
import CoreData

final class CommentComposerViewModel {
    let suggestionsViewModel: SuggestionsListViewModel?

    var save: (String) async throws -> Void = { _ in
        wpAssertionFailure("must be specified")
    }

    /// Comment you are replying it.
    var comment: Comment?

    private let parameters: CommentComposerParameters
    private var context: NSManagedObjectContext

    var isGutenbergEnabled: Bool {
        FeatureFlag.readerGutenbergCommentComposer.enabled
    }

    /// Send a top-level comment to the given post.
    convenience init(post: ReaderPost) {
        let parameters = CommentComposerParameters(siteID: post.siteID, context: .post)

        let suggestionsViewModel = SuggestionsListViewModel.make(siteID: post.siteID)
        suggestionsViewModel?.enableProminentSuggestions(postAuthorID: post.authorID)

        self.init(parameters: parameters, suggestionsViewModel: suggestionsViewModel)
    }

    /// Reply to the given comment.
    convenience init?(comment: Comment) {
        let siteID: NSNumber
        if let post = comment.post as? ReaderPost {
            siteID = post.siteID
        } else if let blogID = comment.blog?.dotComID {
            siteID = blogID
        } else {
            return nil
        }

        let parameters = CommentComposerParameters(siteID: siteID, context: .comment)

        let suggestionsViewModel = SuggestionsListViewModel.make(siteID: siteID)
        suggestionsViewModel?.enableProminentSuggestions(
            postAuthorID: comment.post?.authorID,
            commentAuthorID: comment.commentID as NSNumber
        )

        self.init(parameters: parameters, suggestionsViewModel: suggestionsViewModel)
        self.comment = comment
    }

    init(
        parameters: CommentComposerParameters,
        suggestionsViewModel: SuggestionsListViewModel?,
        context: NSManagedObjectContext = ContextManager.shared.mainContext
    ) {
        self.parameters = parameters
        self.suggestionsViewModel = suggestionsViewModel
        self.context = context
    }

    var navigationTitle: String {
        switch parameters.context {
        case .post: return Strings.comment
        case .comment: return Strings.reply
        }
    }

    var placeholder: String {
        switch parameters.context {
        case .post: return Strings.leaveComment
        case .comment: return Strings.leaveReply
        }
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
        return "CommentDraft-\(userID),\(parameters.siteID),\(comment?.commentID ?? 0)"
    }
}

struct CommentComposerParameters {
    var siteID: NSNumber
    var context: Context

    enum Context {
        /// Send a top-level comment to the given post.
        case post

        /// Send a reply to the given comment.
        case comment
    }
}

private struct CommentID {
    let userID: NSNumber
    let siteID: NSNumber
    let commentID: NSNumber?
}

private enum Strings {
    static let reply = NSLocalizedString("commentComposer.navigationTitleReply", value: "Reply", comment: "Navigation bar title when leaving a reply to a comment")
    static let comment = NSLocalizedString("commentComposer.navigationTitleComment", value: "Comment", comment: "Navigation bar title when leaving a reply to a comment")
    static let leaveReply = NSLocalizedString("commentComposer.placeholderLeaveReply", value: "Leave a reply…", comment: "Navigation bar title when leaving a reply to a comment")
    static let leaveComment = NSLocalizedString("commentComposer.placeholderLeaveComment", value: "Leave a comment…", comment: "Navigation bar title when leaving a reply to a comment")
}
