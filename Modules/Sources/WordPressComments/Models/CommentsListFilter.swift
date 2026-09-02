import Foundation
import WordPressAPI
import WordPressUI

enum CommentsListFilter: Int, CaseIterable, AdaptiveTabBarItem, Sendable {
    case all
    case pending
    case approved
    case spam
    case trash

    var id: Self { self }

    var localizedTitle: String {
        switch self {
        case .all: Strings.tabAll
        case .pending: Strings.tabPending
        case .approved: Strings.tabApproved
        case .spam: Strings.tabSpam
        case .trash: Strings.tabTrash
        }
    }

    /// The `status` query param for `/wp/v2/comments`.
    ///
    /// `all` means pending + approved; spam and trash are excluded by core,
    /// matching wp-admin's All tab.
    var queryStatus: WpApiParamCommentsStatus {
        switch self {
        case .all: .all
        case .pending: .hold
        case .approved: .approve
        case .spam: .spam
        case .trash: .trash
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .all: Strings.emptyAll
        case .pending: Strings.emptyPending
        case .approved: Strings.emptyApproved
        case .spam: Strings.emptySpam
        case .trash: Strings.emptyTrash
        }
    }

    /// Whether a comment with this status belongs in this tab's result set.
    /// Mirrors core's query semantics: `all` is pending + approved only
    /// (comment_approved IN ('0','1')); custom statuses match no tab.
    func matches(_ status: CommentListItem.Status) -> Bool {
        switch self {
        case .all: status == .pending || status == .approved
        case .pending: status == .pending
        case .approved: status == .approved
        case .spam: status == .spam
        case .trash: status == .trash
        }
    }
}
