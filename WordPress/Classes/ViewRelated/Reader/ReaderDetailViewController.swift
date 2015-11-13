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
    public var post: ReaderPost?

    private var didBumpStats: Bool = false
    private var didBumpPageViews: Bool = false

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

    }


    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }


    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }


    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }


    public override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        view.layoutIfNeeded()
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


    // MARK: - Configuration

    func configureNavBar() {
        // Don't show 'Reader' in the next-view back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)

        // TODO: ?? do we need this?
        //        [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:self.shareButton forNavigationItem:self.navigationItem];
    }


    func configureDetailView() {

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



}
