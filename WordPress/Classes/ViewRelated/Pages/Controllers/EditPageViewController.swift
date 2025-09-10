import UIKit
import SwiftUI
import WordPressData

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
            // Leave the original Page object as an empty draft. Set the page content to the newly created revision.
            // With this setup, the content will be treated as unsaved content.
            let newPage = blog.createDraftPage().createRevision() as! Page
            newPage.content = self.content
            newPage.postTitle = self.postTitle
            self.page = newPage
            return newPage
        }
    }

    fileprivate func showEditor() {
        let page = pageToEdit()
        let editorFactory = EditorFactory()

        // Check if application password is required for this page
        if editorFactory.requiresApplicationPasswordForEditor(post: page) {
            showApplicationPasswordRequired(for: page, editorFactory: editorFactory)
        } else {
            // Proceed with normal editor instantiation
            let editorViewController = editorFactory.instantiateEditor(
                for: page,
                replaceEditor: { [weak self] (editor, replacement) in
                    self?.replaceEditor(editor: editor, replacement: replacement)
            })

            show(editorViewController)
        }
    }

    private func showApplicationPasswordRequired(for page: Page, editorFactory: EditorFactory) {
        let feature = NSLocalizedString(
            "applicationPasswordRequired.feature.blockEditor",
            value: "Block Editor",
            comment: "Feature name for the block editor in application password required prompt"
        )

        let applicationPasswordView = ApplicationPasswordRequiredView(
            blog: page.blog,
            localizedFeatureName: feature,
            presentingViewController: self
        ) { [weak self] client in
            // Once authenticated, dismiss the application password view and show editor
            guard let self else { return EmptyView() }

            let editorViewController = editorFactory.instantiateEditor(
                for: page,
                replaceEditor: { [weak self] (editor, replacement) in
                    self?.replaceEditor(editor: editor, replacement: replacement)
            })

            // Dismiss application password view, then present the editor
            self.dismiss(animated: true) {
                self.show(editorViewController)
            }

            return EmptyView()
        }

        let hostingController = UIHostingController(rootView: applicationPasswordView)

        hostingController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissApplicationPasswordView)
        )

        // Note: Pages use different presentation style than posts
        let navController = UINavigationController(rootViewController: hostingController)
        navController.modalPresentationStyle = .overFullScreen
        navController.modalTransitionStyle = .coverVertical

        present(navController, animated: true)
    }

    @objc private func dismissApplicationPasswordView() {
        // Dismiss the ApplicationPasswordRequiredView, then dismiss the entire EditPageViewController
        // since there's no meaningful content to show without the editor
        dismiss(animated: true) { [weak self] in
            self?.dismiss(animated: true) {
                self?.onClose?()
            }
        }
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
