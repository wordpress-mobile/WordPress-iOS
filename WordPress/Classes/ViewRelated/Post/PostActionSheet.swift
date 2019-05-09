import Foundation

class PostActionSheet {

    weak var viewController: UIViewController?
    weak var interactivePostViewDelegate: InteractivePostViewDelegate?

    init(viewController: UIViewController, interactivePostViewDelegate: InteractivePostViewDelegate) {
        self.viewController = viewController
        self.interactivePostViewDelegate = interactivePostViewDelegate
    }

    func show(for post: Post, from view: UIView) {
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        actionSheetController.addCancelActionWithTitle(OptionTitle.cancel)

        if post.status == BasePost.Status.publish || post.status == BasePost.Status.draft {
            actionSheetController.addDefaultActionWithTitle(OptionTitle.stats) { [weak self] _ in
                self?.interactivePostViewDelegate?.handleStats?(for: post)
            }
        }

        if post.status != BasePost.Status.draft {
            actionSheetController.addDefaultActionWithTitle(OptionTitle.draft) { [weak self] _ in
                self?.interactivePostViewDelegate?.handleDraftPost?(post)
            }
        }

        let destructiveTitle = post.status == BasePost.Status.trash ? OptionTitle.delete : OptionTitle.trash
        actionSheetController.addDestructiveActionWithTitle(destructiveTitle) { [weak self] _ in
            self?.interactivePostViewDelegate?.handleTrashPost?(post)
        }

        if let presentationController = actionSheetController.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.sourceView = view
            presentationController.sourceRect = view.bounds;
        }

        viewController?.present(actionSheetController, animated: true)
    }

    struct OptionTitle {
        static let cancel = NSLocalizedString("Cancel", comment: "Dismiss the post action sheet")
        static let stats = NSLocalizedString("Stats", comment: "Label for post stats option. Tapping displays statistics for a post.")
        static let draft = NSLocalizedString("Move to Draft", comment: "Label for an option that moves a post to the draft folder")
        static let delete = NSLocalizedString("Delete Permanently", comment: "Label for the delete post option. Tapping permanently deletes a post.")
        static let trash = NSLocalizedString("Move to Trash", comment: "Label for a option that moves a post to the trash folder")
    }
}
