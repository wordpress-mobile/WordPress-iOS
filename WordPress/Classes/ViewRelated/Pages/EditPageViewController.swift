import UIKit

class EditPageViewController: UIViewController {
    fileprivate var page: Page?
    fileprivate var blog: Blog
    fileprivate var postTitle: String?
    fileprivate var content: String?
    fileprivate var hasShownEditor = false

    convenience init(page: Page) {
        self.init(page: page, blog: page.blog, postTitle: nil, content: nil, appliedTemplate: nil)
    }

    convenience init(blog: Blog, postTitle: String?, content: String?, appliedTemplate: String?) {
        self.init(page: nil, blog: blog, postTitle: postTitle, content: content, appliedTemplate: appliedTemplate)
    }

    fileprivate init(page: Page?, blog: Blog, postTitle: String?, content: String?, appliedTemplate: String?) {
        self.page = page
        self.blog = blog
        self.postTitle = postTitle
        self.content = content

        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .coverVertical
        restorationIdentifier = RestorationKey.viewController.rawValue
        restorationClass = EditPageViewController.self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if  !hasShownEditor {
            showEditor()
            hasShownEditor = true
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WPStyleGuide.preferredStatusBarStyle
    }

    fileprivate func pageToEdit() -> Page {
        if let page = self.page {
            return page
        } else {
            let context = ContextManager.sharedInstance().mainContext
            let postService = PostService(managedObjectContext: context)
            let newPage = postService.createDraftPage(for: blog)
            newPage.content = self.content
            newPage.postTitle = self.postTitle
            self.page = newPage
            return newPage
        }
    }

    fileprivate func showEditor() {
        let editorFactory = EditorFactory()

        let editorViewController = editorFactory.instantiateEditor(
            for: self.pageToEdit(),
            replaceEditor: { [weak self] (editor, replacement) in
                self?.replaceEditor(editor: editor, replacement: replacement)
        })

        show(editorViewController)
    }

    private func show(_ editor: EditorViewController) {
        editor.onClose = { [weak self] _, _ in
            // Dismiss navigation controller
            self?.dismiss(animated: true) {
                // Dismiss self
                self?.dismiss(animated: false)
            }
        }

        let navController = AztecNavigationController(rootViewController: editor)
        navController.modalPresentationStyle = .fullScreen

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        present(navController, animated: true) {
            generator.impactOccurred()
        }
    }

    func replaceEditor(editor: EditorViewController, replacement: EditorViewController) {
        editor.dismiss(animated: true) { [weak self] in
            self?.show(replacement)
        }
    }

}


extension EditPageViewController: UIViewControllerRestoration {
    enum RestorationKey: String {
        case viewController = "EditPageViewControllerRestorationID"
        case page = "EditPageViewControllerPageRestorationID"
    }

    class func viewController(withRestorationIdentifierPath identifierComponents: [String],
                              coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last, identifier == RestorationKey.viewController.rawValue else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext

        guard let pageURL = coder.decodeObject(forKey: RestorationKey.page.rawValue) as? URL,
            let pageID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: pageURL),
            let page = try? context.existingObject(with: pageID),
            let reloadedPage = page as? Page
            else {
                return nil
        }

        return EditPageViewController(page: reloadedPage)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        if let page = self.page {
            coder.encode(page.objectID.uriRepresentation(), forKey: RestorationKey.page.rawValue)
        }
    }
}
