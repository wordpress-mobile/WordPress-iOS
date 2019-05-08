import Foundation

class PostActionSheet {

    weak var viewController: UIViewController?
    weak var interactivePostViewDelegate: InteractivePostViewDelegate?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func show(for post: Post) {
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let cancelActionButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dismiss the post action sheet"), style: .cancel) { _ in }
        actionSheetController.addAction(cancelActionButton)

        if post.status == BasePost.Status.publish || post.status == BasePost.Status.draft {
            let statsActionButton = UIAlertAction(title: NSLocalizedString("Stats", comment: "Label for post stats option. Tapping displays statistics for a post."), style: .default) { _ in
                // show stats
            }
            actionSheetController.addAction(statsActionButton)
        }

        let draftsActionButton = UIAlertAction(title: NSLocalizedString("Move to Draft", comment: "Label for an option that moves a post to the draft folder"), style: .default) { _ in
            // move to drafts
        }
        actionSheetController.addAction(draftsActionButton)

        if post.status == BasePost.Status.trash {
            let deleteActionButton = UIAlertAction(title: NSLocalizedString("Delete Permanently", comment: "Label for the delete post option. Tapping permanently deletes a post."), style: .destructive) { _ in
                print("Delete")
            }
            actionSheetController.addAction(deleteActionButton)
        } else {
            let trashActionButton = UIAlertAction(title: NSLocalizedString("Move to Trash", comment: "Label for a option that moves a post to the trash folder"), style: .destructive) { _ in
                // move to trash
            }
            actionSheetController.addAction(trashActionButton)
        }

        viewController?.present(actionSheetController, animated: true)
    }
}
