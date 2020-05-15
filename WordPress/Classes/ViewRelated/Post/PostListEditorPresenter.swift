import Foundation

/// Handle a user tapping a post in the post list. If an autosave revision is available, give the
/// user the option through a dialog alert to load the autosave (or just load the regular post) into
/// the editor.
/// Analytics are also tracked.
struct PostListEditorPresenter {

    static func handle(post: Post, in postListViewController: PostListViewController, hasVersionConflict: Bool? = false) {
        if hasVersionConflict! {
            handleVersionConflict(post: post, in: postListViewController)
        } else if !post.hasLocalChanges(), post.hasAutosaveRevision, let saveDate = post.dateModified, let autosaveDate = post.autosaveModifiedDate {
            handleAutosaves(post: post, in: postListViewController, saveDate: saveDate, autosaveDate: autosaveDate)
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

    private static func dateAndTime(for date: Date) -> String {
        return dateFormatter.string(from: date) + " @ " + timeFormatter.string(from: date)
    }
}


// MARK: - Version Conflict Alert

extension PostListEditorPresenter {

    private static func handleVersionConflict(post: Post, in postListViewController: PostListViewController) {
        let conflictResolutionAlert = presentConflictResolutionAlert(for: post) { keepLocal in
            switch keepLocal {
            case true:
                // discard web revision
                post.deleteRevision()
                openEditor(with: post, loadAutosaveRevision: false, in: postListViewController)
            default:
                // discard local changes
                PostCoordinator.shared.autoSave(post)
                openEditor(with: post, loadAutosaveRevision: true, in: postListViewController)
            }
        }
        postListViewController.present(conflictResolutionAlert, animated: true)
    }

    /// An alert that is presented when a post has a version conflict, and the user needs to select discarding either the local or web version
    private static func presentConflictResolutionAlert(for post: Post,
                                                       didTapOption: @escaping (_ keepLocal: Bool) -> Void) -> UIAlertController {
        let title = NSLocalizedString("Resolve sync conflict", comment: "Title for an alert giving the user to the option to discard the web or local version of a post.")

        var localDateString = ""
        var webDateString = ""

        if let localDate = post.dateModified {
            localDateString = dateAndTime(for: localDate)
        }
        if let webDate = post.latest().dateModified {
            webDateString = dateAndTime(for: webDate)
        }

        let str = """
        This post has two versions that are in conflict. Select the version you would like to discard.

        Local:
        Saved on \(localDateString)

        Web:
        Saved on \(webDateString)
        """

        let message = NSLocalizedString(str, comment: "Message asking a user to select between a local and web version of the post, with date/time strings for Web and Local.")

        let discardLocalButtonTitle = NSLocalizedString("Discard Local", comment: "Button title displayed in alert indicating that user wants to discard the local version.")
        let discardWebButtonTitle = NSLocalizedString("Discard Web", comment: "Button title displayed in alert indicating that user wants to discard the web version.")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: discardLocalButtonTitle, style: .default) { _ in
            didTapOption(false)
        })
        alertController.addAction(UIAlertAction(title: discardWebButtonTitle, style: .default) { _ in
            didTapOption(true)
        })

        alertController.view.accessibilityIdentifier = "version-conflict-resolution-alert"

        return alertController
    }
}

// MARK: - Autosave Options Alert

extension PostListEditorPresenter {

    /// Autosaves are ignored for posts with local changes.
    private static func handleAutosaves(post: Post, in postListViewController: PostListViewController,
                                        saveDate: Date, autosaveDate: Date) {
        let autosaveViewController = autosaveOptionsViewController(forSaveDate: saveDate, autosaveDate: autosaveDate, didTapOption: { loadAutosaveRevision in
            openEditor(with: post, loadAutosaveRevision: loadAutosaveRevision, in: postListViewController)
        })
        postListViewController.present(autosaveViewController, animated: true)
    }

    /// A dialog giving the user the choice between loading the current version a post or its autosaved version.
    private static func autosaveOptionsViewController(forSaveDate saveDate: Date, autosaveDate: Date, didTapOption: @escaping (_ loadAutosaveRevision: Bool) -> Void) -> UIAlertController {

        let title = NSLocalizedString("Which version would you like to edit?", comment: "Title displayed in popup when user has the option to load unsaved changes")

        let saveDateFormatted = dateAndTime(for: saveDate)
        let autosaveDateFormatted = dateAndTime(for: autosaveDate)
        let message = String(format: NSLocalizedString("You recently made changes to this post but didn't save them. Choose a version to load:\n\nFrom this device\nSaved on %@\n\nFrom another device\nSaved on %@\n", comment: "Message displayed in popup when user has the option to load unsaved changes. \n is a placeholder for a new line, and the two %@ are placeholders for the date of last save on this device, and date of last autosave on another device, respectively."), saveDateFormatted, autosaveDateFormatted)

        let loadSaveButtonTitle = NSLocalizedString("From this device", comment: "Button title displayed in popup indicating date of change on device")
        let fromAutosaveButtonTitle = NSLocalizedString("From another device", comment: "Button title displayed in popup indicating date of change on another device")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: loadSaveButtonTitle, style: .default) { _ in
            didTapOption(false)
        })
        alertController.addAction(UIAlertAction(title: fromAutosaveButtonTitle, style: .default) { _ in
            didTapOption(true)
        })

        alertController.view.accessibilityIdentifier = "autosave-options-alert"

        return alertController
    }
}
