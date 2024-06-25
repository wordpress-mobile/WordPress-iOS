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
            showPostTab(animated: true, completion: afterDismiss)
        }
    }

    func showPostTab(for blog: Blog) {
        let context = ContextManager.shared.mainContext
        if Blog.count(in: context) == 0 {
            mySitesCoordinator.showAddNewSite()
        } else {
            showPostTab(animated: true, blog: blog)
        }
    }

    // TODO: rename
    func showPostTab(animated: Bool,
                     post: Post? = nil,
                     blog: Blog? = nil,
                     completion afterDismiss: (() -> Void)? = nil) {
        if rootViewController.presentedViewController != nil {
            rootViewController.dismiss(animated: false)
        }

        guard let blog = blog ?? currentOrLastBlog() else {
            return
        }

        let editor: EditPostViewController
        if let post {
            editor = EditPostViewController(post: post)
        } else {
            editor = EditPostViewController(blog: blog)
        }
        editor.modalPresentationStyle = .fullScreen
        editor.showImmediately = !animated
        editor.afterDismiss = afterDismiss

        let properties = [WPAppAnalyticsKeyTapSource: "create_button", WPAppAnalyticsKeyPostType: "post"]
        WPAppAnalytics.track(.editorCreatedPost, withProperties: properties, with: blog)
        rootViewController.present(editor, animated: false)
    }

    func showPageEditor(forBlog: Blog? = nil) {
        showPageEditor(blog: forBlog)
    }

    /// Show the page tab
    /// - Parameter blog: Blog to a add a page to. Uses the current or last blog if not provided
    func showPageEditor(blog inBlog: Blog? = nil, title: String? = nil, content: String? = nil, source: String = "create_button") {

        // If we are already showing a view controller, dismiss and show the editor afterward
        guard rootViewController.presentedViewController == nil else {
            rootViewController.dismiss(animated: true) { [weak self] in
                self?.showPageEditor(blog: inBlog, title: title, content: content, source: source)
            }
            return
        }
        guard let blog = inBlog ?? self.currentOrLastBlog() else { return }
        guard content == nil else {
            showEditor(blog: blog, title: title, content: content)
            return
        }

        WPAnalytics.track(WPAnalyticsEvent.editorCreatedPage,
                          properties: [WPAppAnalyticsKeyTapSource: source],
                          blog: blog)
        PageCoordinator.showLayoutPickerIfNeeded(from: rootViewController, forBlog: blog) { [weak self] (selectedLayout) in
            self?.showEditor(blog: blog, title: selectedLayout?.title, content: selectedLayout?.content)
        }
    }

    private func showEditor(blog: Blog, title: String?, content: String?) {
        let editorViewController = EditPageViewController(blog: blog, postTitle: title, content: content)
        rootViewController.present(editorViewController, animated: false)
    }
}
