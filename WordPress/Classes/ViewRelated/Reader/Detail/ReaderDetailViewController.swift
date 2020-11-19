import UIKit

protocol ReaderDetailView: class {
    func render(_ post: ReaderPost)
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

    /// Comment view, add action bar
    private let commentAction: ReaderDetailCommentsView = .loadFromNib()

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

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        applyStyles()
        configureWebView()
        configureFeaturedImage()
        configureHeader()
        configureToolbar()
        configureNoResultsViewController()
        observeWebViewHeight()
        configureNotifications()
        configureCommentAction()

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

    func render(_ post: ReaderPost) {
        configureDiscoverAttribution(post)

        featuredImage.configure(for: post, with: self)
        toolbar.configure(for: post, in: self)
        header.configure(for: post)
        commentAction.configure(for: post, in: self)

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
    }

    /// Shown an error
    func showError() {
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
        header.delegate = coordinator
        headerContainerView.addSubview(header)
        headerContainerView.pinSubviewToAllEdges(header)
        headerContainerView.heightAnchor.constraint(equalTo: header.heightAnchor).isActive = true
        headerContainerView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureToolbar() {
        toolbarContainerView.addSubview(toolbar)
        toolbarContainerView.pinSubviewToAllEdges(toolbar)
        toolbarContainerView.translatesAutoresizingMaskIntoConstraints = false
        toolbarSafeAreaView.backgroundColor = toolbar.backgroundColor
    }

    private func configureCommentAction() {
        actionStackView.insertArrangedSubview(commentAction, at: 0)
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
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
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
    struct Strings {
        static let backButtonAccessibilityLabel = NSLocalizedString("Back", comment: "Spoken accessibility label")
        static let safariButtonAccessibilityLabel = NSLocalizedString("Open in Safari", comment: "Spoken accessibility label")
        static let shareButtonAccessibilityLabel = NSLocalizedString("Share", comment: "Spoken accessibility label")
        static let moreButtonAccessibilityLabel = NSLocalizedString("More", comment: "Spoken accessibility label")
    }

    func configureNavigationBar() {
        let rightItems = [
            moreButtonItem(),
            shareButtonItem(),
            safariButtonItem()
        ]

        navigationItem.leftBarButtonItem = backButtonItem()
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

    func safariButtonItem() -> UIBarButtonItem? {
        let button = barButtonItem(with: .gridicon(.globe), action: #selector(didTapBrowserButton(_:)))
        button.accessibilityLabel = Strings.safariButtonAccessibilityLabel

        return button
    }

    func moreButtonItem() -> UIBarButtonItem? {
        guard let icon = UIImage(named: "icon-menu-vertical-ellipsis") else {
            return nil
        }

        let button = barButtonItem(with: icon, action: #selector(didTapMenuButton(_:)))
        button.accessibilityLabel = Strings.moreButtonAccessibilityLabel
        return button
    }

    func shareButtonItem() -> UIBarButtonItem? {
        let button = barButtonItem(with: .gridicon(.shareiOS), action: #selector(didTapShareButton(_:)))
        button.accessibilityLabel = Strings.shareButtonAccessibilityLabel

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
