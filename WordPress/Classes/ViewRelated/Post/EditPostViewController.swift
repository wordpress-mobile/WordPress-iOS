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

    private(set) var post:Post?
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

    private var editorModalPresentationStyle: UIModalPresentationStyle?
    private var editorModalTransitionSylte: UIModalTransitionStyle?
    override var modalPresentationStyle: UIModalPresentationStyle
        {
        didSet(newValue) {
            super.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
            editorModalPresentationStyle = newValue
        }
    }
    override var modalTransitionStyle: UIModalTransitionStyle
        {
        didSet(newValue) {
            super.modalTransitionStyle = .CrossDissolve
            editorModalTransitionSylte = newValue
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
    /// - Note: it's likely preferable to use one of the convenience initializers
    private init(post: Post?, blog: Blog?) {
        if let post = post {
            self.post = post
        }
        super.init(nibName: nil, bundle: nil)
        if let blog = blog {
            self.blog = blog
        }
        self.modalPresentationStyle = .FullScreen
        self.modalTransitionStyle = .CrossDissolve
        self.restorationIdentifier = RestorationKey.viewController.rawValue
        self.restorationClass = EditPostViewController.self
    }

    // TODO: make sure state restoration is working
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidAppear(animated: Bool) {
        if (!hasShownEditor) {
            // show postpost, which will be transparent
            postPost.modalPresentationStyle = .FullScreen
            presentViewController(postPost, animated: true) {
                // then show editor
                self.showEditor()
                self.hasShownEditor = true
            }
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
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
        let postToEdit: Post
        if let post = self.post {
            postToEdit = post
        } else {
            let context = ContextManager.sharedInstance().mainContext
            let postService = PostService(managedObjectContext: context)
            postToEdit = postService.createDraftPostForBlog(blog)
            WPAppAnalytics.track(.EditorCreatedPost, withProperties: ["tap_source": "posts_view"], withBlog: blog)
        }

        let postViewController = AztecPostViewController(post: postToEdit)
        let navController = UINavigationController(rootViewController: postViewController)
        navController.modalPresentationStyle = .FullScreen
        return navController
    }

    private func editPostInNewEditor() -> UIViewController {
        let targetPost: Post
        if let post = post {
            targetPost = post
        } else {
            let context = ContextManager.sharedInstance().mainContext
            let postService = PostService(managedObjectContext: context)
            targetPost = postService.createDraftPostForBlog(blog)
            post = targetPost
            WPAppAnalytics.track(.EditorCreatedPost, withProperties: ["tap_source": "posts_view"], withBlog: blog)
        }
        let postViewController = WPPostViewController(post: targetPost, mode: kWPPostViewControllerModeEdit)
        postViewController.isOpenedDirectlyForPhotoPost = openWithMediaPicker

        postViewController.onClose = { [weak self] (viewController, changesSaved) in
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
        let editPostViewController: WPLegacyEditPostViewController

        let targetPost: Post
        if let post = post {
            targetPost = post
        } else {
            let context = ContextManager.sharedInstance().mainContext
            let postService = PostService(managedObjectContext: context)
            targetPost = postService.createDraftPostForBlog(blog)
            WPAppAnalytics.track(.EditorCreatedPost, withProperties: ["tap_source": "posts_view"], withBlog: blog)
        }
        editPostViewController = WPLegacyEditPostViewController(post: targetPost)

        editPostViewController.onClose = { [weak self] in
            self?.closeEditor()
        }

        let navController = UINavigationController(rootViewController: editPostViewController)
        navController.modalPresentationStyle = .FullScreen

        return navController
    }

    func closeEditor(changesSaved: Bool = true) {
        self.onClose?(changesSaved: changesSaved)

        var dismissPostPostImmediately = true
        if shouldShowPostPost(hasChanges: changesSaved), let post = post {
            postPost.setup(post: post)
            postPost.onClose = {
                self.closePostPost()
            }
            postPost.reshowEditor = {
                self.showEditor()
            }
            postPost.preview = {
                self.previewPost()
            }
            dismissPostPostImmediately = false
        }

        self.postPost.dismissViewControllerAnimated(true) {
            if dismissPostPostImmediately {
                self.closePostPost()
            }
        }
    }

    func shouldShowPostPost(hasChanges hasChanges: Bool) -> Bool  {
        guard let post = post else {
            return false
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
            self.postPost.dismissViewControllerAnimated(true) {}
        }
        let navWrapper = UINavigationController(rootViewController: controller)
        postPost.presentViewController(navWrapper, animated: true) {}
    }

    func closePostPost() {
        // dismiss PostPost
        self.dismissViewControllerAnimated(false) {
            // dismiss self
            self.dismissViewControllerAnimated(false) {}
        }
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
        var vc: EditPostViewController
        if let post = post {
            vc = EditPostViewController(post: post)
        } else {
            vc = EditPostViewController()
        }

        return vc
    }

    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        if let post = post {
            coder.encodeObject(post.objectID.URIRepresentation(), forKey: RestorationKey.post.rawValue)
        }
    }
}
