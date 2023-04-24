import Foundation
import WordPressFlux

struct PageEditorPresenter {
    @discardableResult
    static func handle(page: Page, in presentingViewController: UIViewController, entryPoint: PostEditorEntryPoint) -> Bool {
        guard !page.isSitePostsPage else {
            showSitePostPageUneditableNotice()
            return false
        }

        guard page.status != .trash else {
            return false
        }

        guard !PostCoordinator.shared.isUploading(post: page) else {
            presentAlertForPageBeingUploaded()
            return false
        }

        QuickStartTourGuide.shared.endCurrentTour()

        let editorViewController = EditPageViewController(page: page)
        editorViewController.entryPoint = entryPoint
        presentingViewController.present(editorViewController, animated: false)
        return true
    }

    private static func showSitePostPageUneditableNotice() {
        let sitePostPageUneditableNotice =  NSLocalizedString("The content of your latest posts page is automatically generated and cannot be edited.", comment: "Message informing the user that posts page cannot be edited")
        let notice = Notice(title: sitePostPageUneditableNotice, feedbackType: .warning)
        ActionDispatcher.global.dispatch(NoticeAction.post(notice))
    }

    private static func presentAlertForPageBeingUploaded() {
        let message = NSLocalizedString("This page is currently uploading. It won't take long – try again soon and you'll be able to edit it.", comment: "Prompts the user that the page is being uploaded and cannot be edited while that process is ongoing.")

        let alertCancel = NSLocalizedString("OK", comment: "Title of an OK button. Pressing the button acknowledges and dismisses a prompt.")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addCancelActionWithTitle(alertCancel, handler: nil)
        alertController.presentFromRootViewController()
    }
}
