import Foundation

public class ReaderDetailViewController : UIViewController, UIScrollViewDelegate
{

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


    // MARK: - Properties

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private weak var tagButton: UIButton!
    @IBOutlet private weak var actionButtonRight: UIButton!
    @IBOutlet private weak var actionButtonLeft: UIButton!

    private weak var detailView: ReaderDetailView!

    private var didBumpStats: Bool = false
    private var didBumpPageViews: Bool = false
    public var isLoggedIn: Bool = true


    public var post: ReaderPost? {
        didSet{
            if isViewLoaded() {
                configureView()
            }
        }
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
        //TODO:
//        post?.removeObserver(self, forKeyPath: DetailConstants.LikeCountKeyPath)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    public override func viewDidLoad() {
        super.viewDidLoad()

        // Styles
        WPStyleGuide.applyReaderCardTagButtonStyle(tagButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonLeft)
        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonRight)

        // Is Logged In
        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let account = service.defaultWordPressComAccount()
        isLoggedIn = account != nil

        setupNavBar()
        setupDetailView()

        if post != nil {
            configureView()
        }
    }


    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        resizeDetailView()
    }


    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        resizeDetailView()
    }


    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }


    public override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        view.layoutIfNeeded()
        resizeDetailView()
        // TODO: Refresh media layout
    }


    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (object! as! NSObject == post!) && (keyPath! == DetailConstants.LikeCountKeyPath) {
            // Note: The intent here is to update the action buttons, specifically the
            // like button, *after* both likeCount and isLiked has changed. The order
            // of the properties is important.
            // TODO: Update the view
        }
    }


    // MARK: - Multitasking Splitview Support

    func handleApplicationDidBecomeActive(notification: NSNotification) {
        view.layoutIfNeeded()
        // TODO: Refresh media layout
    }


    // MARK: - Setup

    func setupWithPostID(postID:NSNumber, siteID:NSNumber) {
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


    func setupNavBar() {
        // Don't show 'Reader' in the next-view back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        configureTitle()

        // TODO: ?? do we need this?
        //        [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:self.shareButton forNavigationItem:self.navigationItem];
    }


    func setupDetailView() {
        detailView = NSBundle.mainBundle().loadNibNamed("ReaderDetailView", owner: nil, options: nil).first as! ReaderDetailView
        scrollView.addSubview(detailView)
    }


    // MARK: - Configuration

    func configureView() {
        configureTitle();
        configureTag()
        configureActionButtons()
        configureDetailView()
    }


    func configureDetailView() {
        detailView.configureView(post!)

        resizeDetailView()
    }

    func resizeDetailView() {
        var frame = detailView.frame
        let size = detailView.sizeThatFits(CGSize(width: self.view.frame.width, height: CGFloat.max))
        frame.size.width = size.width
        frame.size.height = size.height
        detailView.frame = frame
        scrollView.contentSize = detailView.sizeThatFits(size)
    }

    private func configureTitle() {
        self.title = (post != nil) ? post?.postTitle : NSLocalizedString("Post", comment:"Placeholder title for ReaderPostDetails.")
    }

    private func configureTag() {
        var tag = ""
        if let rawTag = post?.primaryTag {
            if (rawTag.characters.count > 0) {
                tag = "#\(rawTag)"
            }
        }
        tagButton.hidden = tag.characters.count == 0
        tagButton.setTitle(tag, forState: .Normal)
        tagButton.setTitle(tag, forState: .Highlighted)
    }


    private func configureActionButtons() {

        var buttons = [
            actionButtonLeft,
            actionButtonRight
        ]

        // Show likes if logged in, or if likes exist, but not if external
        if (isLoggedIn || post!.likeCount.integerValue > 0) && !post!.isExternal {
            let button = buttons.removeLast() as UIButton
            configureLikeActionButton(button)
        }

        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom (jetpack and external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        if post!.isWPCom {
            if (isLoggedIn && post!.commentsOpen) || post!.commentCount.integerValue > 0 {
                let button = buttons.removeLast() as UIButton
                configureCommentActionButton(button)
            }
        }

        resetActionButtons(buttons)
    }

    private func resetActionButtons(buttons:[UIButton!]) {
        for button in buttons {
            resetActionButton(button)
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

    private func configureLikeActionButton(button: UIButton) {
        button.tag = CardAction.Like.rawValue
        button.enabled = isLoggedIn

        let title = post!.likeCountForDisplay()
        let imageName = post!.isLiked ? "icon-reader-liked" : "icon-reader-like"
        let image = UIImage(named: imageName)
        let highlightImage = UIImage(named: "icon-reader-like-highlight")
        let selected = post!.isLiked
        configureActionButton(button, title: title, image: image, highlightedImage: highlightImage, selected:selected)
    }

    private func configureCommentActionButton(button: UIButton) {
        button.tag = CardAction.Comment.rawValue
        let title = post?.commentCount.stringValue
        let image = UIImage(named: "icon-reader-comment")
        let highlightImage = UIImage(named: "icon-reader-comment-highlight")
        configureActionButton(button, title: title, image: image, highlightedImage: highlightImage, selected:false)
    }

    // MARK: - Analytics

    func bumpStats() {
        if didBumpStats {
            return
        }
        didBumpStats = true

        let isOfflineView = ReachabilityUtils.isInternetReachable() ? "no" : "yes"
        let detailType = post!.topic.type == ReaderSiteTopic.TopicType ? DetailAnalyticsConstants.TypePreviewSite : DetailAnalyticsConstants.TypeNormal // TODO: this can be an enum instead of string consts in a struct

        let properties = [
            DetailAnalyticsConstants.TypeKey : detailType,
            DetailAnalyticsConstants.OfflineKey : isOfflineView
        ]

        WPAnalytics.track(WPAnalyticsStat.StatReaderArticleOpened, withProperties: properties)
    }


    func bumpPageViewsForPost(postID:NSNumber, siteID:NSNumber, siteURL:String) {
        if (didBumpPageViews) {
            return;
        }
        didBumpPageViews = true;

        // If the user is an admin on the post's site do not bump the page view unless
        // the the post is private.
        if !post!.isPrivate() && isUserAdminOnSiteWithID(post!.siteID) {
            return;
        }

        let site = NSURL(string: siteURL)
        if site?.host == nil {
            return;
        }

        let pixel = "https://pixel.wp.com/g.gif"
        let params:NSArray = [
            "v=wpcom",
            "reader=1",
            "ref=\(DetailAnalyticsConstants.PixelStatReferrer)",
            "host=\(site!.host)",
            "blog=\(siteID)",
            "post=\(postID)",
            NSString(format:"t=%d", arc4random())
        ]

        let path  = NSString(format: "%@?%@", pixel, params.componentsJoinedByString("&"))
        let userAgent = WordPressAppDelegate.sharedInstance().userAgent.currentUserAgent()

        let request = NSMutableURLRequest(URL: NSURL(string: path as String)!)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(DetailAnalyticsConstants.PixelStatReferrer, forKey: "Referer")

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request)
        task.resume()
    }


    func isUserAdminOnSiteWithID(siteID:NSNumber) -> Bool {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        let blog = blogService.blogByBlogId(siteID)
        return blog.isAdmin;
    }



    // MARK: - Actions

    @IBAction func didTapTagButton(sender: UIButton) {
        if post == nil {
            return
        }

        let controller = ReaderStreamViewController.controllerWithTagSlug(post!.primaryTagSlug)
        navigationController?.pushViewController(controller, animated: true)

        let properties = NSDictionary(object: post!.primaryTagSlug, forKey: "tag") as [NSObject : AnyObject]
        WPAnalytics.track(.StatReaderTagPreviewed, withProperties: properties)
    }

    @IBAction func didTapActionButton(sender: UIButton) {
        if post == nil {
            return
        }

        let tag = CardAction(rawValue: sender.tag)!
        switch tag {

        case .Comment :
            // Comment action
            let controller = ReaderCommentsViewController(post: post)
            navigationController?.pushViewController(controller, animated: true)

        case .Like :
            // Like Action
            let service = ReaderPostService(managedObjectContext: post!.managedObjectContext)
            service.toggleLikedForPost(post, success: nil, failure: { (error:NSError?) in
                if let anError = error {
                    DDLogSwift.logError("Error (un)liking post: \(anError.localizedDescription)")
                }
            })
        }
    }
    




    // MARK: - Private Types

    private enum CardAction: Int
    {
        case Comment = 1
        case Like
    }

}
