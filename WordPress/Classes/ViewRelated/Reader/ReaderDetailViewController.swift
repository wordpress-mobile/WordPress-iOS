import Foundation
import WordPressShared
import WordPressComAnalytics


final public class ReaderDetailViewController : UIViewController
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


    // MARK: - Properties & Accessors

    // Footer views
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private weak var tagButton: UIButton!
    @IBOutlet private weak var commentButton: UIButton!
    @IBOutlet private weak var likeButton: UIButton!
    @IBOutlet private weak var footerViewHeightConstraint: NSLayoutConstraint!

    // Wrapper views
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var contentStackView: UIStackView!

    // Header realated Views
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var blavatarImageView: UIImageView!
    @IBOutlet private weak var blogNameButton: UIButton!
    @IBOutlet private weak var blogURLLabel: UILabel!
    @IBOutlet private weak var menuButton: UIButton!

    // Content views
    @IBOutlet private weak var featuredImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var bylineView: UIView!
    @IBOutlet private weak var avatarImageView: CircularImageView!
    @IBOutlet private weak var bylineLabel: UILabel!
    @IBOutlet private weak var richTextView: WPRichTextView!
    @IBOutlet private weak var attributionView: ReaderCardDiscoverAttributionView!

    // Spacers
    @IBOutlet private weak var featuredImageBottomPaddingView: UIView!
    @IBOutlet private weak var titleBottomPaddingView: UIView!
    @IBOutlet private weak var bylineBottomPaddingView: UIView!
    @IBOutlet private weak var richtTextBottomPaddingView: UIView!

    public var shouldHideComments = false
    private var didBumpStats = false
    private var didBumpPageViews = false
    private var footerViewHeightConstraintConstant = CGFloat(0.0)

    public var post: ReaderPost? {
        didSet {
            oldValue?.removeObserver(self, forKeyPath: DetailConstants.LikeCountKeyPath)

            post?.addObserver(self, forKeyPath: DetailConstants.LikeCountKeyPath, options: .New, context: nil)
            if isViewLoaded() {
                configureView()
            }
        }
    }


    private var isLoaded : Bool {
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
        scrollView.alpha = 0
        footerView.hidden = true

        // Hide the featured image and its padding until we know there is one to load.
        featuredImageView.hidden = true
        featuredImageBottomPaddingView.hidden = true

        // Styles
        applyStyles()

        setupNavBar()

        if post != nil {
            configureView()
        }
    }


    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // The UIApplicationDidBecomeActiveNotification notification is broadcast
        // when the app is resumed as a part of split screen multitasking on the iPad.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ReaderDetailViewController.handleApplicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }


    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        setBarsHidden(false)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }


    public override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // This is something we do to help with the resizing that can occur with 
        // split screen multitasking on the iPad.
        view.layoutIfNeeded()

        richTextView.refreshLayout()

    }


    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        // Make sure that the bars are visible after switching from landscape
        // to portrait orientation.  The content might have been scrollable in landscape
        // orientation, but it might not be in portrait orientation. We'll assume the bars
        // should be visible for safety sake and for performance since WPRichTextView updates
        // its intrinsicContentSize too late for get an accurate scrollWiew.contentSize
        // in the completion handler below.
        if size.height > size.width {
            self.setBarsHidden(false)
        }

        // The image frames in the WPRichTextView are a little bit dumb about their
        // resizing after an orientation change. Use the completion block to 
        // refresh media layout.
        coordinator.animateAlongsideTransition(nil) { (_) in
            self.richTextView.refreshLayout()
        }
    }


    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (object! as! NSObject == post!) && (keyPath! == DetailConstants.LikeCountKeyPath) {
            // Note: The intent here is to update the action buttons, specifically the
            // like button, *after* both likeCount and isLiked has changed. The order
            // of the properties is important.
            configureLikeActionButton(true)
        }
    }


    // MARK: - Multitasking Splitview Support

    func handleApplicationDidBecomeActive(notification: NSNotification) {
        view.layoutIfNeeded()

        // Refresh media layout as our sizing may have changed if the user expanded
        // or shrank the split screen handle.
        richTextView.refreshLayout()
    }


    // MARK: - Setup

    public func setupWithPostID(postID:NSNumber, siteID:NSNumber) {
        let title = NSLocalizedString("Loading Post...", comment:"Text displayed while loading a post.")
        WPNoResultsView.displayAnimatedBoxWithTitle(title, message: nil, view: view)

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderPostService(managedObjectContext: context)

        service.fetchPost(
            postID.unsignedIntegerValue,
            forSite: siteID.unsignedIntegerValue,
            success: {[weak self] (post:ReaderPost!) in
                self?.post = post
                WPNoResultsView.removeFromView(self?.view)
            },
            failure: {[weak self] (error:NSError!) in
                DDLogSwift.logError("Error fetching post for detail: \(error.localizedDescription)")

                let title = NSLocalizedString("Error Loading Post", comment:"Text displayed when load post fails.")
                WPNoResultsView.displayAnimatedBoxWithTitle(title, message: nil, view: self?.view)
            }
        )
    }


    private func setupNavBar() {
        configureNavTitle()

        // Don't show 'Reader' in the next-view back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
    }


    // MARK: - Configuration

    /**
    Applies the default styles to the cell's subviews
    */
    private func applyStyles() {
        WPStyleGuide.applyReaderCardSiteButtonStyle(blogNameButton)
        WPStyleGuide.applyReaderCardBylineLabelStyle(bylineLabel)
        WPStyleGuide.applyReaderCardBylineLabelStyle(blogURLLabel)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)
        WPStyleGuide.applyReaderCardTagButtonStyle(tagButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(commentButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(likeButton)
    }


    private func configureView() {
        scrollView.alpha = 1
        configureNavTitle()
        configureShareButton()
        configureHeader()
        configureFeaturedImage()
        configureTitle()
        configureByLine()
        configureRichText()
        configureDiscoverAttribution()
        configureTag()
        configureActionButtons()
        configureFooterIfNeeded()

        bumpStats()
        bumpPageViewsForPost()

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(ReaderDetailViewController.handleBlockSiteNotification(_:)),
            name: ReaderPostMenu.BlockSiteNotification,
            object: nil)
    }


    private func configureNavTitle() {
        let placeholder = NSLocalizedString("Post", comment:"Placeholder title for ReaderPostDetails.")
        self.title = post?.postTitle ?? placeholder
    }


    private func configureShareButton() {
        // Share button.
        let image = UIImage(named: "icon-posts-share")!
        let button = CustomHighlightButton(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: #selector(ReaderDetailViewController.didTapShareButton(_:)), forControlEvents: .TouchUpInside)

        let shareButton = UIBarButtonItem(customView: button)
        shareButton.accessibilityLabel = NSLocalizedString("Share", comment:"Spoken accessibility label")
        WPStyleGuide.setRightBarButtonItemWithCorrectSpacing(shareButton, forNavigationItem: navigationItem)
    }


    private func configureHeader() {
        // Blavatar
        let placeholder = UIImage(named: "post-blavatar-placeholder")
        let size = blavatarImageView.frame.size.width * UIScreen.mainScreen().scale
        let url = post?.siteIconForDisplayOfSize(Int(size))
        blavatarImageView.setImageWithURL(url!, placeholderImage: placeholder)

        // Site name
        let blogName = post?.blogNameForDisplay()
        blogNameButton.setTitle(blogName, forState: .Normal)
        blogNameButton.setTitle(blogName, forState: .Highlighted)
        blogNameButton.setTitle(blogName, forState: .Disabled)

        // Enable button only if not previewing a site.
        if let topic = post!.topic {
            blogNameButton.enabled = !ReaderHelpers.isTopicSite(topic)
        }

        // If the button is enabled also listen for taps on the avatar.
        if blogNameButton.enabled {
            let tgr = UITapGestureRecognizer(target: self, action: #selector(ReaderDetailViewController.didTapHeaderAvatar(_:)))
            blavatarImageView.addGestureRecognizer(tgr)
        }

        if let siteURL:NSString = post!.siteURLForDisplay() {
            blogURLLabel.text = siteURL.componentsSeparatedByString("//").last
        }
    }


    private func configureFeaturedImage() {
        var url = post!.featuredImageURLForDisplay()

        guard url != nil else {
            return
        }

        // Do not display the featured image if it exists in the content.
        if post!.contentIncludesFeaturedImage() {
            return
        }

        var request: NSURLRequest

        if !(post!.isPrivate()) {
            let size = CGSize(width:featuredImageView.frame.width, height:0)
            url = PhotonImageURLHelper.photonURLWithSize(size, forImageURL: url)
            request = NSURLRequest(URL: url)

        } else if (url.host != nil) && url.host!.hasSuffix("wordpress.com") {
            // private wpcom image needs special handling.
            request = requestForURL(url)

        } else {
            // private but not a wpcom hosted image
            request = NSURLRequest(URL: url)
        }

        // Define a success block to make the image visible and update its aspect ratio constraint
        let successBlock : ((NSURLRequest, NSHTTPURLResponse?, UIImage) -> Void) = { [weak self] (request:NSURLRequest, response:NSHTTPURLResponse?, image:UIImage) in
            guard self != nil else {
                return
            }

            self!.configureFeaturedImageWithImage(image)
        }

        featuredImageView.setImageWithURLRequest(request, placeholderImage: nil, success: successBlock, failure: nil)
    }


    private func configureFeaturedImageWithImage(image: UIImage) {
        // Unhide the views
        featuredImageView.hidden = false
        featuredImageBottomPaddingView.hidden = false

        // Now that we have the image, create an aspect ratio constraint for
        // the featuredImageView
        let ratio = image.size.width / image.size.height
        let constraint = NSLayoutConstraint(item: featuredImageView,
            attribute: .Width,
            relatedBy: .Equal,
            toItem: featuredImageView,
            attribute: .Height,
            multiplier: ratio,
            constant: 0)
        constraint.priority = UILayoutPriorityDefaultHigh
        featuredImageView.addConstraint(constraint)
        featuredImageView.setNeedsUpdateConstraints()
        featuredImageView.image = image

        // Listen for taps so we can display the image detail
        let tgr = UITapGestureRecognizer(target: self, action: #selector(ReaderDetailViewController.didTapFeaturedImage(_:)))
        featuredImageView.addGestureRecognizer(tgr)
    }


    private func requestForURL(url:NSURL) -> NSURLRequest {
        var requestURL = url

        let absoluteString = requestURL.absoluteString
        if !absoluteString.hasPrefix("https") {
            let sslURL = absoluteString.stringByReplacingOccurrencesOfString("http", withString: "https")
            requestURL = NSURL(string: sslURL)!
        }

        let request = NSMutableURLRequest(URL: requestURL)

        let acctServ = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        if let account = acctServ.defaultWordPressComAccount() {
            let token = account.authToken
            let headerValue = String(format: "Bearer %@", token)
            request.addValue(headerValue, forHTTPHeaderField: "Authorization")
        }

        return request
    }


    private func configureTitle() {
        if let title = post?.titleForDisplay() {
            let attributes = WPStyleGuide.readerDetailTitleAttributes() as! [String: AnyObject]
            titleLabel.attributedText = NSAttributedString(string: title, attributes: attributes)
            titleLabel.hidden = false

        } else {
            titleLabel.attributedText = nil
            titleLabel.hidden = true
        }
    }
    

    private func configureByLine() {
        // Avatar
        let placeholder = UIImage(named: "gravatar")
        if let url = NSURL(string: post!.authorAvatarURL) {
            avatarImageView.setImageWithURL(url, placeholderImage: placeholder)
        }

        // Byline
        var byline = post?.dateForDisplay().shortString()
        if let author = post?.authorForDisplay() {
            byline = String(format: "%@ · %@", author, byline!)
        }
        bylineLabel.text = byline

    }

    private func configureRichText() {
        richTextView.delegate = self
        richTextView.content = post!.contentForDisplay()
        richTextView.privateContent = post!.isPrivate()
    }


    private func configureDiscoverAttribution() {
        if post?.sourceAttributionStyle() == SourceAttributionStyle.None {
            attributionView.hidden = true
        } else {
            attributionView.configureViewWithVerboseSiteAttribution(post!)

            let tgr = UITapGestureRecognizer(target: self, action: #selector(ReaderDetailViewController.didTapDiscoverAttribution))
            attributionView.addGestureRecognizer(tgr)
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
        if (ReaderHelpers.isLoggedIn() || post!.likeCount.integerValue > 0) && !post!.isExternal {
            configureLikeActionButton()
        }

        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom (jetpack and external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        if post!.isWPCom && !shouldHideComments {
            if (ReaderHelpers.isLoggedIn() && post!.commentsOpen) || post!.commentCount.integerValue > 0 {
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


    private func configureLikeActionButton(animated:Bool = false) {
        likeButton.enabled = ReaderHelpers.isLoggedIn()

        let title = post!.likeCountForDisplay()
        let imageName = post!.isLiked ? "icon-reader-liked" : "icon-reader-like"
        let image = UIImage(named: imageName)
        let highlightImage = UIImage(named: "icon-reader-like-highlight")
        let selected = post!.isLiked
        configureActionButton(likeButton, title: title, image: image, highlightedImage: highlightImage, selected:selected)

        if animated {
            playLikeButtonAnimation()
        }
    }


    private func playLikeButtonAnimation() {
        let likeImageView = likeButton.imageView!
        let frame = likeButton.convertRect(likeImageView.frame, fromView: likeImageView)

        let imageView = UIImageView(image: UIImage(named: "icon-reader-liked"))
        imageView.frame = frame
        likeButton.addSubview(imageView)

        let animationDuration = 0.3

        if likeButton.selected {
            // Prep a mask to hide the likeButton's image, since changes to visiblility and alpha are ignored
            let mask = UIView(frame: frame)
            mask.backgroundColor = view.backgroundColor
            likeButton.addSubview(mask)
            likeButton.bringSubviewToFront(imageView)

            // Configure starting state
            imageView.alpha = 0.0
            let angle = CGFloat((-270.0 * M_PI) / 180.0)
            let rotate = CGAffineTransformMakeRotation(angle)
            let scale = CGAffineTransformMakeScale(3.0, 3.0)
            imageView.transform = CGAffineTransformConcat(rotate, scale)

            // Perform the animations
            UIView.animateWithDuration(animationDuration,
                animations: { () in
                    let angle = CGFloat((1.0 * M_PI) / 180.0)
                    let rotate = CGAffineTransformMakeRotation(angle)
                    let scale = CGAffineTransformMakeScale(0.75, 0.75)
                    imageView.transform = CGAffineTransformConcat(rotate, scale)
                    imageView.alpha = 1.0;
                    imageView.center = likeImageView.center // In case the button's imageView shifted position
                },
                completion: { (_) in
                    UIView.animateWithDuration(animationDuration,
                        animations: { () in
                            imageView.transform = CGAffineTransformMakeScale(1.0, 1.0)
                        },
                        completion: { (_) in
                            mask.removeFromSuperview()
                            imageView.removeFromSuperview()
                    })
            })

        } else {

            UIView .animateWithDuration(animationDuration,
                animations: { () -> Void in
                    let angle = CGFloat((120.0 * M_PI) / 180.0)
                    let rotate = CGAffineTransformMakeRotation(angle)
                    let scale = CGAffineTransformMakeScale(3.0, 3.0)
                    imageView.transform = CGAffineTransformConcat(rotate, scale)
                    imageView.alpha = 0;
                },
                completion: { (_) in
                    imageView.removeFromSuperview()
            })

        }
    }


    private func configureCommentActionButton() {
        let title = post!.commentCount.stringValue
        let image = UIImage(named: "icon-reader-comment")
        let highlightImage = UIImage(named: "icon-reader-comment-highlight")
        configureActionButton(commentButton, title: title, image: image, highlightedImage: highlightImage, selected:false)
    }


    private func configureFooterIfNeeded() {
        self.footerView.hidden = tagButton.hidden && likeButton.hidden && commentButton.hidden
        if self.footerView.hidden {
            footerViewHeightConstraint.constant = 0
        }
        footerViewHeightConstraintConstant = footerViewHeightConstraint.constant
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

        let properties = ReaderHelpers.statsPropertiesForPost(post!, andValue: post!.blogURL, forKey: "URL")
        WPAppAnalytics.track(.ReaderSitePreviewed, withProperties: properties)
    }


    func setBarsHidden(hidden:Bool) {
        if (navigationController?.navigationBarHidden == hidden) {
            return
        }

        if (hidden) {
            // Hides the navbar and footer view
            navigationController?.setNavigationBarHidden(true, animated: true)
            footerViewHeightConstraint.constant = 0.0
            UIView.animateWithDuration(0.3,
                delay: 0.0,
                options: [.BeginFromCurrentState, .AllowUserInteraction],
                animations: { () -> Void in
                    self.view.layoutIfNeeded()
                }, completion: nil)

        } else {
            // Shows the navbar and footer view
            navigationController?.setNavigationBarHidden(false, animated: true)
            footerViewHeightConstraint.constant = footerViewHeightConstraintConstant
            UIView.animateWithDuration(0.3,
                delay: 0.0,
                options: [.BeginFromCurrentState, .AllowUserInteraction],
                animations: { () -> Void in
                    self.view.layoutIfNeeded()
                }, completion: nil)
        }

    }


    // MARK: - Analytics

    private func bumpStats() {
        if didBumpStats {
            return
        }
        didBumpStats = true

        let isOfflineView = ReachabilityUtils.isInternetReachable() ? "no" : "yes"
        let detailType = post!.topic?.type == ReaderSiteTopic.TopicType ? DetailAnalyticsConstants.TypePreviewSite : DetailAnalyticsConstants.TypeNormal

        var properties = ReaderHelpers.statsPropertiesForPost(post!, andValue: nil, forKey: nil)
        properties[DetailAnalyticsConstants.TypeKey] = detailType
        properties[DetailAnalyticsConstants.OfflineKey] = isOfflineView
        WPAppAnalytics.track(WPAnalyticsStat.ReaderArticleOpened, withProperties: properties)
    }


    private func bumpPageViewsForPost() {
        if didBumpPageViews || (post!.isExternal && !post!.isJetpack) {
            return
        }
        didBumpPageViews = true

        // Don't bump page views for feeds else the wrong blog/post get's bumped
        if post!.isExternal && !post!.isJetpack {
            return
        }

        // If the user is an admin on the post's site do not bump the page view unless
        // the the post is private.
        if !post!.isPrivate() && isUserAdminOnSiteWithID(post!.siteID) {
            return
        }

        let site = NSURL(string: post!.blogURL)
        if site?.host == nil {
            return
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

        let userAgent = WordPressAppDelegate.sharedInstance().userAgent.wordPressUserAgent
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
            return blog.isAdmin
        }
        return false
    }


    // MARK: - Actions

    @IBAction func didTapTagButton(sender: UIButton) {
        if !isLoaded {
            return
        }

        let controller = ReaderStreamViewController.controllerWithTagSlug(post!.primaryTagSlug)
        navigationController?.pushViewController(controller, animated: true)

        let properties =  ReaderHelpers.statsPropertiesForPost(post!, andValue: post!.primaryTagSlug, forKey: "tag")
        WPAppAnalytics.track(.ReaderTagPreviewed, withProperties: properties)
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
        if gesture.state != .Ended {
            return
        }
        previewSite()
    }


    @IBAction func didTapBlogNameButton(sender: UIButton) {
        previewSite()
    }


    @IBAction func didTapMenuButton(sender: UIButton) {
        ReaderPostMenu.showMenuForPost(post!, fromView: menuButton, inViewController: self)
    }


    func didTapFeaturedImage(gesture: UITapGestureRecognizer) {
        if gesture.state != .Ended {
            return
        }

        let controller = WPImageViewController(image: featuredImageView.image)
        controller.modalTransitionStyle = .CrossDissolve
        controller.modalPresentationStyle = .FullScreen
        presentViewController(controller, animated: true, completion: nil)
    }


    func didTapDiscoverAttribution() {
        if post?.sourceAttribution == nil {
            return
        }

        if let blogID = post?.sourceAttribution.blogID {
            let controller = ReaderStreamViewController.controllerWithSiteID(blogID, isFeed: false)
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        var path: String?
        if post?.sourceAttribution.attributionType == SourcePostAttributionTypePost {
            path = post?.sourceAttribution.permalink
        } else {
            path = post?.sourceAttribution.blogURL
        }

        if let linkURL = NSURL(string: path!) {
            presentWebViewControllerWithURL(linkURL)
        }
    }


    func didTapShareButton(sender: UIButton) {
        ReaderHelpers.sharePost(post!, fromView: sender, inViewController: self)
    }


    func handleBlockSiteNotification(notification:NSNotification) {
        if let userInfo = notification.userInfo, aPost = userInfo["post"] as? NSObject {
            if aPost == post! {
                navigationController?.popViewControllerAnimated(true)
            }
        }
    }
}


// MARK: - WPRichTextView Delegate Methods

extension ReaderDetailViewController : WPRichTextViewDelegate
{
    public func richTextView(richTextView: WPRichTextView, didReceiveImageLinkAction imageControl: WPRichTextImage) {
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


    public func richTextView(richTextView: WPRichTextView, didReceiveLinkAction linkURL: NSURL) {
        var url = linkURL
        if url.host != nil {
            let postURL = NSURL(string: post!.permaLink)
            url = NSURL(string: linkURL.absoluteString, relativeToURL: postURL)!
        }
        presentWebViewControllerWithURL(url)
    }

}


extension ReaderDetailViewController : UIScrollViewDelegate
{
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if UIDevice.isPad() || footerView.hidden || !isLoaded {
            return
        }

        // The threshold for hiding the bars is twice the height of the hidden bars. 
        // This ensures that once the bars are hidden the view can still be scrolled 
        // and thus can unhide the bars.
        var threshold = footerViewHeightConstraintConstant
        if let navHeight = navigationController?.navigationBar.frame.height {
            threshold += navHeight
        }
        threshold *= 2.0

        let y = targetContentOffset.memory.y
        if y > scrollView.contentOffset.y && y > threshold {
            setBarsHidden(true)
        } else {
            setBarsHidden(false)
        }
    }

}
