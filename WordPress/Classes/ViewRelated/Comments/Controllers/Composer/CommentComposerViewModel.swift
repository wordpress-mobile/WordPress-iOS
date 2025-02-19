import Foundation
import CoreData

final class CommentComposerViewModel {
    var navigationTitle: String? {
        switch parameters.context {
        case .create: return Strings.comment
        case .reply: return Strings.reply
        case .edit: return Strings.edit
        }
    }

    var buttonSaveTitle: String {
        switch parameters.context {
        case .create, .reply: return Strings.send
        case .edit: return SharedStrings.Button.save
        }
    }

    var placeholder: String {
        switch parameters.context {
        case .create, .edit: return Strings.leaveComment
        case .reply: return Strings.leaveReply
        }
    }

    /// Comment you are replying it.
    var replyToComment: Comment? {
        guard case .reply(let comment) = parameters.context else { return nil }
        return comment
    }

    /// - note: It's a temporary solution until the respective save logic
    /// can be moved from the view controllers.
    var save: (String) async throws -> Void = { _ in
        wpAssertionFailure("must be specified")
    }

    let suggestionsViewModel: SuggestionsListViewModel?

    private let parameters: CommentComposerParameters
    private var context: NSManagedObjectContext

    var isGutenbergEnabled: Bool {
        FeatureFlag.readerGutenbergCommentComposer.enabled
    }

    /// Create a new top-level comment to the given post.
    static func create(post: ReaderPost) -> CommentComposerViewModel {
        let parameters = CommentComposerParameters(siteID: post.siteID, context: .create)

        let suggestionsViewModel = SuggestionsListViewModel.make(siteID: post.siteID)
        suggestionsViewModel?.enableProminentSuggestions(postAuthorID: post.authorID)

        return CommentComposerViewModel(parameters: parameters, suggestionsViewModel: suggestionsViewModel)
    }

    /// Create a reply to the given comment.
    static func create(replyingTo comment: Comment) -> CommentComposerViewModel {
        let siteID = getSiteID(for: comment)
        let parameters = CommentComposerParameters(siteID: siteID, context: .reply(comment))
        let suggestionsViewModel = makeSuggestionsViewModel(for: comment)

        return CommentComposerViewModel(parameters: parameters, suggestionsViewModel: suggestionsViewModel)
    }

    /// Edit an existing comment.
    static func edit(comment: Comment) -> CommentComposerViewModel {
        let siteID = getSiteID(for: comment)
        let parameters = CommentComposerParameters(siteID: siteID, context: .edit(comment))
        let suggestionsViewModel = makeSuggestionsViewModel(for: comment)

        let viewModel = CommentComposerViewModel(parameters: parameters, suggestionsViewModel: suggestionsViewModel)
        viewModel.save = {
            try await CommentComposerViewModel.save(content: $0, comment: comment)
        }
        return viewModel
    }

    private init(
        parameters: CommentComposerParameters,
        suggestionsViewModel: SuggestionsListViewModel?,
        context: NSManagedObjectContext = ContextManager.shared.mainContext
    ) {
        self.parameters = parameters
        self.suggestionsViewModel = suggestionsViewModel
        self.context = context
    }

    static var leaveCommentLocalizedPlaceholder: String {
        Strings.leaveComment
    }

    // MARK: Drafts

    // TODO: delete draft after sending a comment
    func getInitialContent() -> String {
        switch parameters.context {
        case .create, .reply:
            return restoreDraft() ?? ""
        case .edit(let comment):
            return comment.rawContent
        }
    }

    private func restoreDraft() -> String? {
        guard let key = makeDraftKey() else { return nil }
        return UserDefaults.standard.string(forKey: key)
    }

    var canSaveDraft: Bool {
        if case .edit = parameters.context {
            return false
        }
        return makeDraftKey() != nil
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
        return "CommentDraft-\(userID),\(parameters.siteID),\(replyToComment?.commentID ?? 0)"
    }

    // MARK: Helpers

    private static func getSiteID(for comment: Comment) -> NSNumber {
        if let post = comment.post as? ReaderPost {
            return post.siteID
        } else if let blogID = comment.blog?.dotComID {
            return blogID
        } else {
            wpAssertionFailure("missing siteID")
            return -1 // Should not happen
        }
    }

    private static func makeSuggestionsViewModel(for comment: Comment) -> SuggestionsListViewModel? {
        let siteID = Self.getSiteID(for: comment)
        let viewModel = SuggestionsListViewModel.make(siteID: siteID)
        viewModel?.enableProminentSuggestions(
            postAuthorID: comment.post?.authorID,
            commentAuthorID: comment.commentID as NSNumber
        )
        return viewModel
    }

    @MainActor
    private static func save(content: String, comment: Comment) async throws {
        let commentID = comment.commentID as NSNumber
        let siteID = getSiteID(for: comment)

        try await withUnsafeThrowingContinuation { continuation in
            let service = CommentService(coreDataStack: ContextManager.shared)
            service.updateComment(withID: commentID, siteID: siteID, content: content, success: {
                continuation.resume(returning: ())
            }, failure: { error in
                continuation.resume(throwing: error ?? URLError(.unknown))
            })
        }

        let objectID = TaggedManagedObjectID(comment)
        try await ContextManager.shared.performAndSave { context in
            let comment = try context.existingObject(with: objectID)
            comment.content = content
        }

        CommentAnalytics.trackCommentEdited(comment: comment)
    }
}

private struct CommentComposerParameters {
    var siteID: NSNumber
    var context: Context

    enum Context {
        /// Create a top-level comment to the given post.
        case create

        /// Create a reply to the given comment.
        case reply(Comment)

        /// Edit an existing comment/
        case edit(Comment)
    }
}

private enum Strings {
    static let send = NSLocalizedString("commentComposer.send", value: "Send", comment: "Navigation bar button title")
    static let reply = NSLocalizedString("commentComposer.navigationTitleReply", value: "Reply", comment: "Navigation bar title when leaving a reply to a comment")
    static let comment = NSLocalizedString("commentComposer.navigationTitleComment", value: "Comment", comment: "Navigation bar title when leaving a reply to a comment")
    static let edit = NSLocalizedString("commentComposer.navigationTitleEdit", value: "Edit Comment", comment: "Navigation bar title when leaving a editing an existing comment")
    static let leaveReply = NSLocalizedString("commentComposer.placeholderLeaveReply", value: "Leave a reply…", comment: "Navigation bar title when leaving a reply to a comment")
    static let leaveComment = NSLocalizedString("commentComposer.placeholderLeaveComment", value: "Leave a comment…", comment: "Navigation bar title when leaving a reply to a comment")
}
