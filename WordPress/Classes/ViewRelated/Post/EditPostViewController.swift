import UIKit

class EditPostViewController: UIViewController {

    // MARK: - Editor Factory
    private let editorFactory = EditorFactory()

    // MARK: - Configurations

    /// appear instantly, without animations
    @objc var showImmediately: Bool = false
    /// appear with the post epilogue visible
    @objc var openWithPostPost: Bool = false
    /// appear with media pre-inserted into the post
    var insertedMedia: [Media]? = nil
    /// is editing a reblogged post
    var postIsReblogged = false
    /// the entry point for the editor
    var entryPoint: PostEditorEntryPoint = .unknown

    private let loadAutosaveRevision: Bool

    @objc fileprivate(set) var post: Post?
    private let prompt: BloggingPrompt?
    fileprivate var hasShownEditor = false
    fileprivate var editingExistingPost = false
    fileprivate let blog: Blog
    fileprivate lazy var postPost: PostPostViewController = {
        return UIStoryboard(name: "PostPost", bundle: nil).instantiateViewController(withIdentifier: "PostPostViewController") as! PostPostViewController
    }()

    @objc var onClose: ((_ changesSaved: Bool) -> ())?
    @objc var afterDismiss: (() -> Void)?

    override var modalPresentationStyle: UIModalPresentationStyle {
        didSet(newValue) {
            // make sure this view is transparent with the previous VC visible
            super.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        }
    }
    override var modalTransitionStyle: UIModalTransitionStyle {
        didSet(newValue) {
            super.modalTransitionStyle = .coverVertical
        }
    }

    /// Initialize as an editor with the provided post
    ///
    /// - Parameter post: post to edit
    @objc convenience init(post: Post, loadAutosaveRevision: Bool = false) {
        self.init(post: post, blog: post.blog, loadAutosaveRevision: loadAutosaveRevision)
    }


    /// Initialize as an editor to create a new post for the provided blog
    ///
    /// - Parameter blog: blog to create a new post for
    @objc convenience init(blog: Blog) {
        self.init(post: nil, blog: blog)
    }

    /// Initialize as an editor to create a new post for the provided blog and prompt
    ///
    /// - Parameter blog: blog to create a new post for
    /// - Parameter prompt: blogging prompt to configure the new post for
    convenience init(blog: Blog, prompt: BloggingPrompt) {
        self.init(post: nil, blog: blog, prompt: prompt)
    }

    /// Initialize as an editor with a specified post to edit and blog to post too.
    ///
    /// - Parameters:
    ///   - post: the post to edit
    ///   - blog: the blog to create a post for, if post is nil
    /// - Note: it's preferable to use one of the convenience initializers
    fileprivate init(post: Post?, blog: Blog, loadAutosaveRevision: Bool = false, prompt: BloggingPrompt? = nil) {
        self.post = post
        self.loadAutosaveRevision = loadAutosaveRevision
        if let post = post {
            if !post.originalIsDraft() {
                editingExistingPost = true
            }

            post.fixLocalMediaURLs()
        }
        self.blog = blog
        self.prompt = prompt
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .coverVertical
        restorationIdentifier = RestorationKey.viewController.rawValue
        restorationClass = EditPostViewController.self

        addChild(postPost)
        view.addSubview(postPost.view)
        postPost.didMove(toParent: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // show postpost, which will be transparent
        view.isOpaque = false
        view.backgroundColor = .clear

        if openWithPostPost {
            showPostPost()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !openWithPostPost && !hasShownEditor {
            showEditor()
            hasShownEditor = true
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if openWithPostPost {
            return .darkContent
        } else {
            return WPStyleGuide.preferredStatusBarStyle
        }
    }

    fileprivate func postToEdit() -> Post {
        if let post = post {
            return post
        } else {
            let newPost = blog.createDraftPost()
            newPost.prepareForPrompt(prompt)
            post = newPost
            return newPost
        }
    }

    // MARK: - Show editor by settings and post

    fileprivate func showEditor() {
        let editor = editorFactory.instantiateEditor(
            for: postToEdit(),
            loadAutosaveRevision: loadAutosaveRevision,
            replaceEditor: { [weak self] (editor, replacement) in
                self?.replaceEditor(editor: editor, replacement: replacement)
        })
        editor.postIsReblogged = postIsReblogged
        editor.entryPoint = entryPoint
        showEditor(editor)
    }

    private func showEditor(_ editor: EditorViewController) {
        editor.onClose = { [weak self, weak editor] changesSaved, showPostEpilogue in
            guard let strongSelf = self else {
                editor?.dismiss(animated: true) {}
                return
            }

            // NOTE:
            // We need to grab the latest Post Reference, since it may have changed (ie. revision / user picked a
            // new blog).
            if changesSaved {
                strongSelf.post = editor?.post as? Post
            }
            strongSelf.closeEditor(changesSaved, showPostEpilogue: showPostEpilogue)
        }

        let navController = AztecNavigationController(rootViewController: editor)
        navController.modalPresentationStyle = .fullScreen

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        postPost.present(navController, animated: !showImmediately) {
            generator.impactOccurred()

            if let insertedMedia = self.insertedMedia {
                editor.prepopulateMediaItems(insertedMedia)
            }
        }
    }

    func replaceEditor(editor: EditorViewController, replacement: EditorViewController) {
        replacement.postIsReblogged = postIsReblogged
        editor.dismiss(animated: true) { [weak self] in
            self?.showEditor(replacement)
        }
    }

    @objc func closeEditor(_ changesSaved: Bool = true, showPostEpilogue: Bool, from presentingViewController: UIViewController? = nil) {
        onClose?(changesSaved)

        var dismissPostPostImmediately = true
        if showPostEpilogue && shouldShowPostPost(hasChanges: changesSaved) {
            showPostPost()
            dismissPostPostImmediately = false
        }

        dismiss(animated: true) {
            if dismissPostPostImmediately {
                self.closePostPost(animated: false)
            }
        }
    }

    private func showPostPost() {
        guard let post = post else {
            return
        }

        postPost.setup(post: post)
        postPost.hideEditButton = isPresentingOverEditor()
        postPost.onClose = {
            self.closePostPost(animated: true)
        }
        postPost.reshowEditor = {
            self.showEditor()
        }
        postPost.preview = {
            self.previewPost()
        }
    }

    /// - Returns: `true` if `self` was presented over an existing `EditPostViewController`, otherwise `false`.
    private func isPresentingOverEditor() -> Bool {
        guard
            let aztecNavigationController = presentingViewController as? AztecNavigationController,
            aztecNavigationController.presentingViewController is EditPostViewController
        else {
            return false
        }
        return true
    }

    @objc func shouldShowPostPost(hasChanges: Bool) -> Bool {
        guard let post = post else {
            return false
        }
        if openWithPostPost {
            return true
        }
        if editingExistingPost {
            return false
        }
        if postPost.revealPost {
            return true
        }
        if post.originalIsDraft() {
            return false
        }
        return hasChanges
    }

    @objc func previewPost() {
        guard let post = post else {
            return
        }

        let controller = PreviewWebKitViewController(post: post, source: "edit_post_preview")
        controller.trackOpenEvent()
        let navWrapper = LightNavigationController(rootViewController: controller)
        if postPost.traitCollection.userInterfaceIdiom == .pad {
            navWrapper.modalPresentationStyle = .fullScreen
        }
        postPost.present(navWrapper, animated: true) {}
    }

    @objc func closePostPost(animated: Bool) {
        // this reference is needed in the completion
        let presentingController = self.presentingViewController
        // will dismiss self
        dismiss(animated: animated) { [weak self] in
            guard let self = self else {
                return
            }
            self.afterDismiss?()
            guard let post = self.post,
                  post.isPublished(),
                  !self.editingExistingPost,
                  let controller = presentingController else {
                return
            }

            BloggingRemindersFlow.present(from: controller,
                                          for: self.blog,
                                          source: .publishFlow,
                                          alwaysShow: false)
        }
    }
}

// MARK: - State Restoration
//
extension EditPostViewController: UIViewControllerRestoration {
    enum RestorationKey: String {
        case viewController = "EditPostViewControllerRestorationID"
        case post = "EditPostViewControllerPostRestorationID"
    }

    class func viewController(withRestorationIdentifierPath identifierComponents: [String],
                              coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last, identifier == RestorationKey.viewController.rawValue else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext

        guard let postURL = coder.decodeObject(forKey: RestorationKey.post.rawValue) as? URL,
            let postID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: postURL),
            let post = try? context.existingObject(with: postID),
            let reloadedPost = post as? Post
            else {
                return nil
        }

        return EditPostViewController(post: reloadedPost)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        if let post = post {
            coder.encode(post.objectID.uriRepresentation(), forKey: RestorationKey.post.rawValue)
        }
    }
}
