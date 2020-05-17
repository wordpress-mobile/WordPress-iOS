import Foundation

struct PostListConflictResolver {
    /// Presents an alert with an option to discard the local or web version of a post, and opens the editor with the non-discarded version
    static func handle(post: Post, in postListViewController: PostListViewController) {
        let conflictResolutionAlert = presentConflictResolutionAlert(for: post) { discardWeb in
            guard ReachabilityUtils.isInternetReachable() else {
                let offlineMessage = NSLocalizedString("Unable to resolve version conflicts while offline. Please try again later.", comment: "Message that appears when a user tries to resolve a post version conflict while their device is offline.")
                ReachabilityUtils.showNoInternetConnectionNotice(message: offlineMessage)
                return
            }
            discardWeb ? keepLocalVersion(post: post) : keepWebVersion(post: post)
            PostListHelper.openEditor(with: post, loadAutosaveRevision: false, in: postListViewController)
        }
        postListViewController.present(conflictResolutionAlert, animated: true)
    }

    /// Discard web revision, load post with local changes
    private static func keepLocalVersion(post: Post) {
        PostCoordinator.shared.autoSave(post)
    }

    /// Discard local changes, load latest web revision
    private static func keepWebVersion(post: Post) {
        post.updateRevision()
    }

    /// An alert that is presented when a post has a version conflict, and the user needs to select discarding either the local or web version
    static func presentConflictResolutionAlert(for post: Post,
                                                       didTapOption: @escaping (_ keepLocal: Bool) -> Void) -> UIAlertController {
        let title = NSLocalizedString("Resolve sync conflict", comment: "Title for an alert giving the user to the option to discard the web or local version of a post.")

        var localDateString = ""
        var webDateString = ""

        if let localDate = post.dateModified {
            localDateString = PostListHelper.dateAndTime(for: localDate)
        }
        if let webDate = post.original?.dateModified {
            webDateString = PostListHelper.dateAndTime(for: webDate)
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
