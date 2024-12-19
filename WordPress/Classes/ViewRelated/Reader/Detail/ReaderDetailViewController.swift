import UIKit
import WordPressUI
import AutomatticTracks

typealias RelatedPostsSection = (postType: RemoteReaderSimplePost.PostType, posts: [RemoteReaderSimplePost])

protocol ReaderDetailView: AnyObject {
    func render(_ post: ReaderPost)
    func renderRelatedPosts(_ posts: [RemoteReaderSimplePost])
    func showLoading()
    func showError(subtitle: String?)
    func showErrorWithWebAction()
    func scroll(to: String)
    func updateHeader()
    func updateLikesView(with viewModel: ReaderDetailLikesViewModel)

    /// Updates comments table to display the post's comments.
    /// - Parameters:
    ///   - comments: Comments to be displayed.
    ///   - totalComments: The total number of comments for this post.
    func updateComments(_ comments: [Comment], totalComments: Int)
}

class ReaderDetailViewController: UIViewController, ReaderDetailView {

    /// Content scroll view
    @IBOutlet weak var scrollView: UIScrollView!

    /// A ReaderWebView
    @IBOutlet weak var webView: ReaderWebView!

    /// WebView height constraint
    @IBOutlet weak var webViewHeight: NSLayoutConstraint!

    /// The table view that displays Comments
    @IBOutlet weak var commentsTableView: IntrinsicTableView!

    // swiftlint:disable:next weak_delegate
    private lazy var commentsTableViewDelegate = {
        ReaderDetailCommentsTableViewDelegate(displaySetting: displaySetting)
    }()

    /// The table view that displays Related Posts
    @IBOutlet weak var relatedPostsTableView: IntrinsicTableView!

    /// Whether the we should load the related posts section.
    /// Ideally we should only load this section once per post.
    private var shouldFetchRelatedPosts = true

    /// Header container
    @IBOutlet weak var headerContainerView: UIView!

    /// Wrapper for the toolbar
    @IBOutlet weak var toolbarContainerView: UIView!

    private lazy var toolbarHidingConstraint = toolbarContainerView.heightAnchor.constraint(equalToConstant: 0)

    /// Wrapper for the Likes summary view
    @IBOutlet weak var likesContainerView: UIView!

    /// The loading view, which contains all the ghost views
    @IBOutlet weak var actionStackView: UIStackView!

    /// Attribution view for Discovery posts
    @IBOutlet weak var attributionView: ReaderCardDiscoverAttributionView!

    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    /// The actual header
    private let featuredImage: ReaderDetailFeaturedImageView = .loadFromNib()

    /// The actual header
    private lazy var header: ReaderDetailHeaderHostingView = {
        return .init()
    }()

    /// Bottom toolbar
    private let toolbar: ReaderDetailToolbar = .loadFromNib()
    private var isToolbarHidden = false
    private var lastContentOffset: CGFloat = 0

    /// Likes summary view
    private let likesSummary: ReaderDetailLikesView = .loadFromNib()

    /// A view that fills the bottom portion outside of the safe area
    @IBOutlet weak var toolbarSafeAreaView: UIView!

    /// View used to show errors
    private let noResultsViewController = NoResultsViewController.controller()

    /// An observer of the content size of the webview
    private var scrollObserver: NSKeyValueObservation?

    /// The coordinator, responsible for the logic
    var coordinator: ReaderDetailCoordinator?

    /// Hide the comments button in the toolbar
    @objc var shouldHideComments: Bool = false {
        didSet {
            toolbar.shouldHideComments = shouldHideComments
        }
    }

    /// The post being shown
    @objc var post: ReaderPost? {
        return coordinator?.post
    }

    /// The related posts for the post being shown
    var relatedPosts: [RelatedPostsSection] = []

    /// Called if the view controller's post fails to load
    var postLoadFailureBlock: (() -> Void)? {
        didSet {
            coordinator?.postLoadFailureBlock = postLoadFailureBlock
        }
    }

    var currentPreferredStatusBarStyle = UIStatusBarStyle.lightContent {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var hidesBottomBarWhenPushed: Bool {
        set { }
        get { true }
    }

    /// Tracks whether the webview has called -didFinish:navigation
    var isLoadingWebView = true

    /// Temporary work around until white headers are shipped app-wide,
    /// allowing Reader Detail to use a blue navbar.
    var useCompatibilityMode: Bool {
        // This enables ALL Reader Detail screens to use a transparent navigation bar style,
        // so that the display settings can be applied correctly.
        //
        // Plus, it looks like we don't have screens with a blue (legacy) navigation bar anymore,
        // so it may be a good chance to clean up and remove `useCompatibilityMode`.
        !ReaderDisplaySetting.customizationEnabled
    }

    /// Used to disable ineffective buttons when a Related post fails to load.
    var enableRightBarButtons = true

    /// Track whether we've automatically navigated to the comments view or not.
    /// This may happen if we initialize our coordinator with a postURL that
    /// has a comment anchor fragment.
    private var hasAutomaticallyTriggeredCommentAction = false

    // Reader customization model
    private lazy var displaySettingStore: ReaderDisplaySettingStore = {
        let store = ReaderDisplaySettingStore()
        store.delegate = self
        return store
    }()

    // Convenient access to the underlying structure
    private var displaySetting: ReaderDisplaySetting {
        displaySettingStore.setting
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        applyStyles()
        configureWebView()
        configureFeaturedImage()
        configureHeader()
        configureRelatedPosts()
        configureToolbar()
        configureNoResultsViewController()
        observeWebViewHeight()
        configureNotifications()
        configureCommentsTable()

        coordinator?.start()

        startObservingPost()

        // Fixes swipe to go back not working when leftBarButtonItem is set
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        // When comments are moderated or edited from the Comments view, update the Comments snippet here.
        NotificationCenter.default.addObserver(self, selector: #selector(fetchComments), name: .ReaderCommentModifiedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLeftBarButtonItem()
        setupFeaturedImage()
        updateFollowButtonState()
        toolbar.viewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard let controller = navigationController, !controller.isBeingDismissed else {
            return
        }

        featuredImage.viewWillDisappear()
        toolbar.viewWillDisappear()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.featuredImage.deviceDidRotate()
        })
    }

    override func accessibilityPerformEscape() -> Bool {
        navigationController?.popViewController(animated: true)
        return true
    }

    func render(_ post: ReaderPost) {
        configureDiscoverAttribution(post)

        featuredImage.configure(for: post, with: self)
        toolbar.configure(for: post, in: self)
        header.configure(for: post)
        fetchLikes()
        fetchComments()

        if let postURLString = post.permaLink,
           let postURL = URL(string: postURLString) {
            webView.postURL = postURL
        }

        webView.isP2 = post.isP2Type()

        if post.content?.hasSuffix("[…]") == true {
            let viewMoreView = ReaderReadMoreView(post: post)
            webView.addSubview(viewMoreView)
            viewMoreView.pinEdges([.horizontal, .bottom])
        }

        coordinator?.storeAuthenticationCookies(in: webView) { [weak self] in
            self?.webView.loadHTMLString(post.contentForDisplay())
        }

        guard !featuredImage.isLoaded else {
            return
        }

        // Load the image
        featuredImage.load { [weak self] in
            self?.hideLoading()
        }

        navigateToCommentIfNecessary()
    }

    func renderRelatedPosts(_ posts: [RemoteReaderSimplePost]) {
        guard shouldFetchRelatedPosts else {
            return
        }

        shouldFetchRelatedPosts = false

        let groupedPosts = Dictionary(grouping: posts, by: { $0.postType })
        let sections = groupedPosts.map { RelatedPostsSection(postType: $0.key, posts: $0.value) }
        relatedPosts = sections.sorted { $0.postType.rawValue < $1.postType.rawValue }
        relatedPostsTableView.reloadData()
        relatedPostsTableView.invalidateIntrinsicContentSize()
    }

    private func navigateToCommentIfNecessary() {
        if let post,
           let commentID = coordinator?.commentID,
           !hasAutomaticallyTriggeredCommentAction {
            hasAutomaticallyTriggeredCommentAction = true

            ReaderCommentAction().execute(post: post,
                                          origin: self,
                                          promptToAddComment: false,
                                          navigateToCommentID: commentID,
                                          source: .postDetails)
        }
    }

    func showLoading() {
        if activityIndicator.superview == nil {
            for view in allContentViews {
                view.alpha = 0
            }
            scrollView.addSubview(activityIndicator)
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
                activityIndicator.topAnchor.constraint(equalTo: webView.topAnchor, constant: 64),
            ])
            activityIndicator.startAnimating()
        }
    }

    func hideLoading() {
        guard !featuredImage.isLoading, !isLoadingWebView else {
            return
        }

        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        UIView.animate(withDuration: 0.25) {
            for view in self.allContentViews {
                view.alpha = 1
            }
        }

        guard let post else {
            return
        }

        fetchRelatedPostsIfNeeded(for: post)
    }

    private var allContentViews: [UIView] {
        [webView, likesContainerView, commentsTableView, relatedPostsTableView, actionStackView]
    }

    func fetchRelatedPostsIfNeeded(for post: ReaderPost) {
        guard shouldFetchRelatedPosts else {
            return
        }

        coordinator?.fetchRelatedPosts(for: post)
    }

    /// Shown an error
    func showError(subtitle: String?) {
        isLoadingWebView = false
        hideLoading()

        displayLoadingView(title: LoadingText.errorLoadingTitle, subtitle: subtitle)
    }

    /// Shown an error with a button to open the post on the browser
    func showErrorWithWebAction() {
        displayLoadingViewWithWebAction(title: LoadingText.errorLoadingTitle)
    }

    /// Scroll the content to a given #hash
    ///
    func scroll(to hash: String) {
        webView.evaluateJavaScript("document.getElementById('\(hash)').offsetTop", completionHandler: { [weak self] height, _ in
            guard let self, let height = height as? CGFloat else {
                return
            }

            self.scrollView.setContentOffset(CGPoint(x: 0, y: height + self.webView.frame.origin.y), animated: true)
        })
    }

    func updateHeader() {
        header.refreshFollowButton()
    }

    func updateLikesView(with viewModel: ReaderDetailLikesViewModel) {
        guard viewModel.likeCount > 0 else {
            hideLikesView()
            return
        }
        if likesSummary.superview == nil {
            configureLikesSummary()
        }
        scrollView.layoutIfNeeded()

        likesSummary.configure(with: viewModel)
    }

    func updateComments(_ comments: [Comment], totalComments: Int) {
        guard let post else {
            DDLogError("Missing post when updating Reader post detail comments.")
            return
        }

        // Moderated comments could still be cached, so filter out non-approved comments.
        let approvedStatus = Comment.descriptionFor(.approved)
        let approvedComments = comments.filter({ $0.status == approvedStatus})

        // Set the delegate here so the table isn't shown until fetching is complete.
        commentsTableView.delegate = commentsTableViewDelegate
        commentsTableView.dataSource = commentsTableViewDelegate
        commentsTableViewDelegate.updateWith(post: post,
                                             comments: approvedComments,
                                             totalComments: totalComments,
                                             presentingViewController: self,
                                             buttonDelegate: self)

        commentsTableView.reloadData()
    }

    func updateFollowButtonState() {
        guard let post else {
            return
        }

        commentsTableViewDelegate.updateFollowButtonState(post: post)
    }

    deinit {
        scrollObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    /// Apply view styles
    @MainActor private func applyStyles() {
        guard let readableGuide = webView.superview?.readableContentGuide else {
            return
        }

        NSLayoutConstraint.activate([
            webView.rightAnchor.constraint(equalTo: readableGuide.rightAnchor, constant: -Constants.margin),
            webView.leftAnchor.constraint(equalTo: readableGuide.leftAnchor, constant: Constants.margin)
        ])

        webView.translatesAutoresizingMaskIntoConstraints = false

        // Webview is scroll is done by it's superview
        webView.scrollView.isScrollEnabled = false

        webView.displaySetting = displaySetting

        view.backgroundColor = displaySetting.color.background
    }

    private func applyDisplaySetting() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self else {
                return
            }

            // Main background view
            view.backgroundColor = displaySetting.color.background

            // Header view
            header.displaySetting = displaySetting

            // Toolbar
            toolbar.displaySetting = displaySetting
            toolbarSafeAreaView.backgroundColor = toolbar.backgroundColor
        }

        // Featured image view
        featuredImage.displaySetting = displaySetting

        // Update Reader Post web view
        if let contentForDisplay = post?.contentForDisplay() {
            webView.displaySetting = displaySetting
            webView.loadHTMLString(contentForDisplay)
        } else {
            // It's unexpected for the `post` or `contentForDisplay()` to be nil. Let's keep track of it.
            CrashLogging.main.logMessage("Expected contentForDisplay() to exist", level: .error)
        }

        // Likes view
        likesSummary.displaySetting = displaySetting

        // Comments table view
        commentsTableViewDelegate.displaySetting = displaySetting
        commentsTableView.reloadData()

        // Related posts table view
        relatedPostsTableView.reloadData()
    }

    /// Configure the webview
    private func configureWebView() {
        scrollView.delegate = self

        webView.navigationDelegate = self
    }

    /// Updates the webview height constraint with it's height
    private func observeWebViewHeight() {
        scrollObserver = webView.scrollView.observe(\.contentSize, options: .new) { [weak self] _, change in
            guard let self,
                  let height = change.newValue?.height else {
                return
            }

            /// ScrollHeight returned by JS is always more accurated as the value from the contentSize
            /// (except for a few times when it returns a very big weird number)
            /// We use that value so the content is not displayed with weird empty space at the bottom
            ///
            self.webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (webViewHeight, error) in
                guard let webViewHeight = webViewHeight as? CGFloat else {
                    self.webViewHeight.constant = height
                    return
                }

                /// The display setting's custom size is applied through the HTML's initial-scale property
                /// in the meta tag. The `scrollHeight` value seems to return the height as if it's at 1.0 scale,
                /// so we'll need to add the custom scale into account.
                let scaledWebViewHeight = round(webViewHeight * self.displaySetting.size.scale)
                self.webViewHeight.constant = min(scaledWebViewHeight, height)
            })
        }
    }

    private func setupFeaturedImage() {
        configureFeaturedImage()

        featuredImage.configure(
            scrollView: scrollView,
            navigationBar: navigationController?.navigationBar,
            navigationItem: navigationItem
        )

        guard !featuredImage.isLoaded else {
            return
        }

        // Load the image
        featuredImage.load { [weak self] in
            guard let self else {
                return
            }
            self.hideLoading()
        }
    }

    private func configureFeaturedImage() {
        guard featuredImage.superview == nil else {
            return
        }

        if ReaderDisplaySetting.customizationEnabled {
            featuredImage.displaySetting = displaySetting
        }

        featuredImage.useCompatibilityMode = useCompatibilityMode

        featuredImage.delegate = coordinator

        view.insertSubview(featuredImage, belowSubview: webView)

        NSLayoutConstraint.activate([
            featuredImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            featuredImage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            featuredImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
        ])

        headerContainerView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureHeader() {
        header.displaySetting = displaySetting
        header.delegate = coordinator
        headerContainerView.addSubview(header)
        headerContainerView.translatesAutoresizingMaskIntoConstraints = false

        headerContainerView.pinSubviewToAllEdges(header)
    }

    private func fetchLikes() {
        guard let post else {
            return
        }

        coordinator?.fetchLikes(for: post)
    }

    private func configureLikesSummary() {
        likesSummary.delegate = coordinator
        likesSummary.displaySetting = displaySetting
        likesContainerView.addSubview(likesSummary)
        likesContainerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            likesSummary.topAnchor.constraint(equalTo: likesContainerView.topAnchor),
            likesSummary.bottomAnchor.constraint(equalTo: likesContainerView.bottomAnchor),
            likesSummary.leadingAnchor.constraint(equalTo: likesContainerView.leadingAnchor),
            likesSummary.trailingAnchor.constraint(lessThanOrEqualTo: likesContainerView.trailingAnchor)
        ])
    }

    private func hideLikesView() {
        // Because other components are constrained to the likesContainerView, simply hiding it leaves a gap.
        likesSummary.removeFromSuperview()
        likesContainerView.frame.size.height = 0
        view.setNeedsDisplay()
    }

    @objc private func fetchComments() {
        guard let post else {
            return
        }

        coordinator?.fetchComments(for: post)
    }

    private func configureCommentsTable() {
        commentsTableView.separatorStyle = .none
        commentsTableView.backgroundColor = .clear
        commentsTableView.register(ReaderDetailCommentsHeader.defaultNib,
                                   forHeaderFooterViewReuseIdentifier: ReaderDetailCommentsHeader.defaultReuseID)
        commentsTableView.register(CommentContentTableViewCell.defaultNib,
                                   forCellReuseIdentifier: CommentContentTableViewCell.defaultReuseID)
        commentsTableView.register(ReaderDetailNoCommentCell.defaultNib,
                                   forCellReuseIdentifier: ReaderDetailNoCommentCell.defaultReuseID)
    }

    private func configureRelatedPosts() {
        relatedPostsTableView.isScrollEnabled = false
        relatedPostsTableView.separatorStyle = .none
        relatedPostsTableView.backgroundColor = .clear

        relatedPostsTableView.register(ReaderRelatedPostsCell.defaultNib,
                           forCellReuseIdentifier: ReaderRelatedPostsCell.defaultReuseID)
        relatedPostsTableView.register(ReaderRelatedPostsSectionHeaderView.defaultNib,
                           forHeaderFooterViewReuseIdentifier: ReaderRelatedPostsSectionHeaderView.defaultReuseID)

        relatedPostsTableView.dataSource = self
        relatedPostsTableView.delegate = self
    }

    private func configureToolbar() {
        if ReaderDisplaySetting.customizationEnabled {
            toolbar.displaySetting = displaySetting
        }
        toolbar.delegate = coordinator
        toolbarContainerView.addSubview(toolbar)

        // Unfortunately, this doesn't support self-sizing and dynamic type
        toolbar.heightAnchor.constraint(equalToConstant: 58).isActive = true
        toolbar.pinEdges([.top, .horizontal])
        toolbar.pinEdges(.bottom, to: view.safeAreaLayoutGuide, priority: .init(749)) // Break on hiding
    }

    private func configureDiscoverAttribution(_ post: ReaderPost) {
        if post.sourceAttributionStyle() == .none {
            attributionView.isHidden = true
        } else {
            attributionView.displayAsLink = true
            attributionView.translatesAutoresizingMaskIntoConstraints = false
            attributionView.configureViewWithVerboseSiteAttribution(post)
            attributionView.delegate = self
            attributionView.backgroundColor = .clear
        }
    }

    /// Configure the NoResultsViewController
    ///
    private func configureNoResultsViewController() {
        noResultsViewController.delegate = self
    }

    private func configureNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(siteBlocked(_:)),
                                               name: .ReaderSiteBlocked,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userBlocked(_:)),
                                               name: .ReaderUserBlockingDidEnd,
                                               object: nil)
    }

    @objc private func userBlocked(_ notification: Foundation.Notification) {
        dismiss()
    }

    @objc private func siteBlocked(_ notification: Foundation.Notification) {
        dismiss()
    }

    private func dismiss() {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }

    /// Ask the coordinator to present the share sheet
    ///
    @objc func didTapShareButton(_ sender: UIBarButtonItem) {
        coordinator?.share(fromAnchor: sender)
    }

    @objc func didTapBrowserButton(_ sender: UIBarButtonItem) {
        coordinator?.openInBrowser()
    }

    @objc func didTapDisplaySettingButton() {
        let viewController = ReaderDisplaySettingViewController(initialSetting: displaySetting,
                                                                source: .readerPostNavBar) { [weak self] newSetting in
            // no need to refresh if there are no changes to the display setting.
            guard let self,
                  newSetting != self.displaySetting else {
                return
            }

            self.displaySettingStore.setting = newSetting
            self.applyDisplaySetting()
        }

        let navController = UINavigationController(rootViewController: viewController)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
        }

        navigationController?.present(navController, animated: true)
    }

    /// A View Controller that displays a Post content.
    ///
    /// Use this method to present content for the user.
    /// - Parameter postID: a post identification
    /// - Parameter siteID: a site identification
    /// - Parameter isFeed: a Boolean indicating if the site is an external feed (not hosted at WPcom and not using Jetpack)
    /// - Returns: A `ReaderDetailViewController` instance
    @objc class func controllerWithPostID(_ postID: NSNumber, siteID: NSNumber, isFeed: Bool = false) -> ReaderDetailViewController {
        let controller = ReaderDetailViewController.loadFromStoryboard()
        let coordinator = ReaderDetailCoordinator(view: controller)
        coordinator.set(postID: postID, siteID: siteID, isFeed: isFeed)
        controller.coordinator = coordinator

        return controller
    }

    /// A View Controller that displays a Post content.
    ///
    /// Use this method to present content for the user.
    /// - Parameter url: an URL of the post.
    /// - Returns: A `ReaderDetailViewController` instance
    @objc class func controllerWithPostURL(_ url: URL) -> ReaderDetailViewController {
        let controller = ReaderDetailViewController.loadFromStoryboard()
        let coordinator = ReaderDetailCoordinator(view: controller)
        coordinator.postURL = url
        controller.coordinator = coordinator

        return controller
    }

    /// Creates an instance from a Related post / Simple Post
    /// - Parameter simplePost: The related post object
    /// - Returns: If the related post URL is not valid
    class func controllerWithSimplePost(_ simplePost: RemoteReaderSimplePost) -> ReaderDetailViewController? {
        guard !simplePost.postUrl.isEmpty(), let url = URL(string: simplePost.postUrl) else {
            return nil
        }

        let controller = ReaderDetailViewController.loadFromStoryboard()
        let coordinator = ReaderDetailCoordinator(view: controller)
        coordinator.postURL = url
        coordinator.remoteSimplePost = simplePost
        controller.coordinator = coordinator

        controller.postLoadFailureBlock = {
            controller.enableRightBarButtons = false
        }

        return controller
    }

    /// A View Controller that displays a Post content.
    ///
    /// Use this method to present content for the user.
    /// - Parameter post: a Reader Post
    /// - Returns: A `ReaderDetailViewController` instance
    @objc class func controllerWithPost(_ post: ReaderPost) -> ReaderDetailViewController {
        if post.sourceAttributionStyle() == .post &&
            post.sourceAttribution.postID != nil &&
            post.sourceAttribution.blogID != nil {
            return ReaderDetailViewController.controllerWithPostID(post.sourceAttribution.postID!, siteID: post.sourceAttribution.blogID!)
        } else if post.isCross() {
            return ReaderDetailViewController.controllerWithPostID(post.crossPostMeta.postID, siteID: post.crossPostMeta.siteID)
        } else {
            let controller = ReaderDetailViewController.loadFromStoryboard()
            let coordinator = ReaderDetailCoordinator(view: controller)
            coordinator.post = post
            controller.coordinator = coordinator
            return controller
        }
    }

    private enum Constants {
        static let margin: CGFloat = UIDevice.isPad() ? 0 : 8
    }

    // MARK: - Managed object observer

    func startObservingPost() {
        guard let post else {
            return
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleObjectsChange(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: post.managedObjectContext)
    }

    @objc func handleObjectsChange(_ notification: Foundation.Notification) {
        guard let post else {
            return
        }
        let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let refreshed = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> ?? Set()

        if updated.contains(post) || refreshed.contains(post) {
            header.configure(for: post)
        }
    }
}

extension ReaderDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard traitCollection.horizontalSizeClass == .compact else { return }

        let currentOffset = scrollView.contentOffset.y
        // Using `safeAreaLayoutGuide.layoutFrame.height` because it doesn't
        // change when we extend the scroll view size by hiding the toolbar
        if (currentOffset + view.safeAreaLayoutGuide.layoutFrame.height) > likesContainerView.frame.minY {
            setToolbarHidden(false, animated: true) // Reached bottom (controls, comments, etc)
        } else if currentOffset > lastContentOffset && currentOffset > 0 {
            setToolbarHidden(true, animated: true) // Scrolling down
        } else if currentOffset < lastContentOffset {
            setToolbarHidden(false, animated: false) // Scrolling up
        }
        lastContentOffset = currentOffset
    }

    private func setToolbarHidden(_ isHidden: Bool, animated: Bool) {
        guard isToolbarHidden != isHidden else { return }
        self.isToolbarHidden = isHidden

        UIView.animate(withDuration: 0.33, delay: 0.0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.toolbarHidingConstraint.isActive = isHidden
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - StoryboardLoadable

extension ReaderDetailViewController: StoryboardLoadable {
    static var defaultStoryboardName: String {
        return "ReaderDetailViewController"
    }
}

// MARK: - Related Posts

extension ReaderDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return relatedPosts.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return relatedPosts[section].posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReaderRelatedPostsCell.defaultReuseID, for: indexPath) as? ReaderRelatedPostsCell else {
            fatalError("Expected RelatedPostsTableViewCell with identifier: \(ReaderRelatedPostsCell.defaultReuseID)")
        }

        let post = relatedPosts[indexPath.section].posts[indexPath.row]
        cell.configure(for: post)

        // Additional style overrides
        cell.backgroundColor = .clear

        if ReaderDisplaySetting.customizationEnabled {
            cell.titleLabel.font = displaySetting.font(with: .body, weight: .semibold)
            cell.titleLabel.textColor = displaySetting.color.foreground

            cell.excerptLabel.font = displaySetting.font(with: .footnote)
            cell.excerptLabel.textColor = displaySetting.color.foreground
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = getSectionTitle(for: relatedPosts[section].postType),
              let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReaderRelatedPostsSectionHeaderView.defaultReuseID) as? ReaderRelatedPostsSectionHeaderView else {
            return UIView(frame: .zero)
        }

        header.titleLabel.text = title

        // Additional style overrides
        header.backgroundColorView.backgroundColor = .clear

        if ReaderDisplaySetting.customizationEnabled {
            header.titleLabel.font = displaySetting.font(with: .footnote, weight: .semibold)
            header.titleLabel.textColor = displaySetting.color.foreground
        }

        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return ReaderRelatedPostsSectionHeaderView.height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let post = relatedPosts[indexPath.section].posts[indexPath.row]

        guard let controller = ReaderDetailViewController.controllerWithSimplePost(post) else {
            return
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func getSectionTitle(for postType: RemoteReaderSimplePost.PostType) -> String? {
        switch postType {
        case .local:
            guard let blogName = post?.blogNameForDisplay() else {
                return nil
            }
            return String(format: Strings.localPostsSectionTitle, blogName)
        case .global:
            return Strings.globalPostsSectionTitle
        default:
            return nil
        }
    }
}

// MARK: - ReaderDisplaySettingStoreDelegate

extension ReaderDetailViewController: ReaderDisplaySettingStoreDelegate {
    func displaySettingDidChange() {
        applyDisplaySetting()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ReaderDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Reader Card Discover

extension ReaderDetailViewController: ReaderCardDiscoverAttributionViewDelegate {
    public func attributionActionSelectedForVisitingSite(_ view: ReaderCardDiscoverAttributionView) {
        coordinator?.showMore()
    }
}

// MARK: - UpdatableStatusBarStyle
extension ReaderDetailViewController: UpdatableStatusBarStyle {
    func updateStatusBarStyle(to style: UIStatusBarStyle) {
        guard style != currentPreferredStatusBarStyle else {
            return
        }

        currentPreferredStatusBarStyle = style
    }
}

// MARK: - Transitioning Delegate

extension ReaderDetailViewController: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented is FancyAlertViewController else {
            return nil
        }

        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

// MARK: - Navigation Delegate

extension ReaderDetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        coordinator?.webViewDidLoad()
        self.webView.loadMedia()

        isLoadingWebView = false
        hideLoading()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url {
                coordinator?.handle(url)
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

// MARK: - Error View Handling (NoResultsViewController)

private extension ReaderDetailViewController {
    func displayLoadingView(title: String, subtitle: String? = nil, accessoryView: UIView? = nil) {
        noResultsViewController.configure(title: title, subtitle: subtitle, accessoryView: accessoryView)
        showLoadingView()
    }

    func displayLoadingViewWithWebAction(title: String, accessoryView: UIView? = nil) {
        noResultsViewController.configure(title: title,
                                          buttonTitle: LoadingText.errorLoadingPostURLButtonTitle,
                                          accessoryView: accessoryView)
        showLoadingView()
    }

    func showLoadingView() {
        hideLoadingView()
        addChild(noResultsViewController)
        view.addSubview(withFadeAnimation: noResultsViewController.view)
        noResultsViewController.didMove(toParent: self)

        noResultsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(noResultsViewController.view)
    }

    func hideLoadingView() {
        noResultsViewController.removeFromView()
    }

    struct LoadingText {
        static let errorLoadingTitle = NSLocalizedString("Error Loading Post", comment: "Text displayed when load post fails.")
        static let errorLoadingPostURLButtonTitle = NSLocalizedString("Open in browser", comment: "Button title to load a post in an in-app web view")
    }

}

// MARK: - Navigation Bar Configuration
private extension ReaderDetailViewController {

    func configureNavigationBar() {
        // If a Related post fails to load, disable the More and Share buttons as they won't do anything.
        let rightItems = [
            moreButtonItem(enabled: enableRightBarButtons),
            shareButtonItem(enabled: enableRightBarButtons),
            safariButtonItem()
        ]
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItems = rightItems.compactMap({ $0 })
    }

    /// Updates the left bar button item based on the current view controller's context in the navigation stack.
    /// If the view controller is presented modally and does not have a left bar button item, a dismiss button is set.
    /// If the view controller is not the root of the navigation stack, a back button is set.
    /// Otherwise, the left bar button item is cleared.
    func updateLeftBarButtonItem() {
        if isModal(), navigationItem.leftBarButtonItem == nil {
            navigationItem.leftBarButtonItem = dismissButtonItem()
        } else if navigationController?.viewControllers.first !== self {
            navigationItem.leftBarButtonItem = backButtonItem()
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }

    func backButtonItem() -> UIBarButtonItem {
        let config = UIImage.SymbolConfiguration(weight: .semibold)
        let image = UIImage(systemName: "chevron.backward", withConfiguration: config) ?? .gridicon(.chevronLeft)
        let button = barButtonItem(with: image, action: #selector(didTapBackButton(_:)))
        button.accessibilityLabel = Strings.backButtonAccessibilityLabel
        return button
    }

    @objc func didTapBackButton(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    func dismissButtonItem() -> UIBarButtonItem {
        let button = barButtonItem(with: .gridicon(.chevronDown), action: #selector(didTapDismissButton(_:)))
        button.accessibilityLabel = Strings.dismissButtonAccessibilityLabel

        return button
    }

    @objc func didTapDismissButton(_ sender: UIButton) {
        dismiss(animated: true)
    }

    func safariButtonItem() -> UIBarButtonItem? {
        let button = barButtonItem(with: .gridicon(.globe), action: #selector(didTapBrowserButton(_:)))
        button.accessibilityLabel = Strings.safariButtonAccessibilityLabel

        return button
    }

    func moreButtonItem(enabled: Bool = true) -> UIBarButtonItem? {
        let button = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: nil)
        button.menu = UIMenu(options: .displayInline, children: [
            UIDeferredMenuElement.uncached { [weak self, weak button] callback in
                guard let self, let button else {
                    return callback([])
                }
                callback(self.makeMoreMenu(button))
            }
        ])
        button.accessibilityLabel = Strings.moreButtonAccessibilityLabel
        button.isEnabled = enabled
        return button
    }

    func makeMoreMenu(_ anchor: UIPopoverPresentationControllerSourceItem) -> [UIMenuElement] {
        guard let post else {
            return []
        }
        var elements = ReaderPostMenu(
            post: post,
            topic: nil,
            anchor: anchor,
            viewController: self
        ).makeMenu()

        if ReaderDisplaySetting.customizationEnabled {
            elements.append(UIAction(title: Strings.displaySettingsLabel, image: UIImage(systemName: "textformat.size")) { [weak self] _ in
                self?.didTapDisplaySettingButton()
            })
        }

        return elements
    }

    func shareButtonItem(enabled: Bool = true) -> UIBarButtonItem? {
        let button = barButtonItem(with: .gridicon(.shareiOS), action: #selector(didTapShareButton(_:)))
        button.accessibilityLabel = Strings.shareButtonAccessibilityLabel
        button.isEnabled = enabled

        return button
    }

    func barButtonItem(with image: UIImage, action: Selector) -> UIBarButtonItem {
        let image = image.withRenderingMode(.alwaysTemplate)
        return UIBarButtonItem(image: image, style: .plain, target: self, action: action)
    }

    /// Checks if the view is visible in the viewport.
    func isVisibleInScrollView(_ view: UIView) -> Bool {
        guard view.superview != nil, !view.isHidden else {
            return false
        }

        let scrollViewFrame = CGRect(origin: scrollView.contentOffset, size: scrollView.frame.size)
        let convertedViewFrame = scrollView.convert(view.bounds, from: view)
        return scrollViewFrame.intersects(convertedViewFrame)
    }
}

// MARK: - NoResultsViewControllerDelegate
///
extension ReaderDetailViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        coordinator?.openInBrowser()
    }
}

// MARK: - Strings
extension ReaderDetailViewController {
    private struct Strings {
        static let backButtonAccessibilityLabel = NSLocalizedString(
            "readerDetail.backButton.accessibilityLabel",
            value: "Back",
            comment: "Spoken accessibility label"
        )
        static let dismissButtonAccessibilityLabel = NSLocalizedString(
            "readerDetail.dismissButton.accessibilityLabel",
            value: "Dismiss",
            comment: "Spoken accessibility label"
        )
        static let displaySettingsLabel = NSLocalizedString(
            "readerDetail.displaySettingButton.displaySettingsLabel",
            value: "Reading Preferences",
            comment: "Spoken accessibility label for the Reading Preferences menu.")
        static let safariButtonAccessibilityLabel = NSLocalizedString(
            "readerDetail.safariButton.accessibilityLabel",
            value: "Open in Safari",
            comment: "Spoken accessibility label"
        )
        static let shareButtonAccessibilityLabel = NSLocalizedString(
            "readerDetail.shareButton.accessibilityLabel",
            value: "Share",
            comment: "Spoken accessibility label"
        )
        static let moreButtonAccessibilityLabel = NSLocalizedString(
            "readerDetail.moreButton.accessibilityLabel",
            value: "More",
            comment: "Spoken accessibility label"
        )
        static let localPostsSectionTitle = NSLocalizedString(
            "readerDetail.localPostsSection.accessibilityLabel",
            value: "More from %1$@",
            comment: "Section title for local related posts. %1$@ is a placeholder for the blog display name."
        )
        static let globalPostsSectionTitle = NSLocalizedString(
            "readerDetail.globalPostsSection.accessibilityLabel",
            value: "More on WordPress.com",
            comment: "Section title for global related posts."
        )
    }
}

// MARK: - BorderedButtonTableViewCellDelegate
// For the `View All Comments` button.
extension ReaderDetailViewController: BorderedButtonTableViewCellDelegate {
    func buttonTapped() {
        guard let post else {
            return
        }

        ReaderCommentAction().execute(post: post,
                                      origin: self,
                                      promptToAddComment: commentsTableViewDelegate.totalComments == 0,
                                      source: .postDetailsComments)
    }
}
