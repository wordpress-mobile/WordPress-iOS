import SwiftUI
import WordPressData
import WordPressShared

extension BasePost.Status: @retroactive Identifiable {
    public var id: Self { self }

    var title: String {
        switch self {
        case .draft: NSLocalizedString("postStatus.draft.title", value: "Draft", comment: "Post status title")
        case .pending: NSLocalizedString("postStatus.pending.title", value: "Pending", comment: "Post status title")
        case .publishPrivate: NSLocalizedString("postStatus.private.title", value: "Private", comment: "Post status title")
        case .scheduled: NSLocalizedString("postStatus.scheduled.title", value: "Scheduled", comment: "Post status title")
        case .publish: NSLocalizedString("postStatus.published.title", value: "Published", comment: "Post status title")
        case .trash: NSLocalizedString("postStatus.trash.title", value: "Trashed", comment: "Post status title")
        case .deleted: NSLocalizedString("postStatus.deleted.title", value: "Deleted", comment: "Post status title")
        }
    }

    var details: String {
        switch self {
        case .draft: NSLocalizedString("postStatus.draft.details", value: "Not ready to publish", comment: "Post status details")
        case .pending: NSLocalizedString("postStatus.pending.details", value: "Waiting for review before publishing", comment: "Post status details")
        case .publishPrivate: NSLocalizedString("postStatus.private.details", value: "Only visible to site admins and editors", comment: "Post status details")
        case .scheduled: NSLocalizedString("postStatus.scheduled.details", value: "Publish automatically on a chosen date", comment: "Post status details")
        case .publish: NSLocalizedString("postStatus.published.details", value: "Visible to everyone", comment: "Post status details")
        case .trash: NSLocalizedString("postStatus.trash.details", value: "Trashed but not deleted yet", comment: "Post status title")
        case .deleted: NSLocalizedString("postStatus.deleted.details", value: "Permanently deleted", comment: "Post status title")
        }
    }

    var image: String {
        switch self {
        case .draft: "post-status-draft"
        case .pending: "post-status-pending"
        case .publishPrivate: "post-status-private"
        case .scheduled: "post-status-scheduled"
        case .publish: "post-status-published"
        case .trash, .deleted: "" // We don't show these anywhere in the UI
        }
    }
}
