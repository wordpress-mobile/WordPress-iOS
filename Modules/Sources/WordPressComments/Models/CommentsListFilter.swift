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
    /// `.custom` is used where wordpress-rs's `CommentStatus` cannot express the
    /// query vocabulary: `WP_Comment_Query` only recognizes the literal values
    /// `approve` and `all`, while the enum models the response spelling
    /// (`approved`) and has no `all` case. `all` means pending + approved;
    /// spam and trash are excluded by core, matching wp-admin's All tab.
    /// Same workaround as Android (`CommentsRsListTab.kt`).
    /// TODO: Replace both `.custom` values with typed cases once wordpress-rs
    /// separates query values from response values (tracked outside this app).
    var queryStatus: CommentStatus {
        switch self {
        case .all: .custom("all")
        case .pending: .hold
        case .approved: .custom("approve")
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
}
