import UIKit

protocol ReaderDetailView: class {
    func render(_ post: ReaderPost)
    func showError()
}

class ReaderDetailWebviewViewController: UIViewController, ReaderDetailView {
    /// A ReaderWebView
    @IBOutlet weak var webView: ReaderWebView!

    /// WebView height constraint
    @IBOutlet weak var webViewHeight: NSLayoutConstraint!

    /// An observer of the content size of the webview
    private var scrollObserver: NSKeyValueObservation?

    /// The coordinator, responsible for the logic
    var coordinator: ReaderDetailCoordinator!

    override func viewDidLoad() {
        super.viewDidLoad()

        applyStyles()

        observeWebViewHeight()

        coordinator.start()
    }

    func render(_ post: ReaderPost) {
        webView.loadHTMLString(post.contentForDisplay(), baseURL: nil)
    }

    func showError() {
        /// TODO: Show error
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
            webView.rightAnchor.constraint(equalTo: readableGuide.rightAnchor),
            webView.leftAnchor.constraint(equalTo: readableGuide.leftAnchor)
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

            self?.webViewHeight.constant = height
        }
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
}

// MARK: - StoryboardLoadable

extension ReaderDetailWebviewViewController: StoryboardLoadable {
    static var defaultStoryboardName: String {
        return "ReaderDetailViewController"
    }
}
