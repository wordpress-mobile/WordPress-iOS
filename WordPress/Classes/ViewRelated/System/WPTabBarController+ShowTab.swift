extension WPTabBarController {

    @objc func showPageEditor(forBlog: Blog? = nil) {
        showPageEditor(blog: forBlog)
    }

    @objc func showStoryEditor(forBlog: Blog? = nil) {
        showStoryEditor(blog: forBlog)
    }

    /// Show the page tab
    /// - Parameter blog: Blog to a add a page to. Uses the current or last blog if not provided
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
            showEditor(blog: blog, title: title, content: content, templateKey: nil)
            return
        }

        let blogID = blog.dotComID?.intValue ?? 0 as Any
        WPAnalytics.track(WPAnalyticsEvent.editorCreatedPage, properties: [WPAppAnalyticsKeyTapSource: source, WPAppAnalyticsKeyBlogID: blogID, WPAppAnalyticsKeyPostType: "page"])

        PageCoordinator.showLayoutPickerIfNeeded(from: self, forBlog: blog) { [weak self] (selectedLayout) in
            self?.showEditor(blog: blog, title: selectedLayout?.title, content: selectedLayout?.content, templateKey: selectedLayout?.slug)
        }
    }

    private func showEditor(blog: Blog, title: String?, content: String?, templateKey: String?) {
        let editorViewController = EditPageViewController(blog: blog, postTitle: title, content: content, appliedTemplate: templateKey)
        present(editorViewController, animated: false)
    }

    /// Show the story editor
    /// - Parameter blog: Blog to a add a story to. Uses the current or last blog if not provided
    func showStoryEditor(blog inBlog: Blog? = nil, title: String? = nil, content: String? = nil, source: String = "create_button") {
        // If we are already showing a view controller, dismiss and show the editor afterward
        guard presentedViewController == nil else {
            dismiss(animated: true) { [weak self] in
                self?.showStoryEditor(blog: inBlog, title: title, content: content, source: source)
            }
            return
        }

        guard let blog = inBlog ?? self.currentOrLastBlog() else { return }
        let blogID = blog.dotComID?.intValue ?? 0 as Any
        WPAnalytics.track(WPAnalyticsEvent.editorCreatedPage, properties: [WPAppAnalyticsKeyTapSource: source, WPAppAnalyticsKeyBlogID: blogID, WPAppAnalyticsKeyPostType: "story"])

        let controller = UIViewController()
        controller.view.backgroundColor = .white
        present(controller, animated: true, completion: nil)
    }
}
