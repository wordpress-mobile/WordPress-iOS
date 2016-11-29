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

    private(set) var post: Post?
    var revealPost = false
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var postStatusLabel:UILabel!
    @IBOutlet var siteIconView:UIImageView!
    @IBOutlet var siteNameLabel:UILabel!
    @IBOutlet var siteUrlLabel:UILabel!
    @IBOutlet var shareButton:UIButton!
    @IBOutlet var editButton:UIButton!
    @IBOutlet var viewButton:UIButton!
    @IBOutlet var navBar:UINavigationBar!
    @IBOutlet var postInfoView:UIView!
    @IBOutlet var actionsStackView:UIStackView!
    @IBOutlet var shadeView:UIView!
    @IBOutlet var shareButtonWidth:NSLayoutConstraint!
    @IBOutlet var editButtonWidth:NSLayoutConstraint!
    @IBOutlet var viewButtonWidth:NSLayoutConstraint!
    var onClose: (() -> ())?
    var reshowEditor: (() -> ())?
    var preview: (() -> ())?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navBar.translucent = true
        navBar.barTintColor = UIColor.clearColor() //WPStyleGuide.wordPressBlue()
        self.view.backgroundColor = WPStyleGuide.wordPressBlue()
        navBar.tintColor = UIColor.whiteColor()
        let clearImage = UIImage(color: UIColor.clearColor(), havingSize: CGSizeMake(320, 4))
        navBar.shadowImage = clearImage
        navBar.setBackgroundImage(clearImage, forBarMetrics: .Default)

        self.view.alpha = 0
        self.shareButton.alpha = 0
        self.editButton.alpha = 0
        self.viewButton.alpha = 0

        if self.revealPost {
            self.view.alpha = 1
            self.shadeView.backgroundColor = UIColor.blackColor()
            self.shadeView.alpha = 0.5
            self.postInfoView.alpha = 0

            shareButtonWidth.constant = self.shareButton.frame.size.width * -0.75
            editButtonWidth.constant = self.shareButton.frame.size.width * -0.75
            viewButtonWidth.constant = self.shareButton.frame.size.width * -0.75
            view.layoutIfNeeded()

            let animationCoordinator = self.transitionCoordinator()
            animationCoordinator?.animateAlongsideTransition({ (context) in
                self.showPostPost(context)
                self.revealPost = false
            }) { (context) in }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    func showPostPost(context: UIViewControllerTransitionCoordinatorContext) {
        let animationDuration = context.transitionDuration()

        self.postInfoView.alpha = 1

        UIView.animateWithDuration(animationDuration, delay: 0, options: .CurveEaseOut, animations: {
            self.shadeView.alpha = 0
            }, completion: nil)

        UIView.animateWithDuration(animationDuration * 0.66, delay: 0, options: .CurveEaseOut, animations: {
            self.postInfoView.alpha = 1
            }, completion: nil)

        UIView.animateWithDuration(0.2, delay: animationDuration * 0.5, options: .CurveEaseOut, animations: {
            self.shareButton.alpha = 1
            self.shareButtonWidth.constant = 0
            self.actionsStackView.layoutIfNeeded()
            }, completion: nil)
        UIView.animateWithDuration(0.2, delay: animationDuration * 0.6, options: .CurveEaseOut, animations: {
            self.editButton.alpha = 1
            self.editButtonWidth.constant = 0
            self.actionsStackView.layoutIfNeeded()
        }, completion: nil)
        UIView.animateWithDuration(0.2, delay: animationDuration * 0.7, options: .CurveEaseOut, animations: {
            self.viewButton.alpha = 1
            self.viewButtonWidth.constant = 0
            self.actionsStackView.layoutIfNeeded()
        }, completion: nil)
    }

    func setup(post post: Post) {
        guard let blogSettings = post.blog.settings else {
            return
        }
        self.post = post

        titleLabel.text = post.titleForDisplay()
        if post.isScheduled() {
            let format = NSLocalizedString("Scheduled for %@ on", comment: "Precedes the name of the blog a post was just scheduled on. Variable is the date post was schedulde for.")
            postStatusLabel.text = String(format: format, post.dateStringForDisplay())
            shareButton.hidden = true
        } else {
            postStatusLabel.text = NSLocalizedString("Published just now on", comment: "Precedes the name of the blog just posted on")
            shareButton.hidden = false
        }
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

        revealPost = true
    }

    @IBAction func shareTapped() {
        guard let post = post else {
            return
        }

        let sharingController = PostSharingController()
        sharingController.sharePost(post, fromView: self.shareButton, inViewController: self)
    }

    @IBAction func editTapped() {
        self.reshowEditor?()
    }

    @IBAction func viewTapped() {
        self.preview?()
        revealPost = true
    }

    @IBAction func doneTapped() {
        self.onClose?()
    }
}
