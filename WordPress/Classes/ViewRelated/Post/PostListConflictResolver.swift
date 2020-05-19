import Foundation

struct PostListConflictResolver {

    /// Presents an alert with an option to discard the local or web version of a post, and opens the editor with the non-discarded version
    static func handle(post: Post, in viewController: UIViewController) {
        let alertController = presentAlertController(for: post) { discardWeb in
            discardWeb ? keepLocalVersion(post: post, in: viewController) : keepWebVersion(post: post, in: viewController)
        }
        viewController.present(alertController, animated: true)
    }

    /// Discard web revision, load post with local changes
    private static func keepLocalVersion(post: Post, in viewController: UIViewController) {
        PostCoordinator.shared.save(post, automatedRetry: true) { result in
            switch result {
            case .success(let uploadedPost):
                PostListHelper.openEditor(with: uploadedPost as! Post, loadAutosaveRevision: false, in: viewController as! PostListViewController)
            case .failure(let error):
                DDLogError("Error resolving post conflict: \(error.localizedDescription)")
            }
        }
    }

    /// Discard local changes, load latest web revision
    private static func keepWebVersion(post: Post, in viewController: UIViewController) {
        post.updateRevision()
        PostListHelper.openEditor(with: post, loadAutosaveRevision: false, in: viewController as! PostListViewController)
    }

    /// An alert that is presented when a post has a version conflict, and the user needs to select discarding either the local or web version
    static func presentAlertController(for post: Post,
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
        Saved on %@

        Web:
        Saved on %@
        """

        let localizedMessage = NSLocalizedString(str, comment: "Message asking a user to select between a local and web version of the post, with date/time strings for Web and Local.")
        let message = String(format: localizedMessage, localDateString, webDateString)

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
