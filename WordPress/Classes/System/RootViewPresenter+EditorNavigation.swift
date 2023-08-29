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

    func showPostTab(animated: Bool,
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
        editor.afterDismiss = afterDismiss

        let properties = [WPAppAnalyticsKeyTapSource: "create_button", WPAppAnalyticsKeyPostType: "post"]
        WPAppAnalytics.track(.editorCreatedPost, withProperties: properties, with: blog)
        rootViewController.present(editor, animated: false)
    }

    func showPageEditor(forBlog: Blog? = nil) {
        showPageEditor(blog: forBlog)
    }

    func showStoryEditor(forBlog: Blog? = nil) {
        showStoryEditor(blog: forBlog)
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
            showEditor(blog: blog, title: title, content: content, templateKey: nil)
            return
        }

        WPAnalytics.track(WPAnalyticsEvent.editorCreatedPage,
                          properties: [WPAppAnalyticsKeyTapSource: source],
                          blog: blog)
        PageCoordinator.showLayoutPickerIfNeeded(from: rootViewController, forBlog: blog) { [weak self] (selectedLayout) in
            self?.showEditor(blog: blog, title: selectedLayout?.title, content: selectedLayout?.content, templateKey: selectedLayout?.slug)
        }
    }

    private func showEditor(blog: Blog, title: String?, content: String?, templateKey: String?) {
        let editorViewController = EditPageViewController(blog: blog, postTitle: title, content: content, appliedTemplate: templateKey)
        rootViewController.present(editorViewController, animated: false)
    }

    /// Show the story editor
    /// - Parameter blog: Blog to a add a story to. Uses the current or last blog if not provided
    func showStoryEditor(blog inBlog: Blog? = nil, title: String? = nil, content: String? = nil, source: String = "create_button") {
        // If we are already showing a view controller, dismiss and show the editor afterward
        guard rootViewController.presentedViewController == nil else {
            rootViewController.dismiss(animated: true) { [weak self] in
                self?.showStoryEditor(blog: inBlog, title: title, content: content, source: source)
            }
            return
        }

        if UserPersistentStoreFactory.instance().storiesIntroWasAcknowledged == false {
            // Show Intro screen
            let intro = StoriesIntroViewController(continueTapped: { [weak self] in
                UserPersistentStoreFactory.instance().storiesIntroWasAcknowledged = true
                self?.showStoryEditor()
            }, openURL: { [weak self] url in
                let webViewController = WebViewControllerFactory.controller(url: url, source: "show_story_example")
                let navController = UINavigationController(rootViewController: webViewController)
                self?.rootViewController.presentedViewController?.present(navController, animated: true)
            })

            rootViewController.present(intro, animated: true, completion: {
                StoriesIntroViewController.trackShown()
            })
        } else {
            guard let blog = inBlog ?? self.currentOrLastBlog() else { return }
            let blogID = blog.dotComID?.intValue ?? 0 as Any

            WPAppAnalytics.track(.editorCreatedPost, withProperties: [WPAppAnalyticsKeyTapSource: source, WPAppAnalyticsKeyBlogID: blogID, WPAppAnalyticsKeyEditorSource: "stories", WPAppAnalyticsKeyPostType: "post"])

            do {
                let controller = try StoryEditor.editor(blog: blog, context: ContextManager.shared.mainContext, updated: {_ in })
                rootViewController.present(controller, animated: true, completion: nil)
            } catch {
                assertionFailure("Story editor should not fail since this button is hidden on iPads.")
            }
        }
    }
}
