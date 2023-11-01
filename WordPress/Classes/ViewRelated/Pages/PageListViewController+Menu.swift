import Foundation

extension PageListViewController: InteractivePostViewDelegate {

    func edit(_ apost: AbstractPost) {
        guard let page = apost as? Page else { return }

        let didOpenEditor = PageEditorPresenter.handle(page: page, in: self, entryPoint: .pagesList)
        if didOpenEditor {
            WPAppAnalytics.track(.postListEditAction, withProperties: propertiesForAnalytics(), with: page)
        }
    }

    func view(_ apost: AbstractPost) {
        viewPost(apost)
    }

    func stats(for apost: AbstractPost) {
        // Not available for pages
    }

    func duplicate(_ apost: AbstractPost) {
        guard let page = apost as? Page else { return }
        copyPage(page)
    }

    func publish(_ apost: AbstractPost) {
        publishPost(apost)
    }

    func trash(_ apost: AbstractPost) {
        guard let page = apost as? Page else { return }
        trashPage(page)
    }

    func draft(_ apost: AbstractPost) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            moveToDraft(apost)
        }
    }

    func retry(_ apost: AbstractPost) {
        guard let page = apost as? Page else { return }
        retryPage(page)
    }

    func cancelAutoUpload(_ apost: AbstractPost) {
        // Not available for pages
    }

    func share(_ apost: AbstractPost, fromView view: UIView) {
        // Not available for pages
    }

    func blaze(_ apost: AbstractPost) {
        BlazeEventsTracker.trackEntryPointTapped(for: .pagesList)
        BlazeFlowCoordinator.presentBlaze(in: self, source: .pagesList, blog: blog, post: apost)
    }

    func comments(_ apost: AbstractPost) {
        // Not available for pages
    }

    func setParent(for apost: AbstractPost, at indexPath: IndexPath) {
        guard let page = apost as? Page else { return }
        setParent(for: page, at: indexPath)
    }

    func setHomepage(for apost: AbstractPost) {
        guard let page = apost as? Page else { return }
        setPageAsHomepage(page)
    }

    func setPostsPage(for apost: AbstractPost) {
        guard let page = apost as? Page else { return }
        setPageAsPostsPage(page)
    }

    // MARK: - Helpers

    private func copyPage(_ page: Page) {
        // Analytics
        WPAnalytics.track(.postListDuplicateAction, withProperties: propertiesForAnalytics())
        // Copy Page
        let newPage = page.blog.createDraftPage()
        newPage.postTitle = page.postTitle
        newPage.content = page.content
        // Open Editor
        let editorViewController = EditPageViewController(page: newPage)
        present(editorViewController, animated: false)
    }

    private func retryPage(_ page: Page) {
        PostCoordinator.shared.save(page)
    }

    private func trashPage(_ page: Page) {
        guard ReachabilityUtils.isInternetReachable() else {
            ReachabilityUtils.showNoInternetConnectionNotice(message: Strings.offlineMessage)
            return
        }

        let isPageTrashed = page.status == .trash
        let actionText = isPageTrashed ? Strings.DeletePermanently.actionText : Strings.Trash.actionText
        let titleText = isPageTrashed ? Strings.DeletePermanently.titleText : Strings.Trash.titleText
        let messageText = isPageTrashed ? Strings.DeletePermanently.messageText : Strings.Trash.messageText

        let alertController = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert)
        alertController.addCancelActionWithTitle(Strings.cancelText)
        alertController.addDestructiveActionWithTitle(actionText) { [weak self] action in
            self?.deletePost(page)
        }
        alertController.presentFromRootViewController()
    }
}

private enum Strings {

    static let offlineMessage = NSLocalizedString("pagesList.trash.offline", value: "Unable to trash pages while offline. Please try again later.", comment: "Message that appears when a user tries to trash a page while their device is offline.")
    static let cancelText = NSLocalizedString("pagesList.trash.cancel", value: "Cancel", comment: "Cancels an Action")

    enum DeletePermanently {
        static let actionText = NSLocalizedString("pagesList.deletePermanently.actionTitle", value: "Delete Permanently", comment: "Delete option in the confirmation alert when deleting a page from the trash.")
        static let titleText = NSLocalizedString("pagesList.deletePermanently.alertTitle", value: "Delete Permanently?", comment: "Title of the confirmation alert when deleting a page from the trash.")
        static let messageText = NSLocalizedString("pagesList.deletePermanently.alertMessage", value: "Are you sure you want to permanently delete this page?", comment: "Message of the confirmation alert when deleting a page from the trash.")
    }

    enum Trash {
        static let actionText = NSLocalizedString("pagesList.trash.actionTitle", value: "Move to Trash", comment: "Trash option in the trash page confirmation alert.")
        static let titleText = NSLocalizedString("pagesList.trash.alertTitle", value: "Trash this page?", comment: "Title of the trash page confirmation alert.")
        static let messageText = NSLocalizedString("pagesList.trash.alertMessage", value: "Are you sure you want to trash this page?", comment: "Message of the trash page confirmation alert.")
    }
}
