import Foundation

extension RootViewPresenter {
    func currentOrLastBlog() -> Blog? {
        if let blog = currentlyVisibleBlog() {
            return blog
        }
        let context = ContextManager.shared.mainContext
        return Blog.lastUsedOrFirst(in: context)
    }

    func showPostTab() {
        showPostTab(completion: nil)
    }

    func showPostTab(completion afterDismiss: (() -> Void)?) {
        let context = ContextManager.shared.mainContext
        // Ignore taps on the post tab and instead show the modal.
        if Blog.count(in: context) == 0 {
            mySitesCoordinator.showAddNewSite()
        } else {
            showPostTab(animated: true, toMedia: false, completion: afterDismiss)
        }
    }

    func showPostTab(for blog: Blog) {
        let context = ContextManager.shared.mainContext
        if Blog.count(in: context) == 0 {
            mySitesCoordinator.showAddNewSite()
        } else {
            showPostTab(animated: true, toMedia: false, blog: blog)
        }
    }

    func showPostTab(animated: Bool,
                     toMedia openToMedia: Bool,
                     blog: Blog? = nil,
                     completion afterDismiss: (() -> Void)? = nil) {
        if rootViewController.presentedViewController != nil {
            rootViewController.dismiss(animated: false)
        }

        guard let blog = blog ?? currentOrLastBlog() else {
            return
        }

        let editor = EditPostViewController(blog: blog)
        editor.modalPresentationStyle = .fullScreen
        editor.showImmediately = !animated
        editor.openWithMediaPicker = openToMedia
        editor.afterDismiss = afterDismiss

        let properties = [WPAppAnalyticsKeyTapSource: "create_button", WPAppAnalyticsKeyPostType: "post"]
        WPAppAnalytics.track(.editorCreatedPost, withProperties: properties, with: blog)
        rootViewController.present(editor, animated: false)
    }
}
