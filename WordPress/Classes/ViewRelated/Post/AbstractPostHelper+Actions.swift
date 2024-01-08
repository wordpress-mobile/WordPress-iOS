import UIKit

extension AbstractPostHelper {
    // MARK: - Swipe Actions

    static func makeLeadingContextualActions(for post: AbstractPost, delegate: InteractivePostViewDelegate) -> [UIContextualAction] {
        var actions: [UIContextualAction] = []

        if post.status != .trash {
            let viewAction = UIContextualAction(style: .normal, title: Strings.swipeActionView) { [weak delegate] _, _, completion in
                delegate?.view(post)
                completion(true)
            }
            viewAction.image = UIImage(systemName: "safari")
            viewAction.backgroundColor = .systemBlue
            actions.append(viewAction)
        }

        return actions
    }

    static func makeTrailingContextualActions(for post: AbstractPost, delegate: InteractivePostViewDelegate) -> [UIContextualAction] {
        var actions: [UIContextualAction] = []

        let trashAction = UIContextualAction(
            style: .destructive,
            title: post.status == .trash ? Strings.swipeActionDeletePermanently : Strings.swipeActionTrash
        ) { [weak delegate] _, _, completion in
            delegate?.trash(post) {
                completion(true)
            }
        }
        trashAction.image = UIImage(systemName: "trash")
        actions.append(trashAction)

        if post is Post, post.status == .publish && post.hasRemote() {
            let shareAction = UIContextualAction(style: .normal, title: Strings.swipeActionShare) { [weak delegate] _, view, completion in
                delegate?.share(post, fromView: view)
                completion(true)
            }
            shareAction.image = UIImage(systemName: "square.and.arrow.up")
            actions.append(shareAction)
        }

        return actions
    }
}

private enum Strings {
    static let swipeActionView = NSLocalizedString("postList.swipeActionView", value: "View", comment: "Title for the 'View' post list row swipe action")
    static let swipeActionShare = NSLocalizedString("postList.swipeActionShare", value: "Share", comment: "Title for the 'Share' post list row swipe action")
    static let swipeActionTrash = NSLocalizedString("postList.swipeActionDelete", value: "Trash", comment: "Title for the 'Trash' post list row swipe action")
    static let swipeActionDeletePermanently = NSLocalizedString("postList.swipeActionDeletePermanently", value: "Delete", comment: "Title for the 'Delete' post list row swipe action")
}
