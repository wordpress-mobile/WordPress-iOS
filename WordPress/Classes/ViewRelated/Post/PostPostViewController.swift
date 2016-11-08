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
    var post:Post?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

        //actionsStackView.layer.transform = CATransform3DMakeTranslation(0, 10, 0)
        shareButtonWidth.constant = self.shareButton.frame.size.width * -0.75
        editButtonWidth.constant = self.shareButton.frame.size.width * -0.75
        viewButtonWidth.constant = self.shareButton.frame.size.width * -0.75
        view.layoutIfNeeded()
//
//        UIView.animateWithDuration(0.66, delay:0, options:UIViewAnimationOptions.CurveEaseIn, animations: {
//            self.view.alpha = 1
//
//            }, completion: { (success) in
//                self.shareButtonWidth.constant = 0
//                UIView.animateWithDuration(0.6, delay: 0.5, options: UIViewAnimationOptions.CurveLinear, animations: {
//                        //self.actionsStackView.layer.transform = CATransform3DMakeTranslation(0, 0, 0)
//                        self.view.layoutIfNeeded()
//                        self.editButtonWidth.constant = 0
//                        UIView.animateWithDuration(0.6, delay: 0.5, options: UIViewAnimationOptions.CurveLinear, animations: {
//                            self.view.layoutIfNeeded()
//                        }, completion: nil)
//
//                    }, completion: nil)
//
//        })

//        UIView.animateKeyframesWithDuration(0.44, delay: 0, options: UIViewKeyframeAnimationOptions(rawValue: UIViewAnimationOptions.CurveEaseOut.rawValue), animations: {
//            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.5, animations: {
//                self.view.alpha = 1
//            })
//            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.8, animations: {
//                self.shareButton.alpha = 1
//                self.shareButtonWidth.constant = 0
//                self.view.layoutIfNeeded()
//            })
//            UIView.addKeyframeWithRelativeStartTime(0.1, relativeDuration: 0.9, animations: {
//                self.editButton.alpha = 1
//                self.editButtonWidth.constant = 0
//                self.view.layoutIfNeeded()
//            })
//            UIView.addKeyframeWithRelativeStartTime(0.2, relativeDuration: 1.0, animations: {
//                self.viewButton.alpha = 1
//                self.viewButtonWidth.constant = 0
//                self.view.layoutIfNeeded()
//            })
//        }) { (success) in
//
//        }
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

}
