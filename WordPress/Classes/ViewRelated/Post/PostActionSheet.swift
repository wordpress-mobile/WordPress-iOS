import Foundation
import AutomatticTracks

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

    func show(for postCardStatusViewModel: PostCardStatusViewModel, from view: UIView, isCompactOrSearching: Bool = false) {
        let unsupportedButtons: [PostCardStatusViewModel.Button] = [.edit, .more]
        let post = postCardStatusViewModel.post

        let buttons: [PostCardStatusViewModel.Button] = {
            let groups = postCardStatusViewModel.buttonGroups
            if isCompactOrSearching {
                return groups.primary + groups.secondary
            } else {
                return groups.secondary
            }
        }()

        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheetController.addCancelActionWithTitle(Titles.cancel)

        buttons
            .filter { !unsupportedButtons.contains($0) }
            .forEach { button in
                switch button {
                case .view:
                    actionSheetController.addDefaultActionWithTitle(Titles.view) { [weak self] _ in
                        self?.interactivePostViewDelegate?.view(post)
                    }
                case .stats:
                    actionSheetController.addDefaultActionWithTitle(Titles.stats) { [weak self] _ in
                        self?.interactivePostViewDelegate?.stats(for: post)
                    }
                case .publish:
                    actionSheetController.addDefaultActionWithTitle(Titles.publish) { [weak self] _ in
                        self?.interactivePostViewDelegate?.publish(post)
                    }
                case .moveToDraft:
                    actionSheetController.addDefaultActionWithTitle(Titles.draft) { [weak self] _ in
                        self?.interactivePostViewDelegate?.draft(post)
                    }
                case .trash:
                    let destructiveTitle = post.status == .trash ? Titles.delete : Titles.trash
                    actionSheetController.addDestructiveActionWithTitle(destructiveTitle) { [weak self] _ in
                        self?.interactivePostViewDelegate?.trash(post)
                    }
                case .cancelAutoUpload:
                    actionSheetController.addDefaultActionWithTitle(Titles.cancelAutoUpload) { [weak self] _ in
                        self?.interactivePostViewDelegate?.cancelAutoUpload(post)
                    }
                default:
                    CrashLogging.logMessage("Cannot handle unexpected button for post action sheet: \(button). This is a configuration error.", level: .error)
                }
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
        static let cancelAutoUpload = NSLocalizedString("Cancel Upload", comment: "Label for the Post List option that cancels automatic uploading of a post.")
        static let stats = NSLocalizedString("Stats", comment: "Label for post stats option. Tapping displays statistics for a post.")
        static let publish = NSLocalizedString("Publish Now", comment: "Label for an option that moves a publishes a post immediately")
        static let draft = NSLocalizedString("Move to Draft", comment: "Label for an option that moves a post to the draft folder")
        static let delete = NSLocalizedString("Delete Permanently", comment: "Label for the delete post option. Tapping permanently deletes a post.")
        static let trash = NSLocalizedString("Move to Trash", comment: "Label for a option that moves a post to the trash folder")
        static let view = NSLocalizedString("View", comment: "Label for the view post button. Tapping displays the post as it appears on the web.")
    }
}
