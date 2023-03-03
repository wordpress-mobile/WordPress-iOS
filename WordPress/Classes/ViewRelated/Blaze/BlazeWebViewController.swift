import UIKit
import WebKit

class BlazeWebViewController: UIViewController, BlazeWebView {

    // MARK: Private Variables

    private let webView: WKWebView
    private var viewModel: BlazeWebViewModel?
    private let progressView = WebProgressView()
    private var reachabilityObserver: Any?
    private var currentRequestURL: URL?
    private var observingReachability: Bool {
        return reachabilityObserver != nil
    }

    // MARK: Lazy Loaded Views

    private lazy var dismissButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: Strings.cancelButtonTitle,
                                     style: .plain,
                                     target: self,
                                     action: #selector(dismissButtonTapped))
        return button
    }()

    // MARK: Initializers

    init(source: BlazeSource, blog: Blog, postID: NSNumber?) {
        self.webView = WKWebView(frame: .zero)
        super.init(nibName: nil, bundle: nil)
        viewModel = BlazeWebViewModel(source: source, blog: blog, postID: postID, view: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycles

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        overrideUserInterfaceStyle = .light
        configureSubviews()
        configureWebView()
        configureNavBar()
        viewModel?.startBlazeFlow()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopWaitingForConnectionRestored()
        ReachabilityUtils.dismissNoInternetConnectionNotice()
    }

    // MARK: Private Helpers

    private func configureSubviews() {
        let subviews = [progressView, webView]
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = .vertical
        view = stackView
    }

    private func configureWebView() {
        webView.navigationDelegate = self
        webView.customUserAgent = WPUserAgent.wordPress()
        progressView.observeProgress(webView: webView)
    }

    private func configureNavBar() {
        title = Strings.navigationTitle
        navigationItem.rightBarButtonItem = dismissButton
        configureNavBarAppearance()
        reloadNavBar()
    }

    private func configureNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = Colors.navigationBarColor
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationItem.compactScrollEdgeAppearance = appearance
        }
    }

    // MARK: Reachability Helpers

    private func reloadCurrentURL() {
        guard let currentRequestURL else {
            return
        }
        let request = URLRequest(url: currentRequestURL)
        webView.load(request)
    }

    private func observeReachability() {
        if !observingReachability {
            ReachabilityUtils.showNoInternetConnectionNotice()
            reloadWhenConnectionRestored()
        }
    }

    private func reloadWhenConnectionRestored() {
        reachabilityObserver = ReachabilityUtils.observeOnceInternetAvailable { [weak self] in
            self?.reloadCurrentURL()
        }
    }

    private func stopWaitingForConnectionRestored() {
        guard let reachabilityObserver = reachabilityObserver else {
            return
        }

        NotificationCenter.default.removeObserver(reachabilityObserver)
        self.reachabilityObserver = nil
    }

    // MARK: BlazeWebView

    func load(request: URLRequest) {
        webView.load(request)
    }

    var cookieJar: CookieJar {
        webView.configuration.websiteDataStore.httpCookieStore
    }

    func reloadNavBar() {
        guard let viewModel else {
            dismissButton.isEnabled = true
            dismissButton.title = Strings.cancelButtonTitle
            return
        }
        dismissButton.isEnabled = viewModel.isCurrentStepDismissible()
        dismissButton.title = viewModel.isFlowCompleted ? Strings.doneButtonTitle : Strings.cancelButtonTitle
    }

    func dismissView() {
        dismiss(animated: true)
    }

    // MARK: Actions

    @objc func dismissButtonTapped() {
        viewModel?.dismissTapped()
    }
}

extension BlazeWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let viewModel else {
            decisionHandler(.cancel)
            return
        }

        let policy = viewModel.shouldNavigate(to: navigationAction.request, with: navigationAction.navigationType)
        if policy == .allow {
            currentRequestURL = navigationAction.request.mainDocumentURL
        }

        guard ReachabilityUtils.isInternetReachable() else {
            observeReachability()
            decisionHandler(.cancel)
            return
        }

        decisionHandler(policy)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DDLogInfo("\(NSStringFromClass(type(of: self))) Error Loading [\(error)]")

        if !ReachabilityUtils.isInternetReachable() {
            observeReachability()
        } else {
            viewModel?.webViewDidFail(with: error)
            DDLogError("Blaze WebView \(webView) didFailProvisionalNavigation: \(error.localizedDescription)")
        }
    }
}

private extension BlazeWebViewController {
    enum Strings {
        static let navigationTitle = NSLocalizedString("feature.blaze.title",
                                                       value: "Blaze",
                                                       comment: "Name of a feature that allows the user to promote their posts.")
        static let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Cancel. Action.")
        static let doneButtonTitle = NSLocalizedString("Done", comment: "Done. Action.")
    }

    enum Colors {
        static let navigationBarColor = UIColor(hexString: "F2F1F6")?.withAlphaComponent(0.8)
    }
}
