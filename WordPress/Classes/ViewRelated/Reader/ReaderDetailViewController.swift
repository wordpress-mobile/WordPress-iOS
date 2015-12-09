import Foundation
import WordPressShared
import WordPressComAnalytics

// TODO: Go through our Swift StyleGuide and make sure all conventions are adopted.

final public class ReaderDetailViewController : UIViewController
{
    // TODO: Make sure that changes to analytics in the old VC are applied here
    // after the are merged.


    // Structs for Constants

    private struct DetailConstants
    {
        static let LikeCountKeyPath = "likeCount"
    }


    private struct DetailAnalyticsConstants
    {
        static let TypeKey = "post_detail_type"
        static let TypeNormal = "normal"
        static let TypePreviewSite = "preview_site"
        static let OfflineKey = "offline_view"
        static let PixelStatReferrer = "https://wordpress.com/"
    }


    // MARK: - Properties & Accessors

    @IBOutlet private weak var detailView: ReaderDetailView!
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private weak var tagButton: UIButton!
    @IBOutlet private weak var commentButton: UIButton!
    @IBOutlet private weak var likeButton: UIButton!

    private var didBumpStats: Bool = false
    private var didBumpPageViews: Bool = false
    public var isLoggedIn: Bool = true


    public var post: ReaderPost? {
        didSet {
            oldValue?.removeObserver(self, forKeyPath: DetailConstants.LikeCountKeyPath)

            post?.addObserver(self, forKeyPath: DetailConstants.LikeCountKeyPath, options: .New, context: nil)
            if isViewLoaded() {
                configureView()
            }
        }
    }


    var isLoaded : Bool {
        return post != nil
    }


    // MARK: - Convenience Factories

    /**
     Convenience method for instantiating an instance of ReaderListViewController
     for a particular topic.

     @param topic The reader topic for the list.

     @return A ReaderListViewController instance.
     */
    public class func controllerWithPost(post:ReaderPost) -> ReaderDetailViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderDetailViewController") as! ReaderDetailViewController
        controller.post = post

        return controller
    }


    public class func controllerWithPostID(postID:NSNumber, siteID:NSNumber) -> ReaderDetailViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("ReaderDetailViewController") as! ReaderDetailViewController
        controller.setupWithPostID(postID, siteID:siteID)

        return controller
    }


    // MARK: - LifeCycle Methods

    deinit {
        post?.removeObserver(self, forKeyPath: DetailConstants.LikeCountKeyPath)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    public override func viewDidLoad() {
        super.viewDidLoad()

        // Styles
        WPStyleGuide.applyReaderCardTagButtonStyle(tagButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(commentButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(likeButton)

        // Is Logged In
        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let account = service.defaultWordPressComAccount()
        isLoggedIn = account != nil

        setupNavBar()

        if post != nil {
            configureView()
        }
    }


    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleApplicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }


    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }


    public override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        view.layoutIfNeeded()

        detailView.richTextView.refreshMediaLayout()
    }


    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition(nil, completion: { (context:UIViewControllerTransitionCoordinatorContext) in
            self.detailView.richTextView.refreshMediaLayout()
        })
    }


    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (object! as! NSObject == post!) && (keyPath! == DetailConstants.LikeCountKeyPath) {
            // Note: The intent here is to update the action buttons, specifically the
            // like button, *after* both likeCount and isLiked has changed. The order
            // of the properties is important.
            configureLikeActionButton()
        }
    }


    // MARK: - Multitasking Splitview Support

    private func handleApplicationDidBecomeActive(notification: NSNotification) {
        view.layoutIfNeeded()

        detailView.richTextView.refreshMediaLayout()
    }


    // MARK: - Setup

    private func setupWithPostID(postID:NSNumber, siteID:NSNumber) {
        let title = NSLocalizedString("Loading Post...", comment:"Text displayed while loading a post.")
        WPNoResultsView.displayAnimatedBoxWithTitle(title, message: nil, view: view)

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderPostService(managedObjectContext: context)

        service.fetchPost(
            postID.unsignedIntegerValue,
            forSite: siteID.unsignedIntegerValue,
            success: {[weak self] (post:ReaderPost!) -> Void in
                self?.post = post
                WPNoResultsView.removeFromView(self?.view)
            },
            failure: {[weak self] (error:NSError!) -> Void in
                DDLogSwift.logError("Error fetching post for detail: \(error.localizedDescription)")

                let title = NSLocalizedString("Error Loading Post", comment:"Text displayed when load post fails.")
                WPNoResultsView.displayAnimatedBoxWithTitle(title, message: nil, view: self?.view)
            }
        )
    }


    private func setupNavBar() {
        // Don't show 'Reader' in the next-view back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        configureTitle()
    }


    private func setupAvatarTapGestureRecognizer() {
        //        let tgr = UITapGestureRecognizer(target: self, action: Selector("didTapHeaderAvatar:"))
        //        detailView.avatarImageView.addGestureRecognizer(tgr)
    }


    // MARK: - Configuration

    private func configureView() {
        configureTitle();
        configureTag()
        configureActionButtons()
        configureDetailView()

        bumpStats()
        bumpPageViewsForPost()
    }


    private func configureDetailView() {
        // TODO: logged in features
        detailView.richTextView.delegate = self
        detailView.configureView(post!)
    }


    private func configureTitle() {
        if let postTitle = post?.postTitle {
            self.title = postTitle
        } else {
            self.title = NSLocalizedString("Post", comment:"Placeholder title for ReaderPostDetails.")
        }
    }


    private func configureTag() {
        var tag = ""
        if let rawTag = post?.primaryTag {
            if rawTag.characters.count > 0 {
                tag = "#\(rawTag)"
            }
        }
        tagButton.hidden = tag.characters.count == 0
        tagButton.setTitle(tag, forState: .Normal)
        tagButton.setTitle(tag, forState: .Highlighted)
    }


    private func configureActionButtons() {
        resetActionButton(likeButton)
        resetActionButton(commentButton)

        // Show likes if logged in, or if likes exist, but not if external
        if (isLoggedIn || post!.likeCount.integerValue > 0) && !post!.isExternal {
            configureLikeActionButton()
        }

        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom (jetpack and external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        if post!.isWPCom {
            if (isLoggedIn && post!.commentsOpen) || post!.commentCount.integerValue > 0 {
                configureCommentActionButton()
            }
        }
    }


    private func resetActionButton(button:UIButton) {
        button.setTitle(nil, forState: .Normal)
        button.setTitle(nil, forState: .Highlighted)
        button.setTitle(nil, forState: .Disabled)
        button.setImage(nil, forState: .Normal)
        button.setImage(nil, forState: .Highlighted)
        button.setImage(nil, forState: .Disabled)
        button.selected = false
        button.hidden = true
        button.enabled = true
    }


    private func configureActionButton(button: UIButton, title: String?, image: UIImage?, highlightedImage: UIImage?, selected:Bool) {
        button.setTitle(title, forState: .Normal)
        button.setTitle(title, forState: .Highlighted)
        button.setTitle(title, forState: .Disabled)
        button.setImage(image, forState: .Normal)
        button.setImage(highlightedImage, forState: .Highlighted)
        button.setImage(image, forState: .Disabled)
        button.selected = selected
        button.hidden = false
    }


    private func configureLikeActionButton() {
        likeButton.enabled = isLoggedIn

        let title = post!.likeCountForDisplay()
        let imageName = post!.isLiked ? "icon-reader-liked" : "icon-reader-like"
        let image = UIImage(named: imageName)
        let highlightImage = UIImage(named: "icon-reader-like-highlight")
        let selected = post!.isLiked
        configureActionButton(likeButton, title: title, image: image, highlightedImage: highlightImage, selected:selected)
    }


    private func configureCommentActionButton() {
        let title = post!.commentCount.stringValue
        let image = UIImage(named: "icon-reader-comment")
        let highlightImage = UIImage(named: "icon-reader-comment-highlight")
        configureActionButton(commentButton, title: title, image: image, highlightedImage: highlightImage, selected:false)
    }


    // MARK: - Instance Methods

    func presentWebViewControllerWithURL(url:NSURL) {
        let controller = WPWebViewController.authenticatedWebViewController(url)
        let navController = UINavigationController(rootViewController: controller)
        presentViewController(navController, animated: true, completion: nil)
    }


    func previewSite() {
        let controller = ReaderStreamViewController.controllerWithSiteID(post!.siteID, isFeed: post!.isExternal)
        navigationController?.pushViewController(controller, animated: true)

        // TODO: Duplicated in reader stream. Extract this into a helper method
        let properties = NSDictionary(object: post!.blogURL, forKey: "URL") as [NSObject : AnyObject]
        WPAnalytics.track(.ReaderSitePreviewed, withProperties: properties)
    }


    // MARK: - Analytics

    private func bumpStats() {
        if didBumpStats {
            return
        }
        didBumpStats = true

        let isOfflineView = ReachabilityUtils.isInternetReachable() ? "no" : "yes"
        let detailType = post!.topic?.type == ReaderSiteTopic.TopicType ? DetailAnalyticsConstants.TypePreviewSite : DetailAnalyticsConstants.TypeNormal // TODO: this can be an enum instead of string consts in a struct

        // TODO: Update to latest stats
        let properties = [
            DetailAnalyticsConstants.TypeKey : detailType,
            DetailAnalyticsConstants.OfflineKey : isOfflineView
        ]

        WPAnalytics.track(WPAnalyticsStat.ReaderArticleOpened, withProperties: properties)
    }


    private func bumpPageViewsForPost() {
        if didBumpPageViews || (post!.isExternal && !post!.isJetpack) {
            return;
        }
        didBumpPageViews = true;

        // Don't bump page views for feeds else the wrong blog/post get's bumped
        if post!.isExternal && !post!.isJetpack {
            return;
        }

        // If the user is an admin on the post's site do not bump the page view unless
        // the the post is private.
        if !post!.isPrivate() && isUserAdminOnSiteWithID(post!.siteID) {
            return;
        }

        let site = NSURL(string: post!.blogURL)
        if site?.host == nil {
            return;
        }

        let pixel = "https://pixel.wp.com/g.gif"
        let params:NSArray = [
            "v=wpcom",
            "reader=1",
            "ref=\(DetailAnalyticsConstants.PixelStatReferrer)",
            "host=\(site!.host!)",
            "blog=\(post!.siteID)",
            "post=\(post!.postID)",
            NSString(format:"t=%d", arc4random())
        ]

        let userAgent = WordPressAppDelegate.sharedInstance().userAgent.currentUserAgent()
        let path  = NSString(format: "%@?%@", pixel, params.componentsJoinedByString("&")) as String
        let url = NSURL(string: path)

        let request = NSMutableURLRequest(URL: url!)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue(DetailAnalyticsConstants.PixelStatReferrer, forHTTPHeaderField: "Referer")

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request)
        task.resume()
    }


    private func isUserAdminOnSiteWithID(siteID:NSNumber) -> Bool {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        if let blog = blogService.blogByBlogId(siteID) {
            return blog.isAdmin;
        }
        return false
    }


    // MARK: - Actions

    @IBAction func didTapTagButton(sender: UIButton) {
        // TODO: When should this be a secondary as opposed to a primary tag?
        if !isLoaded {
            return
        }

        let controller = ReaderStreamViewController.controllerWithTagSlug(post!.primaryTagSlug)
        navigationController?.pushViewController(controller, animated: true)

        let properties = NSDictionary(object: post!.primaryTagSlug, forKey: "tag") as [NSObject : AnyObject]
        WPAnalytics.track(.ReaderTagPreviewed, withProperties: properties)
    }


    @IBAction func didTapCommentButton(sender: UIButton) {
        if !isLoaded {
            return
        }

        let controller = ReaderCommentsViewController(post: post)
        navigationController?.pushViewController(controller, animated: true)
    }


    @IBAction func didTapLikeButton(sender: UIButton) {
        if !isLoaded {
            return
        }

        let service = ReaderPostService(managedObjectContext: post!.managedObjectContext)
        service.toggleLikedForPost(post, success: nil, failure: { (error:NSError?) in
            if let anError = error {
                DDLogSwift.logError("Error (un)liking post: \(anError.localizedDescription)")
            }
        })
    }


    func didTapHeaderAvatar(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended {
            // TODO: When should this be disabled?
            previewSite();
        }
    }


    @IBAction func didTapBlogNameButton(sender: UIButton) {
        // TODO: When should this be disabled?
        previewSite()
    }


    @IBAction func didTapMenuButton(sender: UIButton) {
        //TODO: menu wrangling
    }


    func didTapFeaturedImage() {
//TODO:
//        UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
//        UIImageView *imageView = (UIImageView *)gesture.view;
//        WPImageViewController *controller = [[WPImageViewController alloc] initWithImage:imageView.image];
//
//        controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//        controller.modalPresentationStyle = UIModalPresentationFullScreen;
//        [self presentViewController:controller animated:YES completion:nil];

    }


    func didTapDiscoverAttribution() {
// TODO:
//        if (!self.post.sourceAttribution) {
//            return;
//        }
//        if (self.post.sourceAttribution.blogID) {
//            ReaderStreamViewController *controller = [ReaderStreamViewController controllerWithSiteID:self.post.sourceAttribution.blogID isFeed:NO];
//            [self.navigationController pushViewController:controller animated:YES];
//            return;
//        }
//
//        NSString *path;
//        if ([self.post.sourceAttribution.attributionType isEqualToString:SourcePostAttributionTypePost]) {
//            path = self.post.sourceAttribution.permalink;
//        } else {
//            path = self.post.sourceAttribution.blogURL;
//        }
//        NSURL *linkURL = [NSURL URLWithString:path];
//        [self presentWebViewControllerWithLink:linkURL];

    }

}


// MARK: - WPRichTextView Delegate Methods
extension ReaderDetailViewController : WPRichTextViewDelegate {

    public func richTextView(richTextView: WPRichTextView!, didReceiveImageLinkAction imageControl: WPRichTextImage!) {
        var controller: WPImageViewController

        if WPImageViewController.isUrlSupported(imageControl.linkURL) {
            controller = WPImageViewController(image: imageControl.imageView.image, andURL: imageControl.linkURL)

        } else if let linkURL = imageControl.linkURL {
            presentWebViewControllerWithURL(linkURL)
            return

        } else {
            controller = WPImageViewController(image: imageControl.imageView.image)
        }

        controller.modalTransitionStyle = .CrossDissolve
        controller.modalPresentationStyle = .FullScreen

        presentViewController(controller, animated: true, completion: nil)
    }


    public func richTextView(richTextView: WPRichTextView!, didReceiveLinkAction linkURL: NSURL!) {
        var url = linkURL
        if url.host != nil {
            let postURL = NSURL(string: post!.permaLink)
            url = NSURL(string: linkURL.absoluteString, relativeToURL: postURL)
        }
        presentWebViewControllerWithURL(url)
    }

}
