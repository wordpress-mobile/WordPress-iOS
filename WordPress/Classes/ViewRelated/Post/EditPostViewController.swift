//
//  EdiPostViewController.swift
//  WordPress
//
//  Created by Nate Heagy on 2016-11-10.
//  Copyright © 2016 WordPress. All rights reserved.
//

import UIKit

class EditPostViewController: UIViewController {

    /// appear instantly, without animations
    var showImmediately: Bool = false
    /// appear with the media picker open
    var openWithMediaPicker: Bool = false

    private(set) var post: Post?
    private var hasShownEditor = false
    private(set) lazy var blog:Blog = {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        return blogService.lastUsedOrFirstBlog()!
    }()
    private lazy var postPost: PostPostViewController = {
        return UIStoryboard(name: "PostPost", bundle: nil).instantiateViewControllerWithIdentifier("PostPostViewController") as! PostPostViewController
    }()

    var onClose: ((changesSaved: Bool) -> ())?

    override var modalPresentationStyle: UIModalPresentationStyle
        {
        didSet(newValue) {
            // make sure this view is transparent with the previous VC visible
            super.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
        }
    }
    override var modalTransitionStyle: UIModalTransitionStyle
        {
        didSet(newValue) {
            super.modalTransitionStyle = .CoverVertical
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
    private init(post: Post?, blog: Blog?) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
        if let blog = blog {
            self.blog = blog
        }
        modalPresentationStyle = .FullScreen
        modalTransitionStyle = .CoverVertical
        restorationIdentifier = RestorationKey.viewController.rawValue
        restorationClass = EditPostViewController.self

        addChildViewController(postPost)
        view.addSubview(postPost.view)
        postPost.didMoveToParentViewController(self)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // show postpost, which will be transparent
        view.opaque = false
        view.backgroundColor = UIColor.clearColor()
    }

    override func viewDidAppear(animated: Bool) {
        if (!hasShownEditor) {
            showEditor()
            hasShownEditor = true
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    private func postToEdit() -> Post {
        if let post = post {
            return post
        } else {
            let context = ContextManager.sharedInstance().mainContext
            let postService = PostService(managedObjectContext: context)
            let newPost = postService.createDraftPostForBlog(blog)!
            post = newPost
            return newPost
        }
    }

    // MARK: show the editor

    private func showEditor() {
        let editorSettings = EditorSettings()
        let editor: UIViewController
        if editorSettings.visualEditorEnabled {
            if editorSettings.nativeEditorEnabled {
                editor = editPostInNativeEditor()
            } else {
                editor = editPostInNewEditor()
            }
        } else {
            editor = editPostInOldEditor()
        }

        postPost.presentViewController(editor, animated: !showImmediately) {
            let generator = WPImpactFeedbackGenerator(style: .Medium)
            generator.impactOccurred()
        }
    }

    private func editPostInNativeEditor() -> UIViewController {
        let postViewController = AztecPostViewController(post: postToEdit())
        postViewController.onClose = { [weak self] (changesSaved) in
            self?.closeEditor(changesSaved)
        }

        let navController = UINavigationController(rootViewController: postViewController)
        navController.modalPresentationStyle = .FullScreen

        return navController
    }

    private func editPostInNewEditor() -> UIViewController {
        let postViewController = WPPostViewController(post: postToEdit(), mode: kWPPostViewControllerModeEdit)
        postViewController.isOpenedDirectlyForPhotoPost = openWithMediaPicker
        postViewController.onClose = { [weak self] (_, changesSaved) in
            self?.closeEditor(changesSaved)
        }

        let navController = UINavigationController(rootViewController: postViewController)
        navController.restorationIdentifier = WPEditorNavigationRestorationID
        navController.restorationClass = WPPostViewController.self
        navController.toolbarHidden = false // Fixes incorrect toolbar animation.
        navController.modalPresentationStyle = .FullScreen

        return navController
    }

    private func editPostInOldEditor() -> UIViewController {
        let editPostViewController = WPLegacyEditPostViewController(post: postToEdit())
        editPostViewController.onClose = { [weak self] in
            self?.closeEditor()
        }

        let navController = UINavigationController(rootViewController: editPostViewController)
        navController.modalPresentationStyle = .FullScreen

        return navController
    }

    func closeEditor(changesSaved: Bool = true, from presentingViewController: UIViewController? = nil) {
        onClose?(changesSaved: changesSaved)

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

        dismissViewControllerAnimated(true) {
            if dismissPostPostImmediately {
                self.closePostPost(animated: false)
            }
        }
    }

    func shouldShowPostPost(hasChanges hasChanges: Bool) -> Bool  {
        guard let post = post else {
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
            self.dismissViewControllerAnimated(true) {}
        }
        let navWrapper = UINavigationController(rootViewController: controller)
        postPost.presentViewController(navWrapper, animated: true) {}
    }

    func closePostPost(animated animated: Bool) {
        // will dismiss self
        dismissViewControllerAnimated(animated) {}
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

    class func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last as? String where identifier == RestorationKey.viewController.rawValue else {
            return nil
        }

        var post: Post?
        if let postURL = coder.decodeObjectForKey(RestorationKey.post.rawValue) as? NSURL {
            let context = ContextManager.sharedInstance().mainContext
            if let postID = context.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(postURL) {
                post = context.objectWithID(postID) as? Post
            }
        }

        if let post = post {
            return EditPostViewController(post: post)
        } else {
            return EditPostViewController()
        }
    }

    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        if let post = post {
            coder.encodeObject(post.objectID.URIRepresentation(), forKey: RestorationKey.post.rawValue)
        }
    }
}
