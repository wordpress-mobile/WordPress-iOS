import Foundation

@objc protocol PostActionSheetDelegate {
    func showActionSheet(_ postCardStatusViewModel: PostCardStatusViewModel, from view: UIView)
}

class PostActionSheet {

    weak var viewController: UIViewController?
    weak var interactivePostViewDelegate: InteractivePostViewDelegate?

    init(viewController: UIViewController, interactivePostViewDelegate: InteractivePostViewDelegate) {
        self.viewController = viewController
        self.interactivePostViewDelegate = interactivePostViewDelegate
    }

    func show(for postCardStatusViewModel: PostCardStatusViewModel, from view: UIView, showViewOption: Bool = false) {
        let post = postCardStatusViewModel.post 

        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        actionSheetController.addCancelActionWithTitle(Titles.cancel)

        if showViewOption {
            actionSheetController.addDefaultActionWithTitle(Titles.view) { [weak self] _ in
                self?.interactivePostViewDelegate?.view(post)
            }
        }

        if post.status == .publish {
            actionSheetController.addDefaultActionWithTitle(Titles.stats) { [weak self] _ in
                self?.interactivePostViewDelegate?.stats(for: post)
            }
        }

        if post.status == .draft {
            actionSheetController.addDefaultActionWithTitle(Titles.publish) { [weak self] _ in
                self?.interactivePostViewDelegate?.publish(post)
            }
        } else {
            actionSheetController.addDefaultActionWithTitle(Titles.draft) { [weak self] _ in
                self?.interactivePostViewDelegate?.draft(post)
            }
        }

        let destructiveTitle = post.status == .trash ? Titles.delete : Titles.trash
        actionSheetController.addDestructiveActionWithTitle(destructiveTitle) { [weak self] _ in
            self?.interactivePostViewDelegate?.trash(post)
        }

        if let presentationController = actionSheetController.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.sourceView = view
            presentationController.sourceRect = view.bounds
        }

        viewController?.present(actionSheetController, animated: true)
    }

    struct Titles {
        static let cancel = NSLocalizedString("Cancel", comment: "Dismiss the post action sheet")
        static let stats = NSLocalizedString("Stats", comment: "Label for post stats option. Tapping displays statistics for a post.")
        static let publish = NSLocalizedString("Publish Now", comment: "Label for an option that moves a publishes a post immediately")
        static let draft = NSLocalizedString("Move to Draft", comment: "Label for an option that moves a post to the draft folder")
        static let delete = NSLocalizedString("Delete Permanently", comment: "Label for the delete post option. Tapping permanently deletes a post.")
        static let trash = NSLocalizedString("Move to Trash", comment: "Label for a option that moves a post to the trash folder")
        static let view = NSLocalizedString("View", comment: "Label for the view post button. Tapping displays the post as it appears on the web.")
    }
}
