import UIKit
import AMScrollingNavbar

protocol ReaderDetailView: class {
    func render(_ post: ReaderPost)
    func showLoading()
    func showError()
    func showErrorWithWebAction()
    func show(title: String?)
    func scroll(to: String)
}

class ReaderDetailViewController: UIViewController, ReaderDetailView {
    /// Content scroll view
    @IBOutlet weak var scrollView: ReaderScrollView!

    /// A ReaderWebView
    @IBOutlet weak var webView: ReaderWebView!

    /// WebView height constraint
    @IBOutlet weak var webViewHeight: NSLayoutConstraint!

    /// Header container
    @IBOutlet weak var headerContainerView: UIView!

    /// Wrapper for the attribution view
    @IBOutlet weak var attributionViewContainer: UIStackView!

    /// Wrapper for the toolbar
    @IBOutlet weak var toolbarContainerView: UIView!

    /// The loading view, which contains all the ghost views
    @IBOutlet weak var loadingView: UIView!

    /// Attribution view for Discovery posts
    private let attributionView: ReaderCardDiscoverAttributionView = .loadFromNib()

    /// The actual header
    private let header: ReaderDetailHeaderView = .loadFromNib()

    /// Bottom toolbar
    private let toolbar: ReaderDetailToolbar = .loadFromNib()

    /// View used to show errors
    private let noResultsViewController = NoResultsViewController.controller()

    /// An observer of the content size of the webview
    private var scrollObserver: NSKeyValueObservation?

    /// If we're following the scrollview to hide/show nav and toolbar
    private var isFollowingScrollView = false

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

    override func viewDidLoad() {
        super.viewDidLoad()

        applyStyles()
        configureWebView()
        configureShareButton()
        configureHeader()
        configureToolbar()
        configureScrollView()
        configureNoResultsViewController()
        observeWebViewHeight()
        configureNotifications()
        coordinator?.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        followScrollView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ReaderTracker.shared.start(.readerPost)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopFollowingScrollView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ReaderTracker.shared.stop(.readerPost)
    }

    func render(_ post: ReaderPost) {
        configureDiscoverAttribution(post)
        toolbar.configure(for: post, in: self)
        header.configure(for: post)

        coordinator?.storeAuthenticationCookies(in: webView) { [weak self] in
            self?.webView.loadHTMLString(post.contentForDisplay())
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
        loadingView.stopGhostAnimation()
        loadingView.isHidden = true
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

    /// Show a given title
    ///
    /// - Parameter title: a optional String containing the title
    func show(title: String?) {
        let placeholder = NSLocalizedString("Post", comment: "Placeholder title for ReaderPostDetails.")
        let titleView = UILabel()

        titleView.attributedText = NSAttributedString(string: title ?? placeholder, attributes: UINavigationBar.standardTitleTextAttributes())
        navigationItem.titleView = titleView
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

    /// Adds the sahre button at the right of the nav bar
    ///
    private func configureShareButton() {
        let image = UIImage.gridicon(.shareiOS).withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        let button = CustomHighlightButton(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        button.setImage(image, for: UIControl.State())
        button.addTarget(self, action: #selector(didTapShareButton(_:)), for: .touchUpInside)

        let shareButton = UIBarButtonItem(customView: button)
        shareButton.accessibilityLabel = NSLocalizedString("Share", comment: "Spoken accessibility label")
        WPStyleGuide.setRightBarButtonItemWithCorrectSpacing(shareButton, for: navigationItem)
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
    }

    private func configureDiscoverAttribution(_ post: ReaderPost) {
        if post.sourceAttributionStyle() == .none {
            attributionView.isHidden = true
        } else {
            attributionView.displayAsLink = true
            attributionViewContainer.addSubview(attributionView)
            attributionViewContainer.pinSubviewToAllEdges(attributionView)
            attributionView.translatesAutoresizingMaskIntoConstraints = false
            attributionView.configureViewWithVerboseSiteAttribution(post)
            attributionView.delegate = self
        }
    }

    /// Add content and scroll insets based on the toolbar height
    ///
    private func configureScrollView() {
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Constants.bottomMargin + Constants.toolbarHeight, right: 0)
        scrollView.navigationBar = navigationController?.navigationBar
        scrollView.delegate = self
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

    /// Start following the scroll view to hide nav bar and toolbar
    /// Only if VoiceOver is not active
    ///
    private func followScrollView() {
        if isFollowingScrollView,
            UIAccessibility.isVoiceOverRunning {
            return
        }

        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.followScrollView(scrollView, delay: Constants.delay, followers: [NavigationBarFollower(view: toolbarContainerView, direction: .scrollDown)])
            navigationController.shouldUpdateContentInset = false
            isFollowingScrollView = true
        }
    }

    /// Stop following the scroll view to hide nav bar and toolbar
    ///
    private func stopFollowingScrollView() {
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.stopFollowingScrollView(showingNavbar: true)
            isFollowingScrollView = false
        }
    }

    /// Update scroll view insets to take into account if toolbar is visible or not
    private func updateScrollInsets(toolbarVisible: Bool) {
        let bottomInset: CGFloat = toolbarVisible ? Constants.toolbarHeight : 0
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
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

// MARK: - Reader Card Discover

extension ReaderDetailViewController: ReaderCardDiscoverAttributionViewDelegate {
    public func attributionActionSelectedForVisitingSite(_ view: ReaderCardDiscoverAttributionView) {
        coordinator?.showMore()
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
        self.webView.loadMedia()
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

// MARK: - NoResultsViewControllerDelegate
///
extension ReaderDetailViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        coordinator?.openInBrowser()
    }
}

// MARK: - Scroll View Delegate

extension ReaderDetailViewController: UIScrollViewDelegate {
    // If we're at the end of the article, show nav bar and toolbar when the user stops scrolling
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height + scrollView.contentInset.bottom - scrollView.frame.size.height - toolbar.frame.height {
            guard let navigationController = self.navigationController as? ScrollingNavigationController,
                navigationController.state != .expanded else {
                    return
            }

            stopFollowingScrollView()
            updateScrollInsets(toolbarVisible: true)
        } else {
            followScrollView()
            updateScrollInsets(toolbarVisible: false)
        }
    }

    /// Show the nav bar when scrolling to top
    ///
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.showNavbar(animated: true, scrollToTop: true)
        }
        return true
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

// MARK: - PrefersFullscreenDisplay (iPad)

// Expand this view controller to full screen if possible
extension ReaderDetailViewController: PrefersFullscreenDisplay {}

// MARK: - DefinesVariableStatusBarStyle (iPad)

// Let's the split view know this vc changes the status bar style.
extension ReaderDetailViewController: DefinesVariableStatusBarStyle {}
