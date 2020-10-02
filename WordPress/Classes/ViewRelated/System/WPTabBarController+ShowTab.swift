extension WPTabBarController {

    @objc func showPageEditor(forBlog: Blog? = nil) {
        showPageEditor(blog: forBlog)
    }

    /// Show the page tab
    /// - Parameter inBlog: Blog to a add a page to. Uses the current or last blog if not provided
    func showPageEditor(blog inBlog: Blog? = nil, title: String? = nil, content: String? = nil, source: String = "create_button") {

        // If we are already showing a view controller, dismiss and show the editor afterward
        guard presentedViewController == nil else {
            dismiss(animated: true) { [weak self] in
                self?.showPageEditor(blog: inBlog, title: title, content: content, source: source)
            }
            return
        }
        guard let blog = inBlog ?? self.currentOrLastBlog() else { return }
        guard content == nil else {
            showEditor(blog: blog, title: title, content: content)
            return
        }

        let blogID = blog.dotComID?.intValue ?? 0 as Any
        WPAnalytics.track(WPAnalyticsEvent.editorCreatedPage, properties: ["tap_source": source, WPAppAnalyticsKeyBlogID: blogID, WPAppAnalyticsKeyPostType: "page"])

        PageCoordinator.showLayoutPickerIfNeeded(from: self, forBlog: blog) { [weak self] (title, template) in
            self?.showEditor(blog: blog, title: title, content: template)
        }
    }

    private func showEditor(blog: Blog, title: String?, content: String?) {
        let editorViewController = EditPageViewController(blog: blog, postTitle: title, content: content)
        present(editorViewController, animated: false)
    }
}
