extension WPTabBarController {

    func showBlogDetails(for blog: Blog) {
        mySitesCoordinator.showBlogDetails(for: blog)
    }

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

        if UserDefaults.standard.storiesIntroWasAcknowledged == false {
            // Show Intro screen
            let intro = StoriesIntroViewController(continueTapped: { [weak self] in
                UserDefaults.standard.storiesIntroWasAcknowledged = true
                self?.showStoryEditor()
            }, openURL: { [weak self] url in
                let webViewController = WebViewControllerFactory.controller(url: url, source: "show_story_example")
                let navController = UINavigationController(rootViewController: webViewController)
                self?.presentedViewController?.present(navController, animated: true)
            })

            present(intro, animated: true, completion: {
                StoriesIntroViewController.trackShown()
            })
        } else {
            guard let blog = inBlog ?? self.currentOrLastBlog() else { return }
            let blogID = blog.dotComID?.intValue ?? 0 as Any

            WPAppAnalytics.track(.editorCreatedPost, withProperties: [WPAppAnalyticsKeyTapSource: source, WPAppAnalyticsKeyBlogID: blogID, WPAppAnalyticsKeyEditorSource: "stories", WPAppAnalyticsKeyPostType: "post"])

            do {
                let controller = try StoryEditor.editor(blog: blog, context: ContextManager.shared.mainContext, updated: {_ in })
                present(controller, animated: true, completion: nil)
            } catch {
                assertionFailure("Story editor should not fail since this button is hidden on iPads.")
            }
        }
    }
}
