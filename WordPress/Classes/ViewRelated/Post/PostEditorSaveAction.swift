import Foundation
import WordPressComAnalytics

/// Encapsulates the current save action of the editor, based on its
/// post status, whether it's already been saved, is scheduled, etc.
@objc enum PostEditorSaveAction: Int {
    case Schedule
    case Post
    case Save
    case Update
}

/// Some utility methods to help keep track of the current post action
extension WPPostViewController {
    /// What action should be taken when the user taps the editor's save button?
    var currentSaveAction: PostEditorSaveAction {
        if let post = post,
            let status = post.status,
            let originalStatus = post.original?.status
            where status != originalStatus || !post.hasRemote() {
            if (post.isScheduled()) {
                return .Schedule
            } else if (status == PostStatusPublish) {
                return .Post
            } else {
                return .Save
            }
        } else {
            return .Update
        }
    }

    /// The title for the Save button, based on the current save action
    var saveBarButtonItemTitle: String {
        switch currentSaveAction {
        case .Schedule:
            return NSLocalizedString("Schedule", comment: "Schedule button, this is what the Publish button changes to in the Post Editor if the post has been scheduled for posting later.")
        case .Post:
            return NSLocalizedString("Post", comment: "Publish button label.")
        case .Save:
            return NSLocalizedString("Save", comment: "Save button label (saving content, ex: Post, Page, Comment).")
        case .Update:
            return NSLocalizedString("Update", comment: "Update button label (saving content, ex: Post, Page, Comment).")
        }
    }

    /// The analytics stat to post when the user saves, based on the current post action
    func analyticsStatForSaveAction(action: PostEditorSaveAction) -> WPAnalyticsStat {
        switch action {
        case .Post:     return .EditorPublishedPost
        case .Schedule: return .EditorScheduledPost
        case .Save:     return .EditorSavedDraft
        case .Update:   return .EditorUpdatedPost
        }
    }
}
