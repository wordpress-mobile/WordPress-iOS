import UIKit

typealias RelatedPostsSection = (postType: RemoteReaderSimplePost.PostType, posts: [RemoteReaderSimplePost])

protocol ReaderDetailView: class {
    func render(_ post: ReaderPost)
    func renderRelatedPosts(_ posts: [RemoteReaderSimplePost])
    func showLoading()
    func showError()
    func showErrorWithWebAction()
    func scroll(to: String)
    func updateHeader()
}

class ReaderDetailViewController: UIViewController, ReaderDetailView {

    /// Content scroll view
    @IBOutlet weak var scrollView: UIScrollView!

    /// A ReaderWebView
    @IBOutlet weak var webView: ReaderWebView!

    /// WebView height constraint
    @IBOutlet weak var webViewHeight: NSLayoutConstraint!

    /// The table view that displays Related Posts
    @IBOutlet weak var tableView: IntrinsicTableView!

    /// Header container
    @IBOutlet weak var headerContainerView: UIView!

    /// Wrapper for the toolbar
    @IBOutlet weak var toolbarContainerView: UIView!

    /// The loading view, which contains all the ghost views
    @IBOutlet weak var loadingView: UIView!

    /// The loading view, which contains all the ghost views
    @IBOutlet weak var actionStackView: UIStackView!

    /// Attribution view for Discovery posts
    @IBOutlet weak var attributionView: ReaderCardDiscoverAttributionView!

    /// The actual header
    private let featuredImage: ReaderDetailFeaturedImageView = .loadFromNib()

    /// The actual header
    private let header: ReaderDetailHeaderView = .loadFromNib()

    /// Bottom toolbar
    private let toolbar: ReaderDetailToolbar = .loadFromNib()

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

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return currentPreferredStatusBarStyle
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
        // Use compatibility mode if not presented within the Reader
        return WPTabBarController.sharedInstance()?.readerNavigationController.viewControllers.contains(self) == false
    }

    /// Used to disable ineffective buttons when a Related post fails to load.
    var enableRightBarButtons = true

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

        coordinator?.start()

        // Fixes swipe to go back not working when leftBarButtonItem is set
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureFeaturedImage()

        featuredImage.configure(scrollView: scrollView,
                                navigationBar: navigationController?.navigationBar)

        featuredImage.applyTransparentNavigationBarAppearance(to: navigationController?.navigationBar)

        guard !featuredImage.isLoaded else {
            return
        }

        // Load the image
        featuredImage.load { [unowned self] in
            self.hideLoading()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard let controller = navigationController, !controller.isBeingDismissed else {
            return
        }

        featuredImage.viewWillDisappear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ReaderTracker.shared.start(.readerPost)

        // Reapply the appearance, this reset the navbar after presenting a view
        featuredImage.applyTransparentNavigationBarAppearance(to: navigationController?.navigationBar)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ReaderTracker.shared.stop(.readerPost)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.featuredImage.deviceDidRotate()
        })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Bar items may change if we're moving single pane to split view
        self.configureNavigationBar()
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

        if let postURLString = post.permaLink,
           let postURL = URL(string: postURLString) {
            webView.postURL = postURL
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
    }

    func renderRelatedPosts(_ posts: [RemoteReaderSimplePost]) {
        let groupedPosts = Dictionary(grouping: posts, by: { $0.postType })
        let sections = groupedPosts.map { RelatedPostsSection(postType: $0.key, posts: $0.value) }
        relatedPosts = sections.sorted { $0.postType.rawValue < $1.postType.rawValue }
        tableView.reloadData()
        tableView.invalidateIntrinsicContentSize()
    }

    /// Show ghost cells indicating the content is loading
    func showLoading() {
        let style = GhostStyle(beatDuration: GhostStyle.Defaults.beatDuration,
                               beatStartColor: .placeholderElement,
                               beatEndColor: .placeholderElementFaded)

        loadingView.startGhostAnimation(style: style)
    }

    /// Hide the ghost cells
    func hideLoading() {
        guard !featuredImage.isLoading, !isLoadingWebView else {
            return
        }

        UIView.animate(withDuration: 0.3, animations: {
            self.loadingView.alpha = 0.0
        }) { (_) in
            self.loadingView.isHidden = true
            self.loadingView.stopGhostAnimation()
            self.loadingView.alpha = 1.0
        }

        guard let post = post else {
            return
        }

        coordinator?.fetchRelatedPosts(for: post)
    }

    /// Shown an error
    func showError() {
        isLoadingWebView = false
        hideLoading()

        displayLoadingView(title: LoadingText.errorLoadingTitle)
    }

    /// Shown an error with a button to open the post on the browser
    func showErrorWithWebAction() {
        displayLoadingViewWithWebAction(title: LoadingText.errorLoadingTitle)
    }

    @objc func willEnterForeground() {
        guard isViewOnScreen() else {
            return
        }

        ReaderTracker.shared.start(.readerPost)
    }

    /// Scroll the content to a given #hash
    ///
    func scroll(to hash: String) {
        webView.evaluateJavaScript("document.getElementById('\(hash)').offsetTop", completionHandler: { [unowned self] height, _ in
            guard let height = height as? CGFloat else {
                return
            }

            self.scrollView.setContentOffset(CGPoint(x: 0, y: height + self.webView.frame.origin.y), animated: true)
        })
    }

    func updateHeader() {
        header.refreshFollowButton()
    }

    deinit {
        scrollObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    /// Apply view styles
    private func applyStyles() {
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
    }

    /// Configure the webview
    private func configureWebView() {
        webView.navigationDelegate = self
    }

    /// Updates the webview height constraint with it's height
    private func observeWebViewHeight() {
        scrollObserver = webView.scrollView.observe(\.contentSize, options: .new) { [weak self] _, change in
            guard let height = change.newValue?.height else {
                return
            }

            /// ScrollHeight returned by JS is always more accurated as the value from the contentSize
            /// (except for a few times when it returns a very big weird number)
            /// We use that value so the content is not displayed with weird empty space at the bottom
            ///
            self?.webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (webViewHeight, error) in
                guard let webViewHeight = webViewHeight as? CGFloat else {
                    self?.webViewHeight.constant = height
                    return
                }

                self?.webViewHeight.constant = min(height, webViewHeight)
            })
        }
    }

    private func configureFeaturedImage() {
        guard featuredImage.superview == nil else {
            return
        }

        featuredImage.useCompatibilityMode = useCompatibilityMode

        featuredImage.delegate = coordinator

        view.insertSubview(featuredImage, belowSubview: loadingView)

        NSLayoutConstraint.activate([
            featuredImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            featuredImage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            featuredImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
        ])

        headerContainerView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureHeader() {
        header.useCompatibilityMode = useCompatibilityMode
        header.delegate = coordinator
        headerContainerView.addSubview(header)
        headerContainerView.translatesAutoresizingMaskIntoConstraints = false

        headerContainerView.pinSubviewToAllEdges(header)
        headerContainerView.heightAnchor.constraint(equalTo: header.heightAnchor).isActive = true
    }

    private func configureRelatedPosts() {
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none

        tableView.register(ReaderRelatedPostsCell.defaultNib,
                           forCellReuseIdentifier: ReaderRelatedPostsCell.defaultReuseID)
        tableView.register(ReaderRelatedPostsSectionHeaderView.defaultNib,
                           forHeaderFooterViewReuseIdentifier: ReaderRelatedPostsSectionHeaderView.defaultReuseID)

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func configureToolbar() {
        toolbarContainerView.addSubview(toolbar)
        toolbarContainerView.translatesAutoresizingMaskIntoConstraints = false

        toolbarContainerView.pinSubviewToAllEdges(toolbar)
        toolbarSafeAreaView.backgroundColor = toolbar.backgroundColor
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
                                               selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(siteBlocked(_:)),
                                               name: .ReaderSiteBlocked,
                                               object: nil)
    }

    @objc private func siteBlocked(_ notification: Foundation.Notification) {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }

    /// Ask the coordinator to present the share sheet
    ///
    @objc func didTapShareButton(_ sender: UIButton) {
        coordinator?.share(fromView: sender)
    }

    @objc func didTapMenuButton(_ sender: UIButton) {
        coordinator?.didTapMenuButton(sender)
    }

    @objc func didTapBrowserButton(_ sender: UIButton) {
        coordinator?.openInBrowser()
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
        static let bottomMargin: CGFloat = 16
        static let toolbarHeight: CGFloat = 50
        static let delay: Double = 50
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

        // Related posts should be presented in its own nav stack,
        // so that a user can return to the original post by dismissing the related posts nav stack.
        if navigationController?.viewControllers.first is ReaderDetailViewController {
            navigationController?.pushViewController(controller, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: controller)
            self.present(nav, animated: true)
        }
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
    func displayLoadingView(title: String, accessoryView: UIView? = nil) {
        noResultsViewController.configure(title: title, accessoryView: accessoryView)
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

        if !isModal() {
            navigationItem.leftBarButtonItem = backButtonItem()
        } else {
            navigationItem.leftBarButtonItem = dismissButtonItem()
        }
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItems = rightItems.compactMap({ $0 })
    }

    func backButtonItem() -> UIBarButtonItem {
        let button = barButtonItem(with: .gridicon(.chevronLeft), action: #selector(didTapBackButton(_:)))
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
        guard let icon = UIImage(named: "icon-menu-vertical-ellipsis") else {
            return nil
        }

        let button = barButtonItem(with: icon, action: #selector(didTapMenuButton(_:)))
        button.accessibilityLabel = Strings.moreButtonAccessibilityLabel
        button.isEnabled = enabled

        return button
    }

    func shareButtonItem(enabled: Bool = true) -> UIBarButtonItem? {
        let button = barButtonItem(with: .gridicon(.shareiOS), action: #selector(didTapShareButton(_:)))
        button.accessibilityLabel = Strings.shareButtonAccessibilityLabel
        button.isEnabled = enabled

        return button
    }

    func barButtonItem(with image: UIImage, action: Selector) -> UIBarButtonItem {
        let image = image.withRenderingMode(.alwaysTemplate)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44.0, height: image.size.height))
        button.setImage(image, for: UIControl.State())
        button.addTarget(self, action: action, for: .touchUpInside)

        return UIBarButtonItem(customView: button)
    }
}

// MARK: - NoResultsViewControllerDelegate
///
extension ReaderDetailViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        coordinator?.openInBrowser()
    }
}

// MARK: - State Restoration

extension ReaderDetailViewController: UIViewControllerRestoration {
    public static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                                      coder: NSCoder) -> UIViewController? {
        return ReaderDetailCoordinator.viewController(withRestorationIdentifierPath: identifierComponents, coder: coder)
    }


    open override func encodeRestorableState(with coder: NSCoder) {
        coordinator?.encodeRestorableState(with: coder)

        super.encodeRestorableState(with: coder)
    }

    open override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        restorationClass = type(of: self)

        return super.awakeAfter(using: aDecoder)
    }
}

// MARK: - Strings
extension ReaderDetailViewController {

    private struct Strings {
        static let backButtonAccessibilityLabel = NSLocalizedString("Back", comment: "Spoken accessibility label")
        static let dismissButtonAccessibilityLabel = NSLocalizedString("Dismiss", comment: "Spoken accessibility label")
        static let safariButtonAccessibilityLabel = NSLocalizedString("Open in Safari", comment: "Spoken accessibility label")
        static let shareButtonAccessibilityLabel = NSLocalizedString("Share", comment: "Spoken accessibility label")
        static let moreButtonAccessibilityLabel = NSLocalizedString("More", comment: "Spoken accessibility label")
        static let localPostsSectionTitle = NSLocalizedString("More from %1$@", comment: "Section title for local related posts. %1$@ is a placeholder for the blog display name.")
        static let globalPostsSectionTitle = NSLocalizedString("More on WordPress.com", comment: "Section title for global related posts.")
    }
}

// MARK: - DefinesVariableStatusBarStyle
// Allows this VC to control the statusbar style dynamically
extension ReaderDetailViewController: DefinesVariableStatusBarStyle {}
