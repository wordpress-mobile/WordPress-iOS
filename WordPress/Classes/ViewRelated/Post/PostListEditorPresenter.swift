import Foundation

/// Handle a user tapping a post in the post list. If an autosave revision is available, the user
/// is given the option through a dialog alert to load it (or the regular post) into the editor.
/// Analytics are also tracked.
enum PostListEditorPresenter {

    static func handle(post: Post, in postListViewController: PostListViewController) {

        // Autosaves are ignored for posts with local changes.
        if !post.hasLocalChanges(), post.hasAutosaveRevision, let saveDate = post.dateModified, let autosaveDate = post.autosaveModifiedDate {
            let autosaveViewController = UIAlertController.autosaveOptionsViewController(forSaveDate: saveDate, autosaveDate: autosaveDate, didTapOption: { loadAutosaveRevision in
                openEditor(with: post, loadAutosaveRevision: loadAutosaveRevision, in: postListViewController)
            })
            postListViewController.present(autosaveViewController, animated: true)
        } else {
            openEditor(with: post, loadAutosaveRevision: false, in: postListViewController)
        }
    }

    private static func openEditor(with post: Post, loadAutosaveRevision: Bool, in postListViewController: PostListViewController) {
        let editor = EditPostViewController(post: post, loadAutosaveRevision: loadAutosaveRevision)
        editor.modalPresentationStyle = .fullScreen
        postListViewController.present(editor, animated: false)
        WPAppAnalytics.track(.postListEditAction, withProperties: postListViewController.propertiesForAnalytics(), with: post)
    }
}
