import Foundation

class PostActionSheet {

    weak var viewController: UIViewController?
    weak var interactivePostViewDelegate: InteractivePostViewDelegate?

    init(viewController: UIViewController, interactivePostViewDelegate: InteractivePostViewDelegate) {
        self.viewController = viewController
        self.interactivePostViewDelegate = interactivePostViewDelegate
    }

    func show(for post: Post) {
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let cancelActionButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dismiss the post action sheet"), style: .cancel) { _ in }
        actionSheetController.addAction(cancelActionButton)

        if post.status == BasePost.Status.publish || post.status == BasePost.Status.draft {
            let statsActionButton = UIAlertAction(title: NSLocalizedString("Stats", comment: "Label for post stats option. Tapping displays statistics for a post."), style: .default) { [weak self] _ in
                self?.interactivePostViewDelegate?.handleStats?(for: post)
            }
            actionSheetController.addAction(statsActionButton)
        }

        if post.status != BasePost.Status.draft {
            let draftsActionButton = UIAlertAction(title: NSLocalizedString("Move to Draft", comment: "Label for an option that moves a post to the draft folder"), style: .default) { [weak self] _ in
                self?.interactivePostViewDelegate?.handleDraftPost?(post)
            }
            actionSheetController.addAction(draftsActionButton)
        }

        if post.status == BasePost.Status.trash {
            let deleteActionButton = UIAlertAction(title: NSLocalizedString("Delete Permanently", comment: "Label for the delete post option. Tapping permanently deletes a post."), style: .destructive) { [weak self] _ in
                self?.interactivePostViewDelegate?.handleTrashPost?(post)
            }
            actionSheetController.addAction(deleteActionButton)
        } else {
            let trashActionButton = UIAlertAction(title: NSLocalizedString("Move to Trash", comment: "Label for a option that moves a post to the trash folder"), style: .destructive) { [weak self] _ in
                self?.interactivePostViewDelegate?.handleTrashPost?(post)
            }
            actionSheetController.addAction(trashActionButton)
        }

        viewController?.present(actionSheetController, animated: true)
    }
}
