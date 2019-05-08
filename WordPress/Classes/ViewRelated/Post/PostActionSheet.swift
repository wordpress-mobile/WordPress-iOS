import Foundation

class PostActionSheet {

    weak var viewController: UIViewController?
    weak var interactivePostViewDelegate: InteractivePostViewDelegate?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func show(for post: Post) {
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        actionSheetController.addAction(cancelActionButton)

        if post.status == BasePost.Status.publish || post.status == BasePost.Status.draft {
            let statsActionButton = UIAlertAction(title: "Stats", style: .default) { _ in
                // show stats
            }
            actionSheetController.addAction(statsActionButton)
        }

        let draftsActionButton = UIAlertAction(title: "Move to drafts", style: .default) { _ in
            // move to drafts
        }
        actionSheetController.addAction(draftsActionButton)

        let trashActionButton = UIAlertAction(title: "Move to trash", style: .destructive) { _ in
            // move to trash
        }
        actionSheetController.addAction(trashActionButton)

        viewController?.present(actionSheetController, animated: true)
    }
}
