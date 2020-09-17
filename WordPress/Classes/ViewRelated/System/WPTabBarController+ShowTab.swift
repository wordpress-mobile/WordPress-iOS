var storyService: KanvasStoryService?
let kanvasService = KanvasService()

extension WPTabBarController {

    @objc func showPageEditor(forBlog: Blog? = nil) {
        showPageEditor(blog: forBlog)
    }

    @objc func showStoryEditor(forBlog: Blog? = nil) {
        showStoryEditor(blog: forBlog)
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

        PageCoordinator.showLayoutPickerIfNeeded(from: self, forBlog: blog) { [weak self] template in
            self?.showEditor(blog: blog, title: title, content: template)
        }
    }
    private func showEditor(blog: Blog, title: String?, content: String?) {
        let context = ContextManager.sharedInstance().mainContext
        let postService = PostService(managedObjectContext: context)
        let page = postService.createDraftPage(for: blog)
        page.postTitle = title
        page.content = content

        let editorFactory = EditorFactory()

        let pageViewController = editorFactory.instantiateEditor(
            for: page,
            replaceEditor: { [weak self] (editor, replacement) in
                self?.replaceEditor(editor: editor, replacement: replacement)
        })

        show(pageViewController)
    }

    /// Show the story editor
    /// - Parameter inBlog: Blog to a add a story to. Uses the current or last blog if not provided
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
        WPAnalytics.track(WPAnalyticsEvent.editorCreatedPage, properties: ["tap_source": source, WPAppAnalyticsKeyBlogID: blogID, WPAppAnalyticsKeyPostType: "story"])

        let controller = kanvasService.controller()

        storyService = KanvasStoryService(blog: blog, posted: { [weak self] result in

            switch result {
            case .success(let post):
                let prepublishing = PrepublishingViewController(post: post, identifiers: [.title, .visibility, .schedule, .tags]) { [weak self] post in
//                    publishAction()
                    self?.dismiss(animated: true, completion: nil)
                }
                let prepublishingNavigationController = PrepublishingNavigationController(rootViewController: prepublishing)
                let bottomSheet = BottomSheetViewController(childViewController: prepublishingNavigationController, customHeaderSpacing: 0)
                bottomSheet.show(from: controller.topmostPresentedViewController, sourceView: controller.view)
            case .failure(let error):
                self?.dismiss(animated: true, completion: nil)
                let controller = UIAlertController(title: "Failed to create story", message: "Error: \(error)", preferredStyle: .alert)
                let dismiss = UIAlertAction(title: "Dismiss", style: .default) { _ in
                    controller.dismiss(animated: true, completion: nil)
                }
                controller.addAction(dismiss)
                self?.present(controller, animated: true, completion: nil)
            }
        })
        kanvasService.delegate = storyService
        present(controller, animated: true, completion: nil)
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
