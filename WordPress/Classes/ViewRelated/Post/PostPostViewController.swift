//
//  PostPostViewController.swift
//  WordPress
//
//  Created by Nate Heagy on 2016-11-02.
//  Copyright © 2016 WordPress. All rights reserved.
//

import UIKit
import WordPressShared

class PostPostViewController: UIViewController {

    private(set) var post:Post?
    private(set) var blog:Blog

    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var siteIconView:UIImageView!
    @IBOutlet var siteNameLabel:UILabel!
    @IBOutlet var siteUrlLabel:UILabel!
    @IBOutlet var shareButton:UIButton!
    @IBOutlet var editButton:UIButton!
    @IBOutlet var viewButton:UIButton!
    @IBOutlet var navBar:UINavigationBar!
    @IBOutlet var actionsStackView:UIStackView!
    @IBOutlet var shareButtonWidth:NSLayoutConstraint!
    @IBOutlet var editButtonWidth:NSLayoutConstraint!
    @IBOutlet var viewButtonWidth:NSLayoutConstraint!

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
    init(post: Post) {
        self.post = post
        self.blog = post.blog
        super.init(nibName: nil, bundle: nil)
    }


    /// Initialize as an editor to create a new post for the provided blog
    ///
    /// - Parameter blog: blog to create a new post for
    init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    /// Initialize as an editor to create a new post for the last used or default blog
    init() {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        blog = blogService.lastUsedOrFirstBlog()!
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        blog = blogService.lastUsedOrFirstBlog()!
        super.init(coder: coder)
    }

    private func defaultBlog() -> Blog {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        return blogService.lastUsedOrFirstBlog()!
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setupPost()

        navBar.barTintColor = WPStyleGuide.wordPressBlue()
        self.view.backgroundColor = WPStyleGuide.wordPressBlue()
        navBar.tintColor = UIColor.whiteColor()
        let clearImage = UIImage(color: UIColor.clearColor(), havingSize: CGSizeMake(320, 4))
        navBar.shadowImage = clearImage
        navBar.setBackgroundImage(clearImage, forBarMetrics: .Default)

        self.view.alpha = 0
        self.shareButton.alpha = 0
        self.editButton.alpha = 0
        self.viewButton.alpha = 0
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showEditor()
    }

    func showPostPost() {
        //actionsStackView.layer.transform = CATransform3DMakeTranslation(0, 10, 0)
        shareButtonWidth.constant = self.shareButton.frame.size.width * -0.75
        editButtonWidth.constant = self.shareButton.frame.size.width * -0.75
        viewButtonWidth.constant = self.shareButton.frame.size.width * -0.75
        view.layoutIfNeeded()

        UIView.animateWithDuration(0.33, delay: 0.1, options: .CurveEaseOut, animations: {
            self.view.alpha = 1
            }, completion: nil)
        UIView.animateWithDuration(0.33, delay: 0.3, options: .CurveEaseOut, animations: {
            self.shareButton.alpha = 1
            self.shareButtonWidth.constant = 0
            self.view.layoutIfNeeded()
            }, completion: nil)
        UIView.animateWithDuration(0.33, delay: 0.4, options: .CurveEaseOut, animations: {
            self.editButton.alpha = 1
            self.editButtonWidth.constant = 0
            self.view.layoutIfNeeded()
            }, completion: nil)
        UIView.animateWithDuration(0.33, delay: 0.5, options: .CurveEaseOut, animations: {
            self.viewButton.alpha = 1
            self.viewButtonWidth.constant = 0
            self.view.layoutIfNeeded()
            }, completion: nil)
    }

    override func prefersStatusBarHidden() -> Bool {
        return false
    }

    func setupPost() {
        guard let post = post, let blogSettings = post.blog.settings else {
            return
        }

        titleLabel.text = post.titleForDisplay()
        siteNameLabel.text = blogSettings.name
        siteUrlLabel.text = post.blog.url
        if let icon = post.blog.icon {
            siteIconView.setImageWithSiteIcon(icon)
        } else {
            siteIconView.superview?.hidden = true
        }
        let isPrivate = !post.blog.visible
        if isPrivate {
            shareButton.hidden = true
        }
    }

    @IBAction func shareTapped() {
        guard let post = post else {
            return
        }

        let sharingController = PostSharingController()
        sharingController.sharePost(post, fromView: self.shareButton, inViewController: self)
    }

    @IBAction func editTapped() {
    }

    @IBAction func viewTapped() {
    }

    @IBAction func doneTapped() {
        guard let appDelegate = UIApplication.sharedApplication().delegate as? WordPressAppDelegate else {
            return
        }

        UIView.animateWithDuration(0.66, animations: {
                self.view.alpha = 0.0
            }) { (success) in
                if self.view.window == appDelegate.secondaryWindow {
                    appDelegate.secondaryWindow.hidden = true
                    appDelegate.secondaryWindow = nil
                }
        }
    }

    // MARK:

    func showEditor() {
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

        presentViewController(editor, animated: true) {
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

        let postViewController: WPPostViewController
        if let post = post {
            postViewController = WPPostViewController(post: post, mode: kWPPostViewControllerModeEdit)
        } else {
            postViewController = WPPostViewController(draftForBlog: blog)
            WPAppAnalytics.track(.EditorCreatedPost, withProperties: ["tap_source": "posts_view"], withBlog: blog)
        }

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
        if let post = post {
            editPostViewController = WPLegacyEditPostViewController(post: post)
        } else {
            editPostViewController = WPLegacyEditPostViewController(draftForLastUsedBlog: ())
            WPAppAnalytics.track(.EditorCreatedPost, withProperties: ["tap_source": "posts_view"], withBlog: blog)
        }

        editPostViewController.onClose = { [weak self] in
            self?.closeEditor()
        }

        let navController = UINavigationController(rootViewController: editPostViewController)
        navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID
        navController.restorationClass = WPLegacyEditPostViewController.self
        navController.modalPresentationStyle = .FullScreen

        return navController
    }

    private func closeEditor(changesSaved: Bool = true) {
        self.onClose?(changesSaved: changesSaved)

        setupPost()
    }
}
