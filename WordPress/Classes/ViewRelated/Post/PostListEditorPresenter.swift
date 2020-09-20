import Foundation

/// Handle a user tapping a post in the post list. If an autosave revision is available, give the
/// user the option through a dialog alert to load the autosave (or just load the regular post) into
/// the editor.
/// Analytics are also tracked.
struct PostListEditorPresenter {

    static func handle(post: Post, in postListViewController: PostListViewController) {

        // Autosaves are ignored for posts with local changes.
        if !post.hasLocalChanges(), post.hasAutosaveRevision {
            let autosaveViewController = autosaveOptionsViewController(for: post, didTapOption: { loadAutosaveRevision in
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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static func dateAndTime(for date: Date?) -> String {
        guard let date = date else {
            return "Unknown Date"
        }
        return dateFormatter.string(from: date) + " @ " + timeFormatter.string(from: date)
    }

    /// A dialog giving the user the choice between loading the local version or the remote version when there's a version conflict
    private static func autosaveOptionsViewController(for post: Post, didTapOption: @escaping (_ loadAutosaveRevision: Bool) -> Void) -> UIAlertController {
        let title = NSLocalizedString("Resolve sync conflict", comment: "Title displayed in popup when user has to resolve a verion conflict due to unsaved/autosaved changes")

        let localFormattedDate = dateAndTime(for: post.dateModified)
        let remoteFormattedDate = dateAndTime(for: post.autosaveModifiedDate)

        let alertMessageText = """
    This post has two versions that are in conflict. Select the version you would like to keep:

    Local
    Saved on \(localFormattedDate)

    Remote
    Saved on \(remoteFormattedDate)

    """

        let message = NSLocalizedString(alertMessageText, comment: "Message displayed in popup displayed to resolve version conflict")

        let localButtonTitle = NSLocalizedString("Keep Local", comment: "Button title displayed in popup indicating date of change on device")
        let remoteButtonTitle = NSLocalizedString("Keep Remote", comment: "Button title displayed in popup indicating date of change on another device")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: localButtonTitle, style: .default) { _ in
            didTapOption(false)
        })
        alertController.addAction(UIAlertAction(title: remoteButtonTitle, style: .default) { _ in
            didTapOption(true)
        })

        alertController.view.accessibilityIdentifier = "autosave-options-alert"

        return alertController
    }
}
