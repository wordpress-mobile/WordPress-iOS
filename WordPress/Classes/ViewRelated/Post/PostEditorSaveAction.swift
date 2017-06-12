import Foundation
import WordPressComAnalytics

/// Encapsulates the current save action of the editor, based on its
/// post status, whether it's already been saved, is scheduled, etc.
@objc enum PostEditorSaveAction: Int {
    case schedule
    case post
    case save
    case update
}

/// Some utility methods to help keep track of the current post action
extension WPPostViewController {
    /// What action should be taken when the user taps the editor's save button?
    var currentSaveAction: PostEditorSaveAction {
        if let status = post.status,
            let originalStatus = post.original?.status, status != originalStatus || !post.hasRemote() {
            if (post.isScheduled()) {
                return .schedule
            } else if (status == .publish) {
                return .post
            } else {
                return .save
            }
        } else {
            return .update
        }
    }

    /// The title for the Save button, based on the current save action
    var saveBarButtonItemTitle: String {
        switch currentSaveAction {
        case .schedule:
            return NSLocalizedString("Schedule", comment: "Schedule button, this is what the Publish button changes to in the Post Editor if the post has been scheduled for posting later.")
        case .post:
            return NSLocalizedString("Post", comment: "Publish button label.")
        case .save:
            return NSLocalizedString("Save", comment: "Save button label (saving content, ex: Post, Page, Comment).")
        case .update:
            return NSLocalizedString("Update", comment: "Update button label (saving content, ex: Post, Page, Comment).")
        }
    }

    /// The analytics stat to post when the user saves, based on the current post action
    func analyticsStatForSaveAction(_ action: PostEditorSaveAction) -> WPAnalyticsStat {
        switch action {
        case .post:     return .editorPublishedPost
        case .schedule: return .editorScheduledPost
        case .save:     return .editorSavedDraft
        case .update:   return .editorUpdatedPost
        }
    }
}
