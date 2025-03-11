import Foundation
import WordPressFlux

struct PageEditorPresenter {
    @discardableResult
    static func handle(page: Page, in presentingViewController: UIViewController, entryPoint: PostEditorEntryPoint) -> Bool {
        guard !page.isSitePostsPage else {
            showSitePostPageUneditableNotice()
            return false
        }

        guard !PostCoordinator.shared.isUpdating(page) else {
            return false // It's clear from the UI that the cells are not interactive
        }

        // No editing posts until the conflict has been resolved.
        if let error = PostCoordinator.shared.syncError(for: page.original()),
           let saveError = error as? PostRepository.PostSaveError,
           case .conflict(let latest) = saveError {
            let page = page.original()
            PostCoordinator.shared.showResolveConflictView(post: page, remoteRevision: latest, source: .pageList)
            return false
        }

        /// This is a workaround for the lack of vie wapperance callbacks send
        /// by `EditPostViewController` due to its unconventional setup.
        NotificationCenter.default.post(name: .postListEditorPresenterWillShowEditor, object: nil)

        let editorViewController = EditPageViewController(page: page)
        editorViewController.entryPoint = entryPoint
        editorViewController.onClose = {
            NotificationCenter.default.post(name: .postListEditorPresenterDidHideEditor, object: nil)
        }
        presentingViewController.present(editorViewController, animated: false)
        return true
    }

    private static func showSitePostPageUneditableNotice() {
        let sitePostPageUneditableNotice = NSLocalizedString("The content of your latest posts page is automatically generated and cannot be edited.", comment: "Message informing the user that posts page cannot be edited")
        let notice = Notice(title: sitePostPageUneditableNotice, feedbackType: .warning)
        ActionDispatcher.global.dispatch(NoticeAction.post(notice))
    }
}
