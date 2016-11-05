//
//  PostPostViewController.swift
//  WordPress
//
//  Created by Nate Heagy on 2016-11-02.
//  Copyright © 2016 WordPress. All rights reserved.
//

import UIKit

class PostPostViewController: UIViewController {

    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var siteIconView:UIImageView!
    @IBOutlet var siteNameLabel:UILabel!
    @IBOutlet var siteUrlLabel:UILabel!
    @IBOutlet var shareButton:UIButton!
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
        setupPost()
    }

    func setupPost() {
        guard let post = post, let blogSettings = post.blog.settings else {
            return
        }

        titleLabel.text = post.titleForDisplay()
        siteNameLabel.text = blogSettings.name
        siteUrlLabel.text = post.blog.url
        let isPrivate = !post.blog.visible
        if isPrivate {
            shareButton.hidden = true
        }
    }

    @IBAction func shareTapped() {
//        if ([self.apost isKindOfClass:[Post class]]) {
//            Post *post = (Post *)self.apost;
//
//            PostSharingController *sharingController = [[PostSharingController alloc] init];
//
//            [sharingController sharePost:post fromBarButtonItem:[self shareBarButtonItem] inViewController:self];
//        }
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

        UIView.animateWithDuration(0.5, animations: { 
                self.view.alpha = 0.0
            }) { (success) in
                if self.view.window == appDelegate.testExtraWindow {
                    appDelegate.testExtraWindow.hidden = true
                    appDelegate.testExtraWindow = nil
                }
        }


    }

}
