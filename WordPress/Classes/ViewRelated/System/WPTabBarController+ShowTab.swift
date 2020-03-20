extension WPTabBarController {

    @objc func showPageTab(forBlog blog: Blog) {
        let context = ContextManager.sharedInstance().mainContext
        let postService = PostService(managedObjectContext: context)
        let page = postService.createDraftPage(for: blog)
        WPAppAnalytics.track(.editorCreatedPost, withProperties: ["tap_source": "create_button"], with: blog)

        let editorFactory = EditorFactory()

        let postViewController = editorFactory.instantiateEditor(
            for: page,
            replaceEditor: { [weak self] (editor, replacement) in
                self?.replaceEditor(editor: editor, replacement: replacement)
        })

        show(postViewController)
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
