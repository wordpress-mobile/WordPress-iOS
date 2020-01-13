import Foundation
import WebKit
import Gridicons

class NewPostPreviewViewController: UIViewController {

    // MARK: Public Properties

    let post: AbstractPost

    // MARK: Private Properties

    private let webView = WKWebView(frame: .zero)

    private let generator: PostPreviewGenerator
    private var reachabilityObserver: Any?

    private weak var noResultsViewController: NoResultsViewController?

    // MARK: Initializers

    /// Creates a view controller displaying a preview web view.
    /// - Parameters:
    ///   - post: The post to use for generating the preview URL and authenticating to the blog. **NOTE**: `previewURL` will be used as the URL instead, when available.
    ///   - previewURL: The URL to display in the preview web view.
    init(post: AbstractPost, previewURL: URL? = nil) {
        self.post = post
        generator = PostPreviewGenerator(post: post, previewURL: previewURL)
        super.init(nibName: nil, bundle: nil)
        generator.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UI Constructor Properties

    private lazy var statusButtonItem: UIBarButtonItem = {
        let statusView = LoadingStatusView(title: NSLocalizedString("Loading", comment: "Label for button to present loading preview status"))
        let buttonItem = UIBarButtonItem(customView: statusView)
        buttonItem.accessibilityIdentifier = "Preview Status"
        return buttonItem
    }()

    private lazy var doneBarButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: "Label for button to dismiss post preview"), style: .done, target: self, action: #selector(dismissPreview))
        buttonItem.accessibilityIdentifier = "Done"
        return buttonItem
    }()

    private lazy var shareBarButtonItem: UIBarButtonItem = {
        let image = Gridicon.iconOfType(.shareIOS)
        let buttonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(sharePost))
        buttonItem.accessibilityLabel = NSLocalizedString("Share", comment: "Title of the share button in the Post Editor.")
        buttonItem.accessibilityIdentifier = "Share"
        return buttonItem
    }()

    // MARK: View Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupBarButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshWebView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopWaitingForConnectionRestored()
    }

    // MARK: Action Selectors

    @objc private func dismissPreview() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func sharePost() {
        if let post = post as? Post {
            let sharingController = PostSharingController()
            sharingController.sharePost(post, fromBarButtonItem: shareBarButtonItem, inViewController: self)
        }
    }

    // MARK: Private Instance Methods

    private func refreshWebView() {
        generator.generate()
    }

    private func setupBarButtons() {
        navigationItem.leftBarButtonItem = doneBarButtonItem
        navigationItem.rightBarButtonItem = shareBarButtonItem
    }

    private func setupWebView() {
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        view.pinSubviewToAllEdges(webView)
    }

    private func showNoResults(withTitle title: String) {
        let controller = NoResultsViewController.controllerWith(title: title,
                                                                buttonTitle: NSLocalizedString("Retry", comment: "Button to retry a preview that failed to load"),
                                                                subtitle: nil,
                                                                attributedSubtitle: nil,
                                                                attributedSubtitleConfiguration: nil,
                                                                image: nil,
                                                                subtitleImage: nil,
                                                                accessoryView: nil)
        controller.delegate = self
        noResultsViewController = controller
        addChild(controller)
        view.addSubview(controller.view)
        view.pinSubviewToAllEdges(controller.view)
        noResultsViewController?.didMove(toParent: self)
    }

    // MARK: Reachability

    private func reloadWhenConnectionRestored() {
        reachabilityObserver = ReachabilityUtils.observeOnceInternetAvailable { [weak self] in
            self?.refreshWebView()
        }
    }

    private func stopWaitingForConnectionRestored() {
        if let observer = reachabilityObserver {
            NotificationCenter.default.removeObserver(observer)
            reachabilityObserver = nil
        }
    }

    // MARK: Loading Animations

    private func startLoadAnimation() {
        navigationItem.setLeftBarButton(statusButtonItem, animated: true)
        navigationItem.title = nil
    }

    private func stopLoadAnimation() {
        navigationItem.leftBarButtonItem = doneBarButtonItem
        navigationItem.title = NSLocalizedString("Preview", comment: "Post Editor / Preview screen title.")
    }
}

// MARK: PostPreviewGeneratorDelegate

extension NewPostPreviewViewController: PostPreviewGeneratorDelegate {
    func preview(_ generator: PostPreviewGenerator, attemptRequest request: URLRequest) {
        startLoadAnimation()
        webView.load(request)
        noResultsViewController?.removeFromView()
    }

    func preview(_ generator: PostPreviewGenerator, loadHTML html: String) {
        webView.loadHTMLString(html, baseURL: nil)
        noResultsViewController?.removeFromView()
    }

    func previewFailed(_ generator: PostPreviewGenerator, message: String) {
        showNoResults(withTitle: message)
        reloadWhenConnectionRestored()
    }


}

// MARK: WKNavigationDelegate

extension NewPostPreviewViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        stopLoadAnimation()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handle(error: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handle(error: error)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        let redirectRequest = generator.interceptRedirect(request: navigationAction.request)

        if let request = redirectRequest {
            DDLogInfo("Found redirect to \(String(describing: redirectRequest))")
            decisionHandler(.cancel)
            webView.load(request)
            return
        }

        guard navigationAction.request.url?.query != "action=postpass" else {
            // Password-protected post, user entered password
            decisionHandler(.allow)
            return
        }

        guard navigationAction.request.url?.absoluteString != post.permaLink else {
            // Always allow loading the preview for `post`
            decisionHandler(.allow)
            return
        }

        switch navigationAction.navigationType {
        case .linkActivated:
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            decisionHandler(.cancel)
        case .formSubmitted:
            decisionHandler(.cancel)
        default:
            decisionHandler(.allow)
        }
    }

    private func handle(error: Error) {
        let error = error as NSError

        // Watch for NSURLErrorCancelled (aka NSURLErrorDomain error -999). This error is returned
        // when an asynchronous load is canceled. For example, a link is tapped (or some other
        // action that causes a new page to load) before the current page has completed loading.
        // It should be safe to ignore.
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            return
        }

        // In iOS 11, it seems UIWebView is based on WebKit, and it's returning a different error when
        // we redirect and cancel a request from shouldStartLoadWithRequest:
        //
        //   Error Domain=WebKitErrorDomain Code=102 "Frame load interrupted"
        //
        // I haven't found a relevant WebKit constant for error 102
        if error.domain == "WebKitErrorDomain" && error.code == 102 {
            return
        }

        stopLoadAnimation()

        let reasonString = "Generic web view error Error. Error code: \(error.code), Error domain: \(error.domain)"

        generator.previewRequestFailed(reason: reasonString)
    }
}

// MARK: NoResultsViewController Delegate

extension NewPostPreviewViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        stopWaitingForConnectionRestored()
        noResultsViewController?.removeFromView()
        refreshWebView()
    }

    func dismissButtonPressed() {
    }
}
