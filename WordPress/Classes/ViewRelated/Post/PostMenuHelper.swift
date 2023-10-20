import Foundation
import UIKit

struct PostMenuHelper {

    let statusViewModel: PostCardStatusViewModel

    /// Creates a menu for post actions
    ///
    /// - parameters:
    ///   - presentingView: The view presenting the menu
    ///   - delegate: The delegate that performs post actions
    func makeMenu(presentingView: UIView, delegate: InteractivePostViewDelegate) -> UIMenu {
        let actions = makeActions(presentingView: presentingView, delegate: delegate)
        return UIMenu(title: "", options: .displayInline, children: actions)
    }

    /// Creates an array of post actions
    ///
    /// - parameters:
    ///   - presentingView: The view presenting the menu
    ///   - delegate: The delegate that performs post actions
    private func makeActions(presentingView: UIView, delegate: InteractivePostViewDelegate) -> [UIAction] {
        let unsupportedButtons: [PostCardStatusViewModel.Button] = [.edit, .more]
        let post = statusViewModel.post

        let buttons: [PostCardStatusViewModel.Button] = {
            let groups = statusViewModel.buttonGroups
            return groups.primary + groups.secondary
        }()

        return buttons
            .filter { !unsupportedButtons.contains($0) }
            .map { button in
                UIAction(title: button.title, image: button.icon, handler: { _ in
                    button.performAction(for: post, view: presentingView, delegate: delegate)
                })
            }
    }
}

protocol PostMenuAction {
    var title: String { get }
    var icon: UIImage? { get }
    func performAction(for post: Post, view: UIView, delegate: InteractivePostViewDelegate)
}

extension PostCardStatusViewModel.Button: PostMenuAction {

    var title: String {
        switch self {
        case .edit: Strings.edit
        case .retry: Strings.retry
        case .view: Strings.view
        case .more: ""
        case .publish: Strings.publish
        case .stats: Strings.stats
        case .duplicate: Strings.duplicate
        case .moveToDraft: Strings.draft
        case .trash: Strings.trash
        case .cancelAutoUpload: Strings.cancelAutoUpload
        case .share: Strings.share
        case .copyLink: Strings.copyLink
        case .blaze: Strings.blaze
        }
    }

    var icon: UIImage? {
        switch self {
        case .edit: UIImage()
        case .retry: UIImage()
        case .view: UIImage(systemName: "eye")
        case .more: UIImage()
        case .publish: UIImage(named: "globe")
        case .stats: UIImage(systemName: "chart.bar.xaxis")
        case .duplicate: UIImage(systemName: "doc.on.doc")
        case .moveToDraft: UIImage(systemName: "pencil.line")
        case .trash: UIImage(systemName: "trash")
        case .cancelAutoUpload: UIImage()
        case .share: UIImage(systemName: "square.and.arrow.up")
        case .copyLink: UIImage(systemName: "link")
        case .blaze: UIImage(systemName: "flame")
        }
    }

    func performAction(for post: Post, view: UIView, delegate: InteractivePostViewDelegate) {
        switch self {
        case .edit:
            delegate.edit(post)
        case .retry:
            delegate.retry(post)
        case .view:
            delegate.view(post)
        case .more:
            WordPressAppDelegate.crashLogging?.logMessage("Cannot handle unexpected action. This is a configuration error.", level: .error)
        case .publish:
            delegate.publish(post)
        case .stats:
            delegate.stats(for: post)
        case .duplicate:
            delegate.duplicate(post)
        case .moveToDraft:
            delegate.draft(post)
        case .trash:
            delegate.trash(post)
        case .cancelAutoUpload:
            delegate.cancelAutoUpload(post)
        case .share:
            delegate.share(post, fromView: view)
        case .copyLink:
            delegate.copyLink(post)
        case .blaze:
            delegate.blaze(post)
        }
    }

    private enum Strings {
        static let cancelAutoUpload = NSLocalizedString("Cancel Upload", comment: "Label for the Post List option that cancels automatic uploading of a post.")
        static let stats = NSLocalizedString("Stats", comment: "Label for post stats option. Tapping displays statistics for a post.")
        static let duplicate = NSLocalizedString("Duplicate", comment: "Label for post duplicate option. Tapping creates a copy of the post.")
        static let publish = NSLocalizedString("Publish Now", comment: "Label for an option that moves a publishes a post immediately")
        static let draft = NSLocalizedString("Move to Draft", comment: "Label for an option that moves a post to the draft folder")
        static let delete = NSLocalizedString("Delete Permanently", comment: "Label for the delete post option. Tapping permanently deletes a post.")
        static let trash = NSLocalizedString("Move to Trash", comment: "Label for a option that moves a post to the trash folder")
        static let view = NSLocalizedString("View", comment: "Label for the view post button. Tapping displays the post as it appears on the web.")
        static let retry = NSLocalizedString("Retry", comment: "Retry uploading the post.")
        static let edit = NSLocalizedString("Edit", comment: "Edit the post.")
        static let share = NSLocalizedString("Share", comment: "Share the post.")
        static let blaze = NSLocalizedString("posts.blaze.actionTitle", value: "Promote with Blaze", comment: "Promote the post with Blaze.")
        static let copyLink = NSLocalizedString("Copy Link", comment: "Copy the post url and paste anywhere in phone")
    }
}
