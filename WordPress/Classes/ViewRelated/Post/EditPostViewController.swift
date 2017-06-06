import UIKit

class EditPostViewController: UIViewController {

    /// appear instantly, without animations
    var showImmediately: Bool = false
    /// appear with the media picker open
    var openWithMediaPicker: Bool = false

    fileprivate(set) var post: Post?
    fileprivate var hasShownEditor = false
    fileprivate var editingExistingPost = false
    fileprivate let blog: Blog
    fileprivate lazy var postPost: PostPostViewController = {
        return UIStoryboard(name: "PostPost", bundle: nil).instantiateViewController(withIdentifier: "PostPostViewController") as! PostPostViewController
    }()

    var onClose: ((_ changesSaved: Bool) -> ())?

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
    convenience init(post: Post) {
        self.init(post: post, blog: post.blog)
    }


    /// Initialize as an editor to create a new post for the provided blog
    ///
    /// - Parameter blog: blog to create a new post for
    convenience init(blog: Blog) {
        self.init(post: nil, blog: blog)
    }

    /// Initialize as an editor with a specified post to edit and blog to post too.
    ///
    /// - Parameters:
    ///   - post: the post to edit
    ///   - blog: the blog to create a post for, if post is nil
    /// - Note: it's preferable to use one of the convenience initializers
    fileprivate init(post: Post?, blog: Blog) {
        self.post = post
        if let post = post {
            if !post.isDraft() {
                editingExistingPost = true
            }
        }
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .coverVertical
        restorationIdentifier = RestorationKey.viewController.rawValue
        restorationClass = EditPostViewController.self

        addChildViewController(postPost)
        view.addSubview(postPost.view)
        postPost.didMove(toParentViewController: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // show postpost, which will be transparent
        view.isOpaque = false
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        if (!hasShownEditor) {
            showEditor()
            hasShownEditor = true
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    fileprivate func postToEdit() -> Post {
        if let post = post {
            return post
        } else {
            let context = ContextManager.sharedInstance().mainContext
            let postService = PostService(managedObjectContext: context)
            let newPost = postService.createDraftPost(for: blog)
            post = newPost
            return newPost
        }
    }

    // MARK: show the editor

    fileprivate func showEditor() {
        let editorSettings = EditorSettings()
        let editor = editorSettings.instantiateEditor(post: postToEdit()) { (editor, vc) in
            editor.isOpenedDirectlyForPhotoPost = openWithMediaPicker
            editor.onClose = { [weak self, weak vc, weak editor] changesSaved in
                guard let strongSelf = self else {
                    vc?.dismiss(animated: true) {}
                    return
                }

                // NOTE:
                // We need to grab the latest Post Reference, since it may have changed (ie. revision / user picked a
                // new blog).
                if changesSaved {
                    strongSelf.post = editor?.post as? Post
                }
                strongSelf.closeEditor(changesSaved)
            }
        }
        // Neutralize iOS's Restoration:
        // We'll relaunch the editor on our own, on viewDidAppear. Why: Because we need to set up the callbacks!
        // This effectively prevents double editor instantiation!
        //
        editor.restorationClass = nil
        editor.restorationIdentifier = nil

        let navController = UINavigationController(rootViewController: editor)
        navController.isToolbarHidden = false // Fixes incorrect toolbar animation.
        navController.modalPresentationStyle = .fullScreen

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        postPost.present(navController, animated: !showImmediately) {
            generator.impactOccurred()
        }
    }

    func closeEditor(_ changesSaved: Bool = true, from presentingViewController: UIViewController? = nil) {
        onClose?(changesSaved)

        var dismissPostPostImmediately = true
        if shouldShowPostPost(hasChanges: changesSaved), let post = post {
            postPost.setup(post: post)
            postPost.onClose = {
                self.closePostPost(animated: true)
            }
            postPost.reshowEditor = {
                self.showEditor()
            }
            postPost.preview = {
                self.previewPost()
            }
            dismissPostPostImmediately = false
        }

        dismiss(animated: true) {
            if dismissPostPostImmediately {
                self.closePostPost(animated: false)
            }
        }
    }

    func shouldShowPostPost(hasChanges: Bool) -> Bool {
        guard let post = post else {
            return false
        }
        if editingExistingPost {
            return false
        }
        if postPost.revealPost {
            return true
        }
        if post.isDraft() {
            return false
        }
        return hasChanges
    }

    func previewPost() {
        guard let post = post else {
            return
        }
        let controller = PostPreviewViewController(post: post)
        controller.hidesBottomBarWhenPushed = true
        controller.onClose = {
            self.dismiss(animated: true) {}
        }
        let navWrapper = UINavigationController(rootViewController: controller)
        postPost.present(navWrapper, animated: true) {}
    }

    func closePostPost(animated: Bool) {
        // will dismiss self
        dismiss(animated: animated) {}
    }
}

// MARK: - State Restoration
//
extension EditPostViewController: UIViewControllerRestoration {
    enum RestorationKey: String {
        case viewController = "EditPostViewControllerRestorationID"
        case post = "EditPostViewControllerPostRestorationID"
    }

    class func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last as? String, identifier == RestorationKey.viewController.rawValue else {
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
