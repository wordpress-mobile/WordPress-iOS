import Foundation
import UIKit

typealias EditorPresenterViewController = UIViewController & EditorAnalyticsProperties

/// Provide properties for when showing the editor (like type of post, filter, etc)
protocol EditorAnalyticsProperties: AnyObject {
    func propertiesForAnalytics() -> [String: AnyObject]
}

/// Handle a user tapping a post in the post list. If an autosave revision is available, give the
/// user the option through a dialog alert to load the autosave (or just load the regular post) into
/// the editor.
/// Analytics are also tracked.
struct PostListEditorPresenter {

    static func handle(post: Post, in postListViewController: EditorPresenterViewController, entryPoint: PostEditorEntryPoint = .unknown) {
        // Return early if a post is still uploading when the editor's requested.
        guard !PostCoordinator.shared.isUpdating(post) else {
            return // It's clear from the UI that the cells are not interactive
        }

        // No editing posts until the conflict has been resolved.
        if let error = PostCoordinator.shared.syncError(for: post.original()),
           let saveError = error as? PostRepository.PostSaveError,
           case .conflict(let latest) = saveError {
            let post = post.original()
            PostCoordinator.shared.showResolveConflictView(post: post, remoteRevision: latest, source: .postList)
            return
        }

        openEditor(with: post, in: postListViewController, entryPoint: entryPoint)
    }

    static func handleCopy(post: Post, in postListViewController: EditorPresenterViewController) {
        // Copy Post
        let newPost = post.blog.createDraftPost()
        newPost.postTitle = post.postTitle
        newPost.content = post.content
        newPost.categories = post.categories
        newPost.postFormat = post.postFormat

        openEditor(with: newPost, in: postListViewController)

        WPAppAnalytics.track(.postListDuplicateAction, withProperties: postListViewController.propertiesForAnalytics(), with: post)
    }

    private static func openEditor(with post: Post, in postListViewController: EditorPresenterViewController, entryPoint: PostEditorEntryPoint = .unknown) {
        /// This is a workaround for the lack of vie wapperance callbacks send
        /// by `EditPostViewController` due to its weird setup.
        NotificationCenter.default.post(name: .postListEditorPresenterWillShowEditor, object: nil)

        let editor = EditPostViewController(post: post)
        editor.modalPresentationStyle = .fullScreen
        editor.entryPoint = entryPoint
        editor.onClose = {
            NotificationCenter.default.post(name: .postListEditorPresenterDidHideEditor, object: nil)
        }
        postListViewController.present(editor, animated: false)
    }
}

extension Foundation.Notification.Name {
    static let postListEditorPresenterWillShowEditor = Foundation.Notification.Name("org.automattic.postListEditorPresenterWillShowEditor")
    static let postListEditorPresenterDidHideEditor = Foundation.Notification.Name("org.automattic.postListEditorPresenterDidHideEditor")
}
