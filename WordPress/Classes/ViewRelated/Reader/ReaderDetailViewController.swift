import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressUI
import QuartzCore
import Gridicons
import AFNetworking

open class ReaderDetailViewController: UIViewController, UIViewControllerRestoration {
    @objc static let restorablePostObjectURLhKey: String = "RestorablePostObjectURLKey"

    // Structs for Constants

    fileprivate struct DetailConstants {
        static let LikeCountKeyPath = "likeCount"
        static let MarginOffset = CGFloat(8.0)
    }


    fileprivate struct DetailAnalyticsConstants {
        static let TypeKey = "post_detail_type"
        static let TypeNormal = "normal"
        static let TypePreviewSite = "preview_site"
        static let OfflineKey = "offline_view"
        static let PixelStatReferrer = "https://wordpress.com/"
    }


    // MARK: - Properties & Accessors

    // Callbacks
    /// Called if the view controller's post fails to load
    var postLoadFailureBlock: (() -> Void)? = nil

    // Footer views
    @IBOutlet fileprivate weak var footerView: UIView!
    @IBOutlet fileprivate weak var tagButton: UIButton!
    @IBOutlet fileprivate weak var commentButton: UIButton!
    @IBOutlet fileprivate weak var likeButton: UIButton!
    @IBOutlet fileprivate weak var footerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var saveForLaterButton: UIButton!
    // Wrapper views
    @IBOutlet fileprivate weak var textHeaderStackView: UIStackView!
    @IBOutlet fileprivate weak var textFooterStackView: UIStackView!
    fileprivate var textFooterTopConstraint: NSLayoutConstraint!

    // Header realated Views
    @IBOutlet fileprivate weak var headerView: UIView!
    @IBOutlet fileprivate weak var blavatarImageView: UIImageView!
    @IBOutlet fileprivate weak var blogNameButton: UIButton!
    @IBOutlet fileprivate weak var blogURLLabel: UILabel!
    @IBOutlet fileprivate weak var menuButton: UIButton!

    // Content views
    @IBOutlet fileprivate weak var featuredImageView: CachedAnimatedImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var bylineView: UIView!
    @IBOutlet fileprivate weak var bylineScrollView: UIScrollView!
    @IBOutlet fileprivate var bylineGradientViews: [GradientView]!
    @IBOutlet fileprivate weak var avatarImageView: CircularImageView!
    @IBOutlet fileprivate weak var bylineLabel: UILabel!
    @IBOutlet fileprivate weak var textView: WPRichContentView!
    @IBOutlet fileprivate weak var attributionView: ReaderCardDiscoverAttributionView!

    // Spacers
    @IBOutlet fileprivate weak var featuredImageBottomPaddingView: UIView!
    @IBOutlet fileprivate weak var titleBottomPaddingView: UIView!
    @IBOutlet fileprivate weak var bylineBottomPaddingView: UIView!

    @objc open var shouldHideComments = false
    fileprivate var didBumpStats = false
    fileprivate var didBumpPageViews = false
    fileprivate var footerViewHeightConstraintConstant = CGFloat(0.0)

    fileprivate let sharingController = PostSharingController()

    private let noResultsViewController = NoResultsViewController.controller()

    private let readerLinkRouter = UniversalLinkRouter(routes: UniversalLinkRouter.ReaderRoutes)

    @objc var currentPreferredStatusBarStyle = UIStatusBarStyle.lightContent {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return currentPreferredStatusBarStyle
    }

    @objc open var post: ReaderPost? {
        didSet {
            oldValue?.removeObserver(self, forKeyPath: DetailConstants.LikeCountKeyPath)
            oldValue?.inUse = false

            if let newPost = post, let context = newPost.managedObjectContext {
                newPost.inUse = true
                ContextManager.sharedInstance().save(context)
                newPost.addObserver(self, forKeyPath: DetailConstants.LikeCountKeyPath, options: .new, context: nil)
            }
            if isViewLoaded {
                configureView()
            }
        }
    }

    open var postURL: URL? = nil

    fileprivate var isLoaded: Bool {
        return post != nil
    }

    fileprivate lazy var featuredImageLoader: ImageLoader = {
        // Allow for large GIFs to animate on the detail page
        return ImageLoader(imageView: featuredImageView, gifStrategy: .largeGIFs)
    }()

    /// The user interface direction for the view's semantic content attribute.
    ///
    private var layoutDirection: UIUserInterfaceLayoutDirection {
        return UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute)
    }

    // MARK: - Convenience Factories


    /// Convenience method for instantiating an instance of ReaderDetailViewController
    /// for a particular topic.
    ///
    /// - Parameters:
    ///     - topic:  The reader topic for the list.
    ///
    /// - Return: A ReaderListViewController instance.
    ///
    @objc open class func controllerWithPost(_ post: ReaderPost) -> ReaderDetailViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderDetailViewController") as! ReaderDetailViewController
        controller.post = post

        return controller
    }


    @objc open class func controllerWithPostID(_ postID: NSNumber, siteID: NSNumber, isFeed: Bool = false) -> ReaderDetailViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderDetailViewController") as! ReaderDetailViewController
        controller.setupWithPostID(postID, siteID: siteID, isFeed: isFeed)

        return controller
    }

    @objc open class func controllerWithPostURL(_ url: URL) -> ReaderDetailViewController {

        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderDetailViewController") as! ReaderDetailViewController
        controller.setupWithPostURL(url)

        return controller
    }

    // MARK: - State Restoration


    public static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        guard let path = coder.decodeObject(forKey: restorablePostObjectURLhKey) as? String else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        guard let url = URL(string: path),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
            return nil
        }

        guard let post = (try? context.existingObject(with: objectID)) as? ReaderPost else {
            return nil
        }

        return controllerWithPost(post)
    }


    open override func encodeRestorableState(with coder: NSCoder) {
        if let post = post {
            coder.encode(post.objectID.uriRepresentation().absoluteString, forKey: type(of: self).restorablePostObjectURLhKey)
        }

        super.encodeRestorableState(with: coder)
    }


    // MARK: - LifeCycle Methods


    deinit {
        if let post = post, let context = post.managedObjectContext {
            post.inUse = false
            ContextManager.sharedInstance().save(context)
            post.removeObserver(self, forKeyPath: DetailConstants.LikeCountKeyPath)
        }
        NotificationCenter.default.removeObserver(self)
    }


    open override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        restorationClass = type(of: self)

        return super.awakeAfter(using: aDecoder)
    }


    open override func viewDidLoad() {
        super.viewDidLoad()

        setupContentHeaderAndFooter()
        textView.alpha = 0
        footerView.isHidden = true

        // Hide the featured image and its padding until we know there is one to load.
        featuredImageView.isHidden = true
        featuredImageBottomPaddingView.isHidden = true

        noResultsViewController.delegate = self

        // Styles
        applyStyles()

        setupNavBar()

        if let _ = post {
            configureView()
        }

        prepareForVoiceOver()
    }


    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // The UIApplicationDidBecomeActiveNotification notification is broadcast
        // when the app is resumed as a part of split screen multitasking on the iPad.
        NotificationCenter.default.addObserver(self, selector: #selector(ReaderDetailViewController.handleApplicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)

        bumpStats()
        bumpPageViewsForPost()
        indexReaderPostInSpotlight()
    }


    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        setBarsHidden(false, animated: animated)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }


    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        updateContentInsets()
        updateTextViewMargins()
    }


    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // This is something we do to help with the resizing that can occur with
        // split screen multitasking on the iPad.
        view.layoutIfNeeded()
    }


    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let y = textView.contentOffset.y
        let position = textView.closestPosition(to: CGPoint(x: 0.0, y: y))

        coordinator.animate(
            alongsideTransition: { (_) in
                if let position = position, let textRange = self.textView.textRange(from: position, to: position) {
                    let rect = self.textView.firstRect(for: textRange)
                    self.textView.setContentOffset(CGPoint(x: 0.0, y: rect.origin.y), animated: false)
                }
            },
            completion: { (_) in
                self.updateContentInsets()
                self.updateTextViewMargins()
        })

        // Make sure that the bars are visible after switching from landscape
        // to portrait orientation.  The content might have been scrollable in landscape
        // orientation, but it might not be in portrait orientation. We'll assume the bars
        // should be visible for safety sake and for performance since WPRichTextView updates
        // its intrinsicContentSize too late for get an accurate scrollWiew.contentSize
        // in the completion handler below.
        if size.height > size.width {
            self.setBarsHidden(false)
        }
    }


    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if (object! as! NSObject == post!) && (keyPath! == DetailConstants.LikeCountKeyPath) {
            // Note: The intent here is to update the action buttons, specifically the
            // like button, *after* both likeCount and isLiked has changed. The order
            // of the properties is important.
            configureLikeActionButton(true)
        }
    }


    // MARK: - Multitasking Splitview Support

    @objc func handleApplicationDidBecomeActive(_ notification: Foundation.Notification) {
        view.layoutIfNeeded()
    }

    // MARK: - Setup

    @objc open func setupWithPostID(_ postID: NSNumber, siteID: NSNumber, isFeed: Bool) {

        configureAndDisplayLoadingView(title: LoadingText.loadingTitle, accessoryView: NoResultsViewController.loadingAccessoryView())

        textView.alpha = 0.0

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderPostService(managedObjectContext: context)

        service.fetchPost(
        postID.uintValue,
        forSite: siteID.uintValue,
        isFeed: isFeed,
        success: {[weak self] (post: ReaderPost?) in
                self?.hideLoadingView()
                self?.textView.alpha = 1.0
                self?.post = post
            }, failure: {[weak self] (error: Error?) in
                DDLogError("Error fetching post for detail: \(String(describing: error?.localizedDescription))")
                self?.configureAndDisplayLoadingView(title: LoadingText.errorLoadingTitle)
                self?.reportPostLoadFailure()
            }
        )
    }

    @objc open func setupWithPostURL(_ postURL: URL) {
        self.postURL = postURL

        configureAndDisplayLoadingView(title: LoadingText.loadingTitle, accessoryView: NoResultsViewController.loadingAccessoryView())

        textView.alpha = 0.0

        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderPostService(managedObjectContext: context)

        service.fetchPost(at: postURL,
                          success: { [weak self] post in
                            self?.hideLoadingView()
                            self?.textView.alpha = 1.0
                            self?.post = post
        }, failure: {[weak self] (error: Error?) in
            DDLogError("Error fetching post for detail: \(String(describing: error?.localizedDescription))")
            self?.configureAndDisplayLoadingViewWithWebAction(title: LoadingText.errorLoadingTitle)
        })
    }


    /// Composes the views for the post header and Discover attribution.
    fileprivate func setupContentHeaderAndFooter() {
        // Add the footer first so its behind the header. This way the header
        // obscures the footer until its properly positioned.
        textView.addSubview(textFooterStackView)
        textView.addSubview(textHeaderStackView)

        textHeaderStackView.topAnchor.constraint(equalTo: textView.topAnchor).isActive = true

        textFooterTopConstraint = NSLayoutConstraint(item: textFooterStackView,
                                                     attribute: .top,
                                                     relatedBy: .equal,
                                                     toItem: textView,
                                                     attribute: .top,
                                                     multiplier: 1.0,
                                                     constant: 0.0)
        textView.addConstraint(textFooterTopConstraint)
        textFooterTopConstraint.constant = textFooterYOffset()
        textView.setContentOffset(CGPoint.zero, animated: false)
    }


    /// Sets the left and right textContainerInset to preserve readable content margins.
    fileprivate func updateContentInsets() {
        var insets = textView.textContainerInset

        let margin = view.readableContentGuide.layoutFrame.origin.x
        insets.left = margin - DetailConstants.MarginOffset
        insets.right = margin - DetailConstants.MarginOffset
        textView.textContainerInset = insets
        textView.layoutIfNeeded()
    }


    /// Returns the y position for the textfooter. Assign to the textFooter's top
    /// constraint constant to correctly position the view.
    fileprivate func textFooterYOffset() -> CGFloat {
        let length = textView.textStorage.length
        if length == 0 {
            return textView.contentSize.height - textFooterStackView.frame.height
        }
        let range = NSRange(location: length - 1, length: 0)
        let frame = textView.frameForTextInRange(range)
        if frame.minY == CGFloat.infinity {
            // A value of infinity can occur when a device is rotated 180 degrees.
            // It will sort it self out as the rotation aniation progresses,
            // so just return the existing constant.
            return textFooterTopConstraint.constant
        }
        return frame.minY
    }


    /// Updates the bounds of the placeholder top and bottom text attachments so
    /// there is enough vertical space for the text header and footer views.
    fileprivate func updateTextViewMargins() {
        textView.topMargin = textHeaderStackView.frame.height
        textView.bottomMargin = textFooterStackView.frame.height
        textFooterTopConstraint.constant = textFooterYOffset()
    }


    fileprivate func setupNavBar() {
        configureNavTitle()

        // Don't show 'Reader' in the next-view back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }


    // MARK: - Configuration

    /**
    Applies the default styles to the cell's subviews
    */
    fileprivate func applyStyles() {
        WPStyleGuide.applyReaderCardSiteButtonStyle(blogNameButton)
        WPStyleGuide.applyReaderCardBylineLabelStyle(bylineLabel)
        WPStyleGuide.applyReaderCardBylineLabelStyle(blogURLLabel)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)
        WPStyleGuide.applyReaderCardTagButtonStyle(tagButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(commentButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(likeButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(saveForLaterButton)
    }


    fileprivate func configureView() {
        textView.alpha = 1
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
        adjustInsetsForTextDirection()

        bumpStats()
        bumpPageViewsForPost()

        NotificationCenter.default.addObserver(self,
            selector: #selector(ReaderDetailViewController.handleBlockSiteNotification(_:)),
            name: NSNotification.Name(rawValue: ReaderPostMenu.BlockSiteNotification),
            object: nil)

        view.layoutIfNeeded()
        textView.setContentOffset(CGPoint.zero, animated: false)
    }


    fileprivate func configureNavTitle() {
        let placeholder = NSLocalizedString("Post", comment: "Placeholder title for ReaderPostDetails.")
        self.title = post?.postTitle ?? placeholder
    }


    fileprivate func configureShareButton() {
        // Share button.
        let image = UIImage(named: "icon-posts-share")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        let button = CustomHighlightButton(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        button.setImage(image, for: UIControlState())
        button.addTarget(self, action: #selector(ReaderDetailViewController.didTapShareButton(_:)), for: .touchUpInside)

        let shareButton = UIBarButtonItem(customView: button)
        shareButton.accessibilityLabel = NSLocalizedString("Share", comment: "Spoken accessibility label")
        WPStyleGuide.setRightBarButtonItemWithCorrectSpacing(shareButton, for: navigationItem)
    }


    fileprivate func configureHeader() {
        // Blavatar
        let placeholder = UIImage(named: "post-blavatar-placeholder")
        blavatarImageView.image = placeholder

        let size = blavatarImageView.frame.size.width * UIScreen.main.scale
        if let url = post?.siteIconForDisplay(ofSize: Int(size)) {
            blavatarImageView.setImageWith(url, placeholderImage: placeholder)
        }
        // Site name
        let blogName = post?.blogNameForDisplay()
        blogNameButton.setTitle(blogName, for: UIControlState())
        blogNameButton.setTitle(blogName, for: .highlighted)
        blogNameButton.setTitle(blogName, for: .disabled)
        blogNameButton.isAccessibilityElement = false
        blogNameButton.naturalContentHorizontalAlignment = .leading

        // Enable button only if not previewing a site.
        if let topic = post!.topic {
            blogNameButton.isEnabled = !ReaderHelpers.isTopicSite(topic)
        }

        // If the button is enabled also listen for taps on the avatar.
        if blogNameButton.isEnabled {
            let tgr = UITapGestureRecognizer(target: self, action: #selector(ReaderDetailViewController.didTapHeaderAvatar(_:)))
            blavatarImageView.addGestureRecognizer(tgr)
        }

        if let siteURL: NSString = post!.siteURLForDisplay() as NSString? {
            blogURLLabel.text = siteURL.components(separatedBy: "//").last
        }
    }


    fileprivate func configureFeaturedImage() {
        guard let post = post,
            !post.contentIncludesFeaturedImage(),
            let featuredImageURL = post.featuredImageURLForDisplay() else {
                return
        }

        let postInfo = ReaderCardContent(provider: post)
        let maxImageWidth = min(view.frame.width, view.frame.height)
        let imageWidthSize = CGSize(width: maxImageWidth, height: 0) // height 0: preserves aspect ratio.
        featuredImageLoader.loadImage(with: featuredImageURL, from: postInfo, preferredSize: imageWidthSize, placeholder: nil, success: { [weak self] in
            guard let strongSelf = self, let size = strongSelf.featuredImageView.image?.size else {
                return
            }
            DispatchQueue.main.async {
                strongSelf.configureFeaturedImageConstraints(with: size)
                strongSelf.configureFeaturedImageGestures()
            }
        }) { error in
            DDLogError("Error loading featured image in reader detail: \(String(describing: error))")
        }
    }

    fileprivate func configureFeaturedImageConstraints(with size: CGSize) {
        // Unhide the views
        featuredImageView.isHidden = false
        featuredImageBottomPaddingView.isHidden = false

        // Now that we have the image, create an aspect ratio constraint for
        // the featuredImageView
        let ratio = size.height / size.width
        let constraint = NSLayoutConstraint(item: featuredImageView,
                                            attribute: .height,
                                            relatedBy: .equal,
                                            toItem: featuredImageView,
                                            attribute: .width,
                                            multiplier: ratio,
                                            constant: 0)
        constraint.priority = .defaultHigh
        featuredImageView.addConstraint(constraint)
        featuredImageView.setNeedsUpdateConstraints()
    }


    fileprivate func configureFeaturedImageGestures() {
        // Listen for taps so we can display the image detail
        let tgr = UITapGestureRecognizer(target: self, action: #selector(ReaderDetailViewController.didTapFeaturedImage(_:)))
        featuredImageView.addGestureRecognizer(tgr)

        view.layoutIfNeeded()
        updateTextViewMargins()
    }


    fileprivate func requestForURL(_ url: URL) -> URLRequest {
        var requestURL = url

        let absoluteString = requestURL.absoluteString
        if !absoluteString.hasPrefix("https") {
            let sslURL = absoluteString.replacingOccurrences(of: "http", with: "https")
            requestURL = URL(string: sslURL)!
        }

        let request = NSMutableURLRequest(url: requestURL)

        let acctServ = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        if let account = acctServ.defaultWordPressComAccount() {
            let token = account.authToken
            let headerValue = String(format: "Bearer %@", token!)
            request.addValue(headerValue, forHTTPHeaderField: "Authorization")
        }

        return request as URLRequest
    }


    fileprivate func configureTitle() {
        if let title = post?.titleForDisplay() {
            titleLabel.attributedText = NSAttributedString(string: title, attributes: WPStyleGuide.readerDetailTitleAttributes())
            titleLabel.isHidden = false

        } else {
            titleLabel.attributedText = nil
            titleLabel.isHidden = true
        }
    }


    fileprivate func configureByLine() {
        // Avatar
        let placeholder = UIImage(named: "gravatar")

        if let avatarURLString = post?.authorAvatarURL,
            let url = URL(string: avatarURLString) {
            avatarImageView.setImageWith(url, placeholderImage: placeholder)
        }

        // Byline
        let author = post?.authorForDisplay()
        let dateAsString = post?.dateForDisplay()?.mediumString()
        let byline: String

        if let author = author, let date = dateAsString {
            byline = author + " · " + date
        } else {
            byline = author ?? dateAsString ?? String()
        }

        bylineLabel.text = byline

        flipBylineViewIfNeeded()
    }

    private func flipBylineViewIfNeeded() {
        if layoutDirection == .rightToLeft {
            bylineScrollView.transform = CGAffineTransform(scaleX: -1, y: 1)
            bylineScrollView.subviews.first?.transform = CGAffineTransform(scaleX: -1, y: 1)

            for gradientView in bylineGradientViews {
                let start = gradientView.startPoint
                let end = gradientView.endPoint

                gradientView.startPoint = end
                gradientView.endPoint = start
            }
        }
    }


    fileprivate func configureRichText() {
        guard let post = post else {
            return
        }
        textView.isPrivate = post.isPrivate()
        textView.content = post.contentForDisplay()

        updateTextViewMargins()
    }


    fileprivate func configureDiscoverAttribution() {
        if post?.sourceAttributionStyle() == SourceAttributionStyle.none {
            attributionView.isHidden = true
        } else {
            attributionView.configureViewWithVerboseSiteAttribution(post!)
            attributionView.delegate = self
        }
    }


    fileprivate func configureTag() {
        var tag = ""
        if let rawTag = post?.primaryTag {
            if rawTag.count > 0 {
                tag = "#\(rawTag)"
            }
        }
        tagButton.isHidden = tag.count == 0
        tagButton.setTitle(tag, for: UIControlState())
        tagButton.setTitle(tag, for: .highlighted)
    }


    fileprivate func configureActionButtons() {
        resetActionButton(likeButton)
        resetActionButton(commentButton)
        resetActionButton(saveForLaterButton)

        guard let post = post else {
            assertionFailure()
            return
        }

        // Show likes if logged in, or if likes exist, but not if external
        if (ReaderHelpers.isLoggedIn() || post.likeCount.intValue > 0) && !post.isExternal {
            configureLikeActionButton()
        }

        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom (jetpack and external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        if (post.isWPCom || post.isJetpack) && !shouldHideComments {
            let commentCount = post.commentCount?.intValue ?? 0
            if (ReaderHelpers.isLoggedIn() && post.commentsOpen) || commentCount > 0 {
                configureCommentActionButton()
            }
        }

        configureSaveForLaterButton()
    }


    fileprivate func resetActionButton(_ button: UIButton) {
        button.setTitle(nil, for: UIControlState())
        button.setTitle(nil, for: .highlighted)
        button.setTitle(nil, for: .disabled)
        button.setImage(nil, for: UIControlState())
        button.setImage(nil, for: .highlighted)
        button.setImage(nil, for: .disabled)
        button.isSelected = false
        button.isHidden = true
        button.isEnabled = true
    }


    fileprivate func configureActionButton(_ button: UIButton, title: String?, image: UIImage?, highlightedImage: UIImage?, selected: Bool) {
        button.setTitle(title, for: UIControlState())
        button.setTitle(title, for: .highlighted)
        button.setTitle(title, for: .disabled)
        button.setImage(image, for: UIControlState())
        button.setImage(highlightedImage, for: .highlighted)
        button.setImage(image, for: .disabled)
        button.isSelected = selected
        button.isHidden = false
    }


    fileprivate func configureLikeActionButton(_ animated: Bool = false) {
        likeButton.isEnabled = ReaderHelpers.isLoggedIn()

        let title = post!.likeCountForDisplay()
        let imageName = post!.isLiked ? "icon-reader-liked" : "icon-reader-like"
        let image = UIImage(named: imageName)
        let highlightImage = UIImage(named: "icon-reader-like-highlight")
        let selected = post!.isLiked
        configureActionButton(likeButton, title: title, image: image, highlightedImage: highlightImage, selected: selected)

        if animated {
            playLikeButtonAnimation()
        }
    }


    fileprivate func playLikeButtonAnimation() {
        let likeImageView = likeButton.imageView!
        let frame = likeButton.convert(likeImageView.frame, from: likeImageView)

        let imageView = UIImageView(image: UIImage(named: "icon-reader-liked"))
        imageView.frame = frame
        likeButton.addSubview(imageView)

        let animationDuration = 0.3

        if likeButton.isSelected {
            // Prep a mask to hide the likeButton's image, since changes to visiblility and alpha are ignored
            let mask = UIView(frame: frame)
            mask.backgroundColor = view.backgroundColor
            likeButton.addSubview(mask)
            likeButton.bringSubview(toFront: imageView)

            // Configure starting state
            imageView.alpha = 0.0
            let angle = (-270.0 * CGFloat.pi) / 180.0
            let rotate = CGAffineTransform(rotationAngle: angle)
            let scale = CGAffineTransform(scaleX: 3.0, y: 3.0)
            imageView.transform = rotate.concatenating(scale)

            // Perform the animations
            UIView.animate(withDuration: animationDuration,
                animations: { () in
                    let angle = (1.0 * CGFloat.pi) / 180.0
                    let rotate = CGAffineTransform(rotationAngle: angle)
                    let scale = CGAffineTransform(scaleX: 0.75, y: 0.75)
                    imageView.transform = rotate.concatenating(scale)
                    imageView.alpha = 1.0
                    imageView.center = likeImageView.center // In case the button's imageView shifted position
                },
                completion: { (_) in
                    UIView.animate(withDuration: animationDuration,
                        animations: { () in
                            imageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                        },
                        completion: { (_) in
                            mask.removeFromSuperview()
                            imageView.removeFromSuperview()
                    })
            })

        } else {

            UIView .animate(withDuration: animationDuration,
                animations: { () -> Void in
                    let angle = (120.0 * CGFloat.pi) / 180.0
                    let rotate = CGAffineTransform(rotationAngle: angle)
                    let scale = CGAffineTransform(scaleX: 3.0, y: 3.0)
                    imageView.transform = rotate.concatenating(scale)
                    imageView.alpha = 0
                },
                completion: { (_) in
                    imageView.removeFromSuperview()
            })

        }
    }


    fileprivate func configureCommentActionButton() {
        let title = post!.commentCount.stringValue
        let image = UIImage(named: "icon-reader-comment")?.imageFlippedForRightToLeftLayoutDirection()
        let highlightImage = UIImage(named: "icon-reader-comment-highlight")?.imageFlippedForRightToLeftLayoutDirection()
        configureActionButton(commentButton, title: title, image: image, highlightedImage: highlightImage, selected: false)
    }

    fileprivate func configureSaveForLaterButton() {
        WPStyleGuide.applyReaderSaveForLaterButtonStyle(saveForLaterButton)
        WPStyleGuide.applyReaderSaveForLaterButtonTitles(saveForLaterButton)

        saveForLaterButton.isHidden = false
        saveForLaterButton.isSelected = post?.isSavedForLater ?? false
    }


    fileprivate func configureFooterIfNeeded() {
        self.footerView.isHidden = tagButton.isHidden && likeButton.isHidden && commentButton.isHidden
        if self.footerView.isHidden {
            footerViewHeightConstraint.constant = 0
        }
        footerViewHeightConstraintConstant = footerViewHeightConstraint.constant
    }

    fileprivate func adjustInsetsForTextDirection() {
        let buttonsToAdjust: [UIButton] = [
            likeButton,
            commentButton,
            saveForLaterButton]
        for button in buttonsToAdjust {
            button.flipInsetsForRightToLeftLayoutDirection()
        }
    }


    // MARK: - Instance Methods

    @objc func presentReaderDetailViewControllerWithURL(_ url: URL) {
        let viewController = ReaderDetailViewController.controllerWithPostURL(url)
        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc func presentWebViewControllerWithURL(_ url: URL) {
        var url = url
        if url.host == nil {
            if let postURLString = post?.permaLink {
                let postURL = URL(string: postURLString)
                url = URL(string: url.absoluteString, relativeTo: postURL)!
            }
        }
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticateWithDefaultAccount()
        configuration.addsWPComReferrer = true
        let controller = WebViewControllerFactory.controller(configuration: configuration)
        let navController = UINavigationController(rootViewController: controller)
        present(navController, animated: true, completion: nil)
    }

    @objc func presentFullScreenGif(with animatedGifData: Data?) {
        guard let animatedGifData = animatedGifData else {
                return
        }
        let controller = WPImageViewController(gifData: animatedGifData)

        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }

    @objc func presentFullScreenImage(with image: UIImage?, linkURL: URL? = nil) {
        var controller: WPImageViewController

        if let linkURL = linkURL {
            controller = WPImageViewController(image: image, andURL: linkURL)
        } else if let image = image {
            controller = WPImageViewController(image: image)
        } else {
            return
        }

        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }

    @objc func previewSite() {
        let controller = ReaderStreamViewController.controllerWithSiteID(post!.siteID, isFeed: post!.isExternal)
        navigationController?.pushViewController(controller, animated: true)

        let properties = ReaderHelpers.statsPropertiesForPost(post!, andValue: post!.blogURL as AnyObject?, forKey: "URL")
        WPAppAnalytics.track(.readerSitePreviewed, withProperties: properties)
    }

    @objc func setBarsHidden(_ hidden: Bool, animated: Bool = true) {
        if navigationController?.isNavigationBarHidden == hidden {
            return
        }

        if hidden {
            // Hides the navbar and footer view
            navigationController?.setNavigationBarHidden(true, animated: animated)
            currentPreferredStatusBarStyle = .default
            footerViewHeightConstraint.constant = 0.0
            UIView.animate(withDuration: animated ? 0.2 : 0,
                delay: 0.0,
                options: [.beginFromCurrentState, .allowUserInteraction],
                animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)

        } else {
            // Shows the navbar and footer view
            let pinToBottom = isScrollViewAtBottom()

            currentPreferredStatusBarStyle = .lightContent
            footerViewHeightConstraint.constant = footerViewHeightConstraintConstant
            UIView.animate(withDuration: animated ? 0.2 : 0,
                           delay: 0.0,
                           options: [.beginFromCurrentState, .allowUserInteraction],
                           animations: {
                            self.view.layoutIfNeeded()
                            self.navigationController?.setNavigationBarHidden(false, animated: animated)
                            if pinToBottom {
                                let y = self.textView.contentSize.height - self.textView.frame.height
                                self.textView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
                            }

            }, completion: nil)
        }

    }


    @objc func isScrollViewAtBottom() -> Bool {
        return textView.contentOffset.y + textView.frame.height == textView.contentSize.height
    }

    @objc func indexReaderPostInSpotlight() {
        guard let post = post else {
            return
        }

        SearchManager.shared.indexItem(post)
    }

    private func reportPostLoadFailure() {
        postLoadFailureBlock?()

        // We'll nil out the failure block so we don't perform multiple callbacks
        postLoadFailureBlock = nil
    }

    // MARK: - Analytics

    fileprivate func bumpStats() {
        if didBumpStats {
            return
        }

        guard let readerPost = post, isViewLoaded && view.window != nil else {
            return
        }

        didBumpStats = true

        let isOfflineView = ReachabilityUtils.isInternetReachable() ? "no" : "yes"
        let detailType = readerPost.topic?.type == ReaderSiteTopic.TopicType ? DetailAnalyticsConstants.TypePreviewSite : DetailAnalyticsConstants.TypeNormal


        var properties = ReaderHelpers.statsPropertiesForPost(readerPost, andValue: nil, forKey: nil)
        properties[DetailAnalyticsConstants.TypeKey] = detailType
        properties[DetailAnalyticsConstants.OfflineKey] = isOfflineView
        WPAppAnalytics.track(.readerArticleOpened, withProperties: properties)

        // We can remove the nil check and use `if let` when `ReaderPost` adopts nullibility.
        let railcar = readerPost.railcarDictionary()
        if railcar != nil {
            WPAppAnalytics.trackTrainTracksInteraction(.readerArticleOpened, withProperties: railcar)
        }
    }


    fileprivate func bumpPageViewsForPost() {
        if didBumpPageViews {
            return
        }

        guard let readerPost = post, isViewLoaded && view.window != nil else {
            return
        }

        didBumpPageViews = true
        ReaderHelpers.bumpPageViewForPost(readerPost)
    }


    // MARK: - Actions

    @IBAction func didTapSaveForLaterButton(_ sender: UIButton) {
        guard let readerPost = post, let context = readerPost.managedObjectContext else {
            return
        }

        if !readerPost.isSavedForLater {
            FancyAlertViewController.presentReaderSavedPostsAlertControllerIfNecessary(from: self)
        }

        ReaderSaveForLaterAction().execute(with: readerPost, context: context, origin: .postDetail) { [weak self] in
            self?.saveForLaterButton.isSelected = readerPost.isSavedForLater
            self?.prepareActionButtonsForVoiceOver()
        }
    }

    @IBAction func didTapTagButton(_ sender: UIButton) {
        if !isLoaded {
            return
        }

        let controller = ReaderStreamViewController.controllerWithTagSlug(post!.primaryTagSlug)
        navigationController?.pushViewController(controller, animated: true)

        let properties =  ReaderHelpers.statsPropertiesForPost(post!, andValue: post!.primaryTagSlug as AnyObject?, forKey: "tag")
        WPAppAnalytics.track(.readerTagPreviewed, withProperties: properties)
    }


    @IBAction func didTapCommentButton(_ sender: UIButton) {
        if !isLoaded {
            return
        }

        let controller = ReaderCommentsViewController(post: post)
        navigationController?.pushViewController(controller!, animated: true)
    }


    @IBAction func didTapLikeButton(_ sender: UIButton) {
        if !isLoaded {
            return
        }

        guard let post = post else {
            return
        }

        if !post.isLiked {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        let service = ReaderPostService(managedObjectContext: post.managedObjectContext!)
        service.toggleLiked(for: post, success: nil, failure: { (error: Error?) in
            if let anError = error {
                DDLogError("Error (un)liking post: \(anError.localizedDescription)")
            }
        })
    }


    @objc func didTapHeaderAvatar(_ gesture: UITapGestureRecognizer) {
        if gesture.state != .ended {
            return
        }
        previewSite()
    }


    @IBAction func didTapBlogNameButton(_ sender: UIButton) {
        previewSite()
    }


    @IBAction func didTapMenuButton(_ sender: UIButton) {
        guard let post = post,
            let context = post.managedObjectContext else {
            return
        }

        guard post.isFollowing else {
            ReaderPostMenu.showMenuForPost(post, fromView: menuButton, inViewController: self)
            return
        }

        let service = ReaderTopicService(managedObjectContext: context)
        if let topic = service.findSiteTopic(withSiteID: post.siteID) {
            ReaderPostMenu.showMenuForPost(post, topic: topic, fromView: menuButton, inViewController: self)
            return
        }
    }


    @objc func didTapFeaturedImage(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let post = post else {
            return
        }

        var controller: WPImageViewController
        if post.featuredImageURL.isGif, let data = featuredImageView.animatedGifData {
            controller = WPImageViewController(gifData: data)
        } else if let featuredImage = featuredImageView.image {
            controller = WPImageViewController(image: featuredImage)
        } else {
            return
        }
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }


    @objc func didTapDiscoverAttribution() {
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

        if let linkURL = URL(string: path!) {
            presentWebViewControllerWithURL(linkURL)
        }
    }


    @objc func didTapShareButton(_ sender: UIButton) {
        sharingController.shareReaderPost(post!, fromView: sender, inViewController: self)
    }


    @objc func handleBlockSiteNotification(_ notification: Foundation.Notification) {
        if let userInfo = notification.userInfo, let aPost = userInfo["post"] as? NSObject {
            if aPost == post! {
                _ = navigationController?.popViewController(animated: true)
            }
        }
    }
}

// MARK: - Loading View Handling

private extension ReaderDetailViewController {

    func configureAndDisplayLoadingView(title: String, accessoryView: UIView? = nil) {
        noResultsViewController.configure(title: title, image: "wp-illustration-empty-results", accessoryView: accessoryView)
        showLoadingView()
    }

    func configureAndDisplayLoadingViewWithWebAction(title: String, accessoryView: UIView? = nil) {
        noResultsViewController.configure(title: title,
                                          buttonTitle: LoadingText.errorLoadingPostURLButtonTitle,
                                          image: "wp-illustration-empty-results",
                                          accessoryView: accessoryView)
        showLoadingView()
    }

    func showLoadingView() {
        hideLoadingView()
        addChildViewController(noResultsViewController)
        view.addSubview(withFadeAnimation: noResultsViewController.view)
        noResultsViewController.didMove(toParentViewController: self)
    }

    func hideLoadingView() {
        noResultsViewController.removeFromView()
    }

    struct LoadingText {
        static let loadingTitle = NSLocalizedString("Loading Post...", comment: "Text displayed while loading a post.")
        static let errorLoadingTitle = NSLocalizedString("Error Loading Post", comment: "Text displayed when load post fails.")
        static let errorLoadingPostURLButtonTitle = NSLocalizedString("Open in browser", comment: "Button title to load a post in an in-app web view")
    }

}

// MARK: - ReaderCardDiscoverAttributionView Delegate Methods

extension ReaderDetailViewController: ReaderCardDiscoverAttributionViewDelegate {
    public func attributionActionSelectedForVisitingSite(_ view: ReaderCardDiscoverAttributionView) {
        didTapDiscoverAttribution()
    }
}


// MARK: - UITextView/WPRichContentView Delegate Methods

extension ReaderDetailViewController: WPRichContentViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        presentWebViewControllerWithURL(URL)
        return false
    }

    @available(iOS 10, *)
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .presentActions {
            // show
            let frame = textView.frameForTextInRange(characterRange)
            let shareController = PostSharingController()
            shareController.shareURL(url: URL as NSURL, fromRect: frame, inView: textView, inViewController: self)
        } else if readerLinkRouter.canHandle(url: URL) {
            readerLinkRouter.handle(url: URL, shouldTrack: false, source: self)
        } else if URL.isWordPressDotComPost {
            presentReaderDetailViewControllerWithURL(URL)
        } else {
            presentWebViewControllerWithURL(URL)
        }
        return false
    }

    func richContentView(_ richContentView: WPRichContentView, didReceiveImageAction image: WPRichTextImage) {
        // If we have gif data availible, present that
        if let animatedGifData = image.imageView.animatedGifData {
            presentFullScreenGif(with: animatedGifData)
            return
        }

        // Otherwise try to present the static image/URL
        if let linkURL = image.linkURL, WPImageViewController.isUrlSupported(linkURL) {
            presentFullScreenImage(with: image.imageView.image, linkURL: linkURL)
        } else if let linkURL = image.linkURL {
            presentWebViewControllerWithURL(linkURL as URL)
        } else if let staticImage = image.imageView.image {
            presentFullScreenImage(with: staticImage)
        }
    }
}


// MARK: - UIScrollView Delegate Methods

extension ReaderDetailViewController: UIScrollViewDelegate {

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if UIDevice.isPad() || footerView.isHidden || !isLoaded {
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

        let y = targetContentOffset.pointee.y
        if y > scrollView.contentOffset.y && y > threshold {
            setBarsHidden(true)
        } else {
            // Velocity will be 0,0 if the user taps to stop an in progress scroll.
            // If the bars are already visible its fine but if the bars are hidden
            // we don't want to jar the user by having them reappear.
            if !velocity.equalTo(CGPoint.zero) {
                setBarsHidden(false)
            }
        }
    }


    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        setBarsHidden(false)
    }


    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if isScrollViewAtBottom() {
            setBarsHidden(false)
        }
    }

}

// Expand this view controller to full screen if possible
extension ReaderDetailViewController: PrefersFullscreenDisplay {}

// Let's the split view know this vc changes the status bar style.
extension ReaderDetailViewController: DefinesVariableStatusBarStyle {}

extension ReaderDetailViewController: Accessible {
    func prepareForVoiceOver() {
        prepareMenuForVoiceOver()
        prepareHeaderForVoiceOver()
        prepareContentForVoiceOver()
        prepareActionButtonsForVoiceOver()
    }

    private func prepareMenuForVoiceOver() {
        menuButton.accessibilityLabel = NSLocalizedString("More", comment: "Accessibility label for the More button on Reader's post details")
        menuButton.accessibilityTraits = UIAccessibilityTraitButton
        menuButton.accessibilityHint = NSLocalizedString("Shows more options.", comment: "Accessibility hint for the More button on Reader's post details")
    }

    private func prepareHeaderForVoiceOver() {
        guard let post = post else {
            blogNameButton.isAccessibilityElement = false
            return
        }
        blogNameButton.isAccessibilityElement = true
        blogNameButton.accessibilityTraits = UIAccessibilityTraitStaticText
        if let label = blogNameLabel(post) {
            blogNameButton.accessibilityLabel = label
        }
    }

    private func blogNameLabel(_ post: ReaderPost) -> String? {
        guard let postedIn = post.blogNameForDisplay(),
            let postedBy = post.authorDisplayName else {
                return nil
        }

        guard let postedOn = post.dateCreated?.mediumString() else {
            let format = NSLocalizedString("Posted in %@, by %@.", comment: "Accessibility label for the blog name in the Reader's post details, without date. Placeholders are blog title, author name")
            return String(format: format, postedIn, postedBy)
        }

        let format = NSLocalizedString("Posted in %@, by %@, %@", comment: "Accessibility label for the blog name in the Reader's post details. Placeholders are blog title, author name, published date")
        return String(format: format, postedIn, postedBy, postedOn)
    }

    private func prepareContentForVoiceOver() {
        preparePostTitleForVoiceOver()
    }

    private func preparePostTitleForVoiceOver() {
        guard let post = post else {
            return
        }

        guard let title = post.titleForDisplay() else {
            return
        }
        textHeaderStackView.isAccessibilityElement = false

        titleLabel.accessibilityLabel = title
        titleLabel.accessibilityTraits = UIAccessibilityTraitStaticText
    }

    private func prepareActionButtonsForVoiceOver() {
        let isSavedForLater = post?.isSavedForLater ?? false
        saveForLaterButton.accessibilityLabel = isSavedForLater ? NSLocalizedString("Saved Post", comment: "Accessibility label for the 'Save Post' button when a post has been saved.") : NSLocalizedString("Save post", comment: "Accessibility label for the 'Save Post' button.")
        saveForLaterButton.accessibilityHint = isSavedForLater ? NSLocalizedString("Remove this post from my saved posts.", comment: "Accessibility hint for the 'Save Post' button when a post is already saved.") : NSLocalizedString("Saves this post for later.", comment: "Accessibility hint for the 'Save Post' button.")
    }
}


//// MARK: - UIViewControllerTransitioningDelegate
////
extension ReaderDetailViewController: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented is FancyAlertViewController else {
            return nil
        }

        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

/// MARK: - NoResultsViewControllerDelegate
///
extension ReaderDetailViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        if let postURL = postURL {
            presentWebViewControllerWithURL(postURL)
            navigationController?.popViewController(animated: true)
        }
    }
}
