import UIKit

class EditPageViewController: UIViewController {
    var entryPoint: PostEditorEntryPoint = .unknown
    fileprivate var page: Page?
    fileprivate var blog: Blog
    fileprivate var postTitle: String?
    fileprivate var content: String?
    fileprivate var hasShownEditor = false
    var onClose: (() -> Void)?

    convenience init(page: Page) {
        self.init(page: page, blog: page.blog, postTitle: nil, content: nil)
    }

    convenience init(blog: Blog, postTitle: String?, content: String?) {
        self.init(page: nil, blog: blog, postTitle: postTitle, content: content)
    }

    fileprivate init(page: Page?, blog: Blog, postTitle: String?, content: String?) {
        self.page = page
        self.blog = blog
        self.postTitle = postTitle
        self.content = content

        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .coverVertical
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

    fileprivate func pageToEdit() -> Page {
        if let page = self.page {
            return page
        } else {
            let newPage = blog.createDraftPage()
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
        editor.entryPoint = entryPoint
        editor.onClose = { [weak self] in
            // Dismiss navigation controller
            self?.dismiss(animated: true) {
                // Dismiss self
                self?.dismiss(animated: false) {
                    // Invoke completion
                    self?.onClose?()
                }
            }
        }

        let navController = AztecNavigationController(rootViewController: editor)
        navController.modalPresentationStyle = .fullScreen
        navController.view.backgroundColor = .systemBackground

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        present(navController, animated: true) {
            if !(editor is NewGutenbergViewController) {
                generator.impactOccurred()
            }
        }
    }

    func replaceEditor(editor: EditorViewController, replacement: EditorViewController) {
        editor.dismiss(animated: true) { [weak self] in
            self?.show(replacement)
        }
    }

}
