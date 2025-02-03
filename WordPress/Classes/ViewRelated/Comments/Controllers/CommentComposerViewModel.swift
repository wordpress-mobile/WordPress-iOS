import Foundation
import CoreData

final class CommentComposerViewModel {
    let parameters: CommentComposerParameters
    var suggestionsService: SuggestionService
    var context: NSManagedObjectContext

    init(
        parameters: CommentComposerParameters,
        suggestionsService: SuggestionService = SuggestionService.shared,
        context: NSManagedObjectContext = ContextManager.shared.mainContext
    ) {
        self.parameters = parameters
        self.suggestionsService = suggestionsService
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

    // MARK: Suggestions

    func suggestionsTableView(with siteID: NSNumber, useTransparentHeader: Bool, prominentSuggestionsIds: [NSNumber]?, delegate: SuggestionsTableViewDelegate) -> SuggestionsTableView {
        let suggestionListViewModel = SuggestionsListViewModel(siteID: siteID, context: context)
        suggestionListViewModel.userSuggestionService = suggestionsService
        suggestionListViewModel.suggestionType = .mention
        let tableView = SuggestionsTableView(viewModel: suggestionListViewModel, delegate: delegate)
        tableView.useTransparentHeader = useTransparentHeader
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.prominentSuggestionsIds = prominentSuggestionsIds
        return tableView
    }

    func shouldShowSuggestions(with siteID: NSNumber?) -> Bool {
        guard let siteID, let blog = Blog.lookup(withID: siteID, in: context) else {
            return false
        }
        return suggestionsService.shouldShowSuggestions(for: blog)
    }

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
        // TODO: check if this is always the correct event
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

extension CommentComposerParameters {
    /// Send a top-level comment to the given post.
    init(post: ReaderPost) {
        self.siteID = post.siteID
        self.context = .post(post)
    }

    /// Reply to the given comment.
    init?(comment: Comment) {
        if let post = comment.post as? ReaderPost {
            self.siteID = post.siteID
        } else if let siteID = comment.blog?.dotComID {
            self.siteID = siteID
        } else {
            return nil
        }
        self.context = .comment(.init(commentID: comment.commentID as NSNumber))
    }

    /// Reply to the comment from the given notification.
    init?(notification: Notification) {
        guard let siteID = notification.metaSiteID,
              let commentID = notification.metaCommentID else {
            return nil
        }
        self.siteID = siteID
        self.context = .comment(.init(commentID: commentID))
    }
}

private enum Strings {
    static let reply = NSLocalizedString("commentComposer.navigationTitleReply", value: "Reply", comment: "Navigation bar title when leaving a reply to a comment")
    static let comment = NSLocalizedString("commentComposer.navigationTitleComment", value: "Comment", comment: "Navigation bar title when leaving a reply to a comment")
    static let leaveReply = NSLocalizedString("commentComposer.placeholderLeaveReply", value: "Leave a reply…", comment: "Navigation bar title when leaving a reply to a comment")
    static let leaveComment = NSLocalizedString("commentComposer.placeholderLeaveComment", value: "Leave a comment…", comment: "Navigation bar title when leaving a reply to a comment")
}
