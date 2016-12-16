import UIKit

class EditPostViewController: UIViewController {

    /// appear instantly, without animations
    var showImmediately: Bool = false
    /// appear with the media picker open
    var openWithMediaPicker: Bool = false

    fileprivate(set) var post: Post?
    fileprivate var hasShownEditor = false
    fileprivate var editingExistingPost = false
    fileprivate(set) lazy var blog:Blog = {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        return blogService!.lastUsedOrFirstBlog()!
    }()
    fileprivate lazy var postPost: PostPostViewController = {
        return UIStoryboard(name: "PostPost", bundle: nil).instantiateViewController(withIdentifier: "PostPostViewController") as! PostPostViewController
    }()

    var onClose: ((_ changesSaved: Bool) -> ())?

    override var modalPresentationStyle: UIModalPresentationStyle
        {
        didSet(newValue) {
            // make sure this view is transparent with the previous VC visible
            super.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        }
    }
    override var modalTransitionStyle: UIModalTransitionStyle
        {
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

    /// Initialize as an editor to create a new post for the last used or default blog
    convenience init() {
        self.init(post: nil, blog: nil)
    }


    /// Initialize as an editor with a specified post to edit and blog to post too.
    ///
    /// - Parameters:
    ///   - post: the post to edit
    ///   - blog: the blog to create a post for, if post is nil
    /// - Note: it's preferable to use one of the convenience initializers
    fileprivate init(post: Post?, blog: Blog?) {
        self.post = post
        if let post = post {
            if !post.isDraft() {
                editingExistingPost = true
            }
        }
        super.init(nibName: nil, bundle: nil)
        if let blog = blog {
            self.blog = blog
        }
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .coverVertical
        restorationIdentifier = RestorationKey.viewController.rawValue
        restorationClass = EditPostViewController.self

        addChildViewController(postPost)
        view.addSubview(postPost.view)
        postPost.didMove(toParentViewController: self)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // show postpost, which will be transparent
        view.isOpaque = false
        view.backgroundColor = UIColor.clear
    }

    override func viewDidAppear(_ animated: Bool) {
        if (!hasShownEditor) {
            showEditor()
            hasShownEditor = true
        }
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    fileprivate func postToEdit() -> Post {
        if let post = post {
            return post
        } else {
            let context = ContextManager.sharedInstance().mainContext
            let postService = PostService(managedObjectContext: context)
            let newPost = postService?.createDraftPost(for: blog)!
            post = newPost
            return newPost!
        }
    }

    // MARK: show the editor

    fileprivate func showEditor() {
        let editorSettings = EditorSettings()
        let editor: UIViewController
        if editorSettings.visualEditorEnabled {
            if editorSettings.nativeEditorEnabled {
                editor = editPostInNativeVisualEditor()
            } else {
                editor = editPostInHybridVisualEditor()
            }
        } else {
            editor = editPostInTextEditor()
        }

        postPost.present(editor, animated: !showImmediately) {
            let generator = WPImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }

    fileprivate func editPostInNativeVisualEditor() -> UIViewController {
        let postViewController = AztecPostViewController(post: postToEdit())
        postViewController.onClose = { [weak self] (changesSaved) in
            self?.closeEditor(changesSaved)
        }

        let navController = UINavigationController(rootViewController: postViewController)
        navController.modalPresentationStyle = .fullScreen

        return navController
    }

    fileprivate func editPostInHybridVisualEditor() -> UIViewController {
        let postViewController = WPPostViewController(post: postToEdit(), mode: kWPPostViewControllerModeEdit)
        postViewController?.isOpenedDirectlyForPhotoPost = openWithMediaPicker
        postViewController?.onClose = { [weak self] (editorVC, changesSaved) in
            guard let strongSelf = self else {
                editorVC?.dismiss(animated: true) {}
                return
            }
            if changesSaved {
                strongSelf.post = editorVC?.post as? Post
            }
            strongSelf.closeEditor(changesSaved)
        }

        let navController = UINavigationController(rootViewController: postViewController!)
        navController.restorationIdentifier = WPEditorNavigationRestorationID
        navController.restorationClass = WPPostViewController.self
        navController.isToolbarHidden = false // Fixes incorrect toolbar animation.
        navController.modalPresentationStyle = .fullScreen

        return navController
    }

    fileprivate func editPostInTextEditor() -> UIViewController {
        let editPostViewController = WPLegacyEditPostViewController(post: postToEdit())
        editPostViewController?.onClose = { [weak self] (editorVC, changesSaved) in
            guard let strongSelf = self else {
                editorVC?.dismiss(animated: true) {}
                return
            }
            if changesSaved {
                strongSelf.post = editorVC?.post as? Post
            }
            strongSelf.closeEditor(changesSaved)
        }

        let navController = UINavigationController(rootViewController: editPostViewController!)
        navController.modalPresentationStyle = .fullScreen

        return navController
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

    func shouldShowPostPost(hasChanges: Bool) -> Bool  {
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
        controller?.hidesBottomBarWhenPushed = true
        controller?.onClose = {
            self.dismiss(animated: true) {}
        }
        let navWrapper = UINavigationController(rootViewController: controller!)
        postPost.present(navWrapper, animated: true) {}
    }

    func closePostPost(animated: Bool) {
        // will dismiss self
        dismiss(animated: animated) {}
    }
}

// MARK: - State Restoration
//
extension EditPostViewController: UIViewControllerRestoration
{
    enum RestorationKey: String {
        case viewController = "EditPostViewControllerRestorationID"
        case post = "EditPostViewControllerPostRestorationID"
    }

    class func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last as? String, identifier == RestorationKey.viewController.rawValue else {
            return nil
        }

        var post: Post?
        if let postURL = coder.decodeObject(forKey: RestorationKey.post.rawValue) as? URL {
            let context = ContextManager.sharedInstance().mainContext
            if let postID = context?.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: postURL) {
                post = context?.object(with: postID) as? Post
            }
        }

        if let post = post {
            return EditPostViewController(post: post)
        } else {
            return EditPostViewController()
        }
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        if let post = post {
            coder.encode(post.objectID.uriRepresentation(), forKey: RestorationKey.post.rawValue)
        }
    }
}
