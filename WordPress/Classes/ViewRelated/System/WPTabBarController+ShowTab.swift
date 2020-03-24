extension WPTabBarController {

    @objc func showPageEditor(forBlog: Blog? = nil) {
        showPageEditor(blog: forBlog)
    }

    /// Show the page tab
    /// - Parameter inBlog: Blog to a add a page to. Uses the current or last blog if not provided
    func showPageEditor(blog inBlog: Blog? = nil, title: String? = nil, content: String? = nil, source: String = "create_button") {

        guard let blog = inBlog ?? self.currentOrLastBlog() else { return }

        let context = ContextManager.sharedInstance().mainContext
        let postService = PostService(managedObjectContext: context)
        let page = postService.createDraftPage(for: blog)
        page.postTitle = title
        page.content = content

        let blogID = blog.dotComID?.intValue ?? 0 as Any
        WPAnalytics.track(WPAnalyticsEvent.editorCreatedPage, properties: ["tap_source": source, WPAppAnalyticsKeyBlogID: blogID])

        let editorFactory = EditorFactory()

        let pageViewController = editorFactory.instantiateEditor(
            for: page,
            replaceEditor: { [weak self] (editor, replacement) in
                self?.replaceEditor(editor: editor, replacement: replacement)
        })

        show(pageViewController)
    }

    private func replaceEditor(editor: EditorViewController, replacement: EditorViewController) {
        editor.dismiss(animated: true) { [weak self] in
            self?.show(replacement)
        }
    }

    private func show(_ editorViewController: EditorViewController) {
        editorViewController.onClose = { [weak editorViewController] _, _ in
            editorViewController?.dismiss(animated: true)
        }

        let navController = UINavigationController(rootViewController: editorViewController)
        navController.restorationIdentifier = Restorer.Identifier.navigationController.rawValue
        navController.modalPresentationStyle = .fullScreen

        present(navController, animated: true, completion: nil)
    }
}
