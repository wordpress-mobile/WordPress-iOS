import Foundation
import CoreData
import WordPressData
import WordPressShared

@MainActor
final class CommentCreateViewModel {
    var title: String {
        replyToComment == nil ? Strings.comment : Strings.reply
    }

    var placeholder: String {
        replyToComment == nil ? Strings.leaveComment : Strings.leaveReply
    }

    /// Comment you are replying it.
    private(set) var replyToComment: Comment?

    let suggestionsViewModel: SuggestionsListViewModel?

    private let siteID: NSNumber
    private let context = ContextManager.shared.mainContext

    /// - note: It's a temporary solution until the respective save logic
    /// can be moved from the view controllers.
    private var _save: (String) async throws -> Void = { _ in
        wpAssertionFailure("Not implemented")
    }

    var isGutenbergEnabled: Bool {
        FeatureFlag.readerGutenbergCommentComposer.enabled
    }

    /// Create a new top-level comment to the given post.
    init(post: ReaderPost, replyingTo comment: Comment? = nil) {
        self.siteID = post.siteID ?? 0
        self.replyToComment = comment

        wpAssert(siteID != 0, "missing required parameter siteID")

        self.suggestionsViewModel = SuggestionsListViewModel.make(siteID: self.siteID)
        if let comment {
            self.suggestionsViewModel?.enableProminentSuggestions(
                postAuthorID: comment.post?.authorID,
                commentAuthorID: comment.commentID as NSNumber
            )
        } else {
            self.suggestionsViewModel?.enableProminentSuggestions(postAuthorID: post.authorID)
        }

        self._save = { [weak self] in
            try await self?.sendComment($0, post: post, replyingTo: comment)
        }
    }

    /// Create a reply to the given comment (from notifications)
    init(replyingTo comment: Comment, save: @escaping (String) async throws -> Void) {
        let siteID = comment.associatedSiteID ?? 0

        self.siteID = siteID
        self.replyToComment = comment
        self._save = save

        self.suggestionsViewModel = comment.blog.flatMap { SuggestionsListViewModel.make(blog: $0) }
        self.suggestionsViewModel?.enableProminentSuggestions(
            postAuthorID: comment.post?.authorID,
            commentAuthorID: comment.commentID as NSNumber
        )
    }

    static var leaveCommentLocalizedPlaceholder: String {
        Strings.leaveComment
    }

    func save(content: String) async throws {
        try await _save(content)
        deleteDraft()
    }

    // MARK: Reader

    private func sendComment(_ content: String, post: ReaderPost, replyingTo comment: Comment? = nil) async throws {
        try await withUnsafeThrowingContinuation { [weak self] continuation in
            let service = CommentService(coreDataStack: ContextManager.shared)
            if let comment {
                service.replyToHierarchicalComment(withID: comment.commentID as NSNumber, post: post, content: content) {
                    self?.trackReply(isReplyingToComment: true, post: post)
                    continuation.resume()
                } failure: {
                    continuation.resume(throwing: $0 ?? URLError(.unknown))
                }
            } else {
                service.reply(to: post, content: content) {
                    self?.trackReply(isReplyingToComment: true, post: post)
                    continuation.resume()
                } failure: {
                    continuation.resume(throwing: $0 ?? URLError(.unknown))
                }
            }
        }
    }

    private func trackReply(isReplyingToComment: Bool, post: ReaderPost) {
        var properties: [String: Any] = [
            WPAppAnalyticsKeyBlogID: post.siteID ?? 0,
            WPAppAnalyticsKeyPostID: post.postID ?? 0,
            WPAppAnalyticsKeyIsJetpack: post.isJetpack,
            WPAppAnalyticsKeyReplyingTo: isReplyingToComment ? "comment" : "post"
        ]

        if let feedID = post.feedID, let feedItemID = post.feedItemID {
            properties[WPAppAnalyticsKeyFeedID] = feedID
            properties[WPAppAnalyticsKeyFeedItemID] = feedItemID
        }

        WPAnalytics.trackReaderStat(.readerArticleCommentedOn, properties: properties)
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
