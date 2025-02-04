import Foundation
import CoreData

final class CommentComposerViewModel {
    let suggestionsViewModel: SuggestionsListViewModel?

    private let parameters: CommentComposerParameters
    private var context: NSManagedObjectContext

    /// Send a top-level comment to the given post.
    convenience init(post: ReaderPost) {
        self.init(parameters: .init(
            siteID: post.siteID,
            context: .post(post)
        ))
        self.suggestionsViewModel?.enableProminentSuggestions(postAuthorID: post.authorID)
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
        self.init(parameters: .init(
            siteID: siteID,
            context: .comment(.init(commentID: comment.commentID as NSNumber))
        ))
        self.suggestionsViewModel?.enableProminentSuggestions(
            postAuthorID: comment.post?.authorID,
            commentAuthorID: comment.commentID as NSNumber
        )
    }

    /// Reply to the comment from the given notification.
    convenience init?(notification: Notification) {
        guard let siteID = notification.metaSiteID,
              let commentID = notification.metaCommentID else {
            return nil
        }
        self.init(parameters: .init(
            siteID: siteID,
            context: .comment(.init(commentID: commentID))
        ))
        self.suggestionsViewModel?.enableProminentSuggestions(postAuthorID: nil, commentAuthorID: notification.metaCommentAuthorID)
    }

    init(
        parameters: CommentComposerParameters,
        context: NSManagedObjectContext = ContextManager.shared.mainContext
    ) {
        self.parameters = parameters
        self.context = context
        self.suggestionsViewModel = SuggestionsListViewModel.make(siteID: parameters.siteID)
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

    // MARK: Actions

    @MainActor
    func send(comment: String) async throws {
        let service = CommentService(coreDataStack: ContextManager.shared)
        try await service.createComment(content: comment, target: parameters.target, siteID: parameters.siteID)
        trackCommentSent()
    }

    // MARK: Analytics

    private func trackCommentSent() {
        var properties: [AnyHashable: Any] = [:]
        switch parameters.context {
        case .post(let post):
            properties[WPAppAnalyticsKeyReplyingTo] = "post"
            if let siteID = post.siteID {
                properties[WPAppAnalyticsKeyBlogID] = siteID
            }
            if let postID = post.postID {
                properties[WPAppAnalyticsKeyPostID] = postID
            }
            if let feedID = post.feedID, let feedItemID = post.feedItemID {
                properties[WPAppAnalyticsKeyFeedID] = feedID
                properties[WPAppAnalyticsKeyFeedItemID] = feedItemID
            }
            properties[WPAppAnalyticsKeyIsJetpack] = NSNumber(value: post.isJetpack)
        case .comment:
            properties[WPAppAnalyticsKeyReplyingTo] = "comment"
        }
        WPAnalytics.trackReaderStat(.readerArticleCommentedOn, properties: properties)
    }
}

struct CommentComposerParameters {
    var siteID: NSNumber
    var context: Context

    enum Context {
        /// Send a top-level comment to the given post.
        case post(ReaderPost)

        /// Send a reply to the given comment.
        case comment(CommentDetails)
    }

    struct CommentDetails {
        var commentID: NSNumber
    }

    var target: CommentService.CommentTarget {
        switch context {
        case .post(let post): return .postID(post.postID ?? 0)
        case .comment(let comment): return .commentID(comment.commentID)
        }
    }
}

private enum Strings {
    static let reply = NSLocalizedString("commentComposer.navigationTitleReply", value: "Reply", comment: "Navigation bar title when leaving a reply to a comment")
    static let comment = NSLocalizedString("commentComposer.navigationTitleComment", value: "Comment", comment: "Navigation bar title when leaving a reply to a comment")
    static let leaveReply = NSLocalizedString("commentComposer.placeholderLeaveReply", value: "Leave a reply…", comment: "Navigation bar title when leaving a reply to a comment")
    static let leaveComment = NSLocalizedString("commentComposer.placeholderLeaveComment", value: "Leave a comment…", comment: "Navigation bar title when leaving a reply to a comment")
}
