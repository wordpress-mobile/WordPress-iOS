import Foundation
import Gridicons
import UIKit
import WebKit

class WebKitViewController: UIViewController {
    @objc let webView: WKWebView
    @objc let progressView = WebProgressView()
    @objc let titleView = NavigationTitleView()

    @objc lazy var backButton: UIBarButtonItem = {
        return UIBarButtonItem(image: Gridicon.iconOfType(.chevronLeft).imageFlippedForRightToLeftLayoutDirection(),
                               style: .plain,
                               target: self,
                               action: #selector(goBack))
    }()
    @objc lazy var forwardButton: UIBarButtonItem = {
        return UIBarButtonItem(image: Gridicon.iconOfType(.chevronRight).imageFlippedForRightToLeftLayoutDirection(),
                               style: .plain,
                               target: self,
                               action: #selector(goForward))
    }()
    @objc lazy var shareButton: UIBarButtonItem = {
        return UIBarButtonItem(image: Gridicon.iconOfType(.shareIOS),
                               style: .plain,
                               target: self,
                               action: #selector(share))
    }()
    @objc lazy var safariButton: UIBarButtonItem = {
        return UIBarButtonItem(image: Gridicon.iconOfType(.globe),
                               style: .plain,
                               target: self,
                               action: #selector(openInSafari))
    }()
    @objc var customOptionsButton: UIBarButtonItem?

    @objc let url: URL
    @objc let authenticator: WebViewAuthenticator?
    @objc let navigationDelegate: WebNavigationDelegate?
    @objc var secureInteraction = false
    @objc var addsWPComReferrer = false
    @objc var addsHideMasterbarParameters = true
    @objc var customTitle: String?

    private var reachabilityObserver: Any?

    private struct WebViewErrors {
        static let frameLoadInterrupted = 102
    }

    @objc init(configuration: WebViewControllerConfiguration) {
        webView = WKWebView()
        url = configuration.url
        customOptionsButton = configuration.optionsButton
        secureInteraction = configuration.secureInteraction
        addsWPComReferrer = configuration.addsWPComReferrer
        addsHideMasterbarParameters = configuration.addsHideMasterbarParameters
        customTitle = configuration.customTitle
        authenticator = configuration.authenticator
        navigationDelegate = configuration.navigationDelegate
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
        startObservingWebView()
    }

    fileprivate init(url: URL, parent: WebKitViewController) {
        webView = WKWebView(frame: .zero, configuration: parent.webView.configuration)
        self.url = url
        customOptionsButton = parent.customOptionsButton
        secureInteraction = parent.secureInteraction
        addsWPComReferrer = parent.addsWPComReferrer
        addsHideMasterbarParameters = parent.addsHideMasterbarParameters
        customTitle = parent.customTitle
        authenticator = parent.authenticator
        navigationDelegate = parent.navigationDelegate
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
        startObservingWebView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
    }

    private func startObservingWebView() {
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: [.new], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: [.new], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: [.new], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: [], context: nil)
    }

    override func loadView() {
        let stackView = UIStackView(arrangedSubviews: [
            progressView,
            webView
            ])
        stackView.axis = .vertical
        view = stackView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureToolbar()
        webView.customUserAgent = WPUserAgent.wordPress()
        webView.navigationDelegate = self
        webView.uiDelegate = self

        loadWebViewRequest()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopWaitingForConnectionRestored()
        ReachabilityUtils.dismissNoInternetConnectionNotice()
    }

    @objc func loadWebViewRequest() {
        if ReachabilityUtils.alertIsShowing() {
            self.dismiss(animated: false)
        }

        guard let authenticator = authenticator else {
            load(request: URLRequest(url: url))
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }

            authenticator.request(url: strongSelf.url, cookieJar: strongSelf.webView.configuration.websiteDataStore.httpCookieStore) { [weak self] (request) in
                self?.load(request: request)
            }
        }
    }

    @objc func load(request: URLRequest) {
        var request = request
        if addsWPComReferrer {
            request.setValue(WPComReferrerURL, forHTTPHeaderField: "Referer")
        }

        if addsHideMasterbarParameters,
            let host = request.url?.host,
            (host.contains(WPComDomain) || host.contains(AutomatticDomain)) {
            request.url = request.url?.appendingHideMasterbarParameters()
        }

        webView.load(request)
    }

    // MARK: Navigation bar setup

    @objc func configureNavigation() {
        setupNavBarTitleView()
        setupRefreshButton()

        // Modal styling
        // Proceed only if this Modal, and it's the only view in the stack.
        // We're not changing the NavigationBar style, if we're sharing it with someone else!
        guard isModal() else {
            return
        }

        setupCloseButton()
        styleNavBar()
        styleNavBarButtons()
    }

    private func setupRefreshButton() {
        let refreshButton = UIBarButtonItem(image: Gridicon.iconOfType(.refresh), style: .plain, target: self, action: #selector(WebKitViewController.refresh))
        if let customOptionsButton = customOptionsButton {
            navigationItem.rightBarButtonItems = [refreshButton, customOptionsButton]
        } else if !secureInteraction {
            navigationItem.rightBarButtonItem = refreshButton
        }
    }

    private func setupCloseButton() {
        let closeButton = UIBarButtonItem(image: Gridicon.iconOfType(.cross), style: .plain, target: self, action: #selector(WebKitViewController.close))
        closeButton.accessibilityLabel = NSLocalizedString("Dismiss", comment: "Dismiss a view. Verb")
        navigationItem.leftBarButtonItem = closeButton
    }

    private func setupNavBarTitleView() {
        titleView.titleLabel.text = NSLocalizedString("Loading...", comment: "Loading. Verb")
        if #available(iOS 13.0, *) {
            titleView.titleLabel.textColor = UIColor(light: .white, dark: .neutral(.shade70))
        } else {
            titleView.titleLabel.textColor = .neutral(.shade70)
        }
        titleView.subtitleLabel.textColor = .neutral(.shade30)

        if let title = customTitle {
            self.title = title
        } else {
            navigationItem.titleView = titleView
        }
    }

    private func styleNavBar() {
        guard let navigationBar = navigationController?.navigationBar else {
            return
        }
        navigationBar.barStyle = .default
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.neutral(.shade70)]
        navigationBar.shadowImage = UIImage(color: WPStyleGuide.webViewModalNavigationBarShadow())
        navigationBar.setBackgroundImage(UIImage(color: WPStyleGuide.webViewModalNavigationBarBackground()), for: .default)

        fixBarButtonsColorForBoldText(on: navigationBar)
    }

    private func styleNavBarButtons() {
        navigationItem.leftBarButtonItems?.forEach(styleBarButton)
        navigationItem.rightBarButtonItems?.forEach(styleBarButton)
    }

    // MARK: ToolBar setup

    @objc func configureToolbar() {
        navigationController?.isToolbarHidden = secureInteraction

        guard !secureInteraction else {
            return
        }

        styleToolBar()
        configureToolbarButtons()
        styleToolBarButtons()
    }

    private func configureToolbarButtons() {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let items = [
            backButton,
            space,
            forwardButton,
            space,
            shareButton,
            space,
            safariButton
        ]
        setToolbarItems(items, animated: false)
    }

    private func styleToolBar() {
        guard let toolBar = navigationController?.toolbar else {
            return
        }
        toolBar.barTintColor = UIColor(light: .white, dark: .appBar)
        fixBarButtonsColorForBoldText(on: toolBar)
    }

    private func styleToolBarButtons() {
        navigationController?.toolbar.items?.forEach(styleToolBarButton)
    }

    // MARK: Helpers

    private func fixBarButtonsColorForBoldText(on bar: UIView) {
        if UIAccessibility.isBoldTextEnabled {
            bar.tintColor = .listIcon
        }
    }

    private func styleBarButton(_ button: UIBarButtonItem) {
        if #available(iOS 13.0, *) {
            button.tintColor = UIColor(light: .white, dark: .neutral(.shade70))
        } else {
            button.tintColor = .listIcon
        }
    }

    private func styleToolBarButton(_ button: UIBarButtonItem) {
        button.tintColor = .listIcon
    }

    // MARK: Reachability Helpers

    private func reloadWhenConnectionRestored() {
        reachabilityObserver = ReachabilityUtils.observeOnceInternetAvailable {
            self.loadWebViewRequest()
        }
    }

    private func stopWaitingForConnectionRestored() {
        guard let reachabilityObserver = reachabilityObserver else {
            return
        }

        NotificationCenter.default.removeObserver(reachabilityObserver)
        self.reachabilityObserver = nil
    }

    // MARK: User Actions

    @objc func close() {
        dismiss(animated: true)
    }

    @objc func share() {
        guard let url = webView.url else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.modalPresentationStyle = .popover
        activityViewController.popoverPresentationController?.barButtonItem = shareButton

        activityViewController.completionWithItemsHandler = { (type, completed, _, _) in
            if completed, let type = type?.rawValue {
                WPActivityDefaults.trackActivityType(type)
            }
        }
        present(activityViewController, animated: true)

    }

    @objc func refresh() {
        webView.reload()
    }

    @objc func goBack() {
        webView.goBack()
    }

    @objc func goForward() {
        webView.goForward()
    }

    @objc func openInSafari() {
        guard let url = webView.url else {
            return
        }
        UIApplication.shared.open(url)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let object = object as? WKWebView,
            object == webView,
            let keyPath = keyPath else {
                return
        }

        switch keyPath {
        case #keyPath(WKWebView.title):
            titleView.titleLabel.text = webView.title
        case #keyPath(WKWebView.url):
            // If the site has no title, use the url.
            if webView.title?.nonEmptyString() == nil {
                titleView.titleLabel.text = webView.url?.host
            }
            titleView.subtitleLabel.text = webView.url?.host
            let haveUrl = webView.url != nil
            shareButton.isEnabled = haveUrl
            safariButton.isEnabled = haveUrl
            navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = haveUrl }
        case #keyPath(WKWebView.estimatedProgress):
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress == 1
        case #keyPath(WKWebView.isLoading):
            backButton.isEnabled = webView.canGoBack
            forwardButton.isEnabled = webView.canGoForward
        default:
            assertionFailure("Observed change to web view that we are not handling")
        }
    }

}

extension WebKitViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let request = authenticator?.interceptRedirect(request: navigationAction.request) {
            decisionHandler(.cancel)
            load(request: request)
            return
        }

        if let delegate = navigationDelegate {
            let policy = delegate.shouldNavigate(request: navigationAction.request)
            if let redirect = policy.redirectRequest {
                load(request: redirect)
            }
            decisionHandler(policy.action)
            return
        }
        decisionHandler(.allow)
    }
}

extension WebKitViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil,
            let url = navigationAction.request.url {
            let controller = WebKitViewController(url: url, parent: self)
            let navController = UINavigationController(rootViewController: controller)
            present(navController, animated: true)
        }
        return nil
    }

    func webViewDidClose(_ webView: WKWebView) {
        dismiss(animated: true)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DDLogInfo("\(NSStringFromClass(type(of: self))) Error Loading [\(error)]")

        // Don't show Frame Load Interrupted errors
        let code = (error as NSError).code
        if code == WebViewErrors.frameLoadInterrupted {
            return
        }

        if !ReachabilityUtils.isInternetReachable() {
            ReachabilityUtils.showNoInternetConnectionNotice()
            reloadWhenConnectionRestored()
        } else {
            WPError.showAlert(withTitle: NSLocalizedString("Error", comment: "Generic error alert title"), message: error.localizedDescription)
        }
    }
}
