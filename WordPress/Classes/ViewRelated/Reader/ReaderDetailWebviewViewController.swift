import UIKit

protocol ReaderDetailView: class {
    func render(_ post: ReaderPost)
    func showError()
    func show(title: String?)
}

class ReaderDetailWebviewViewController: UIViewController, ReaderDetailView {
    /// Content scroll view
    @IBOutlet weak var scrollView: UIScrollView!

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

    /// Attribution view for Discovery posts
    private let attributionView: ReaderCardDiscoverAttributionView = .loadFromNib()

    /// The actual header
    private let header: ReaderDetailHeaderView = .loadFromNib()

    /// Bottom toolbar
    private let toolbar: ReaderDetailToolbar = .loadFromNib()

    /// An observer of the content size of the webview
    private var scrollObserver: NSKeyValueObservation?

    /// The coordinator, responsible for the logic
    var coordinator: ReaderDetailCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()

        applyStyles()
        configureShareButton()
        configureHeader()
        configureToolbar()
        configureScrollView()
        observeWebViewHeight()
        coordinator?.start()
    }

    func render(_ post: ReaderPost) {
        configureDiscoverAttribution(post)
        toolbar.configure(for: post, in: self)
        header.configure(for: post)
        webView.loadHTMLString(post.contentForDisplay(), baseURL: nil)
    }

    func showError() {
        /// TODO: Show error
    }

    func show(title: String?) {
        let placeholder = NSLocalizedString("Post", comment: "Placeholder title for ReaderPostDetails.")
        self.title = title ?? placeholder
    }

    deinit {
        scrollObserver?.invalidate()
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
        if post.sourceAttributionStyle() == SourceAttributionStyle.none {
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
        let toolbarHeight = toolbarContainerView.frame.height
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: toolbarHeight + Constants.bottomMargin, right: 0)
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: toolbarHeight, right: 0)
    }

    /// Ask the coordinator to present the share sheet
    ///
    @objc func didTapShareButton(_ sender: UIButton) {
        coordinator?.share(fromView: sender)
    }

    /// A View Controller that displays a Post content.
    ///
    /// Use this method to present content for the user.
    /// - Parameter postID: a post identification
    /// - Parameter siteID: a site identification
    /// - Parameter isFeed: a Boolean indicating if the site is an external feed (not hosted at WPcom and not using Jetpack)
    /// - Returns: A `ReaderDetailWebviewViewController` instance
    @objc class func controllerWithPostID(_ postID: NSNumber, siteID: NSNumber, isFeed: Bool = false) -> ReaderDetailWebviewViewController {
        let controller = ReaderDetailWebviewViewController.loadFromStoryboard()
        let coordinator = ReaderDetailCoordinator(view: controller)
        coordinator.set(postID: postID, siteID: siteID, isFeed: isFeed)
        controller.coordinator = coordinator

        return controller
    }

    /// A View Controller that displays a Post content.
    ///
    /// Use this method to present content for the user.
    /// - Parameter url: an URL of the post.
    /// - Returns: A `ReaderDetailWebviewViewController` instance
    @objc class func controllerWithPostURL(_ url: URL) -> ReaderDetailWebviewViewController {
        let controller = ReaderDetailWebviewViewController.loadFromStoryboard()

        return controller
    }

    /// A View Controller that displays a Post content.
    ///
    /// Use this method to present content for the user.
    /// - Parameter post: a Reader Post
    /// - Returns: A `ReaderDetailWebviewViewController` instance
    @objc class func controllerWithPost(_ post: ReaderPost) -> ReaderDetailWebviewViewController {
        if post.sourceAttributionStyle() == .post &&
            post.sourceAttribution.postID != nil &&
            post.sourceAttribution.blogID != nil {
            return ReaderDetailWebviewViewController.controllerWithPostID(post.sourceAttribution.postID!, siteID: post.sourceAttribution.blogID!)
        } else if post.isCross() {
            return ReaderDetailWebviewViewController.controllerWithPostID(post.crossPostMeta.postID, siteID: post.crossPostMeta.siteID)
        } else {
            let controller = ReaderDetailWebviewViewController.loadFromStoryboard()
            let coordinator = ReaderDetailCoordinator(view: controller)
            coordinator.post = post
            controller.coordinator = coordinator
            return controller
        }
    }

    private enum Constants {
        static let margin: CGFloat = UIDevice.isPad() ? 0 : 8
        static let bottomMargin: CGFloat = 16
    }
}

// MARK: - StoryboardLoadable

extension ReaderDetailWebviewViewController: StoryboardLoadable {
    static var defaultStoryboardName: String {
        return "ReaderDetailViewController"
    }
}

extension ReaderDetailWebviewViewController: ReaderCardDiscoverAttributionViewDelegate {
    public func attributionActionSelectedForVisitingSite(_ view: ReaderCardDiscoverAttributionView) {
        coordinator?.showMore()
    }
}

extension ReaderDetailWebviewViewController: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented is FancyAlertViewController else {
            return nil
        }

        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
