import Foundation
import Gridicons
import UIKit
import WebKit

class WebKitViewController: UIViewController {
    @objc let webView: WKWebView
    @objc let progressView = WebProgressView()
    @objc let titleView = NavigationTitleView()

    @objc var backButton: UIBarButtonItem?
    @objc var forwardButton: UIBarButtonItem?
    @objc var shareButton: UIBarButtonItem?
    @objc var safariButton: UIBarButtonItem?
    @objc var customOptionsButton: UIBarButtonItem?

    @objc let url: URL
    @objc let authenticator: WebViewAuthenticator?
    @objc let navigationDelegate: WebNavigationDelegate?
    @objc var secureInteraction = false
    @objc var addsWPComReferrer = false
    @objc var customTitle: String?

    @objc init(configuration: WebViewControllerConfiguration) {
        webView = WKWebView()
        url = configuration.url
        customOptionsButton = configuration.optionsButton
        secureInteraction = configuration.secureInteraction
        addsWPComReferrer = configuration.addsWPComReferrer
        customTitle = configuration.customTitle
        authenticator = configuration.authenticator
        navigationDelegate = configuration.navigationDelegate
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    fileprivate init(url: URL, parent: WebKitViewController) {
        webView = WKWebView(frame: .zero, configuration: parent.webView.configuration)
        self.url = url
        customOptionsButton = parent.customOptionsButton
        secureInteraction = parent.secureInteraction
        addsWPComReferrer = parent.addsWPComReferrer
        customTitle = parent.customTitle
        authenticator = parent.authenticator
        navigationDelegate = parent.navigationDelegate
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
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
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: [.new], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: [.new], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: [.new], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: [], context: nil)
        webView.customUserAgent = WPUserAgent.wordPress()
        webView.navigationDelegate = self
        webView.uiDelegate = self

        loadWebViewRequest()
    }

    @objc func loadWebViewRequest() {
        guard let authenticator = authenticator,
            #available(iOS 11, *) else {
            load(request: URLRequest(url: url))
            return
        }
        authenticator.request(url: url, cookieJar: webView.configuration.websiteDataStore.httpCookieStore) { [weak self] (request) in
            self?.load(request: request)
        }
    }

    @objc func load(request: URLRequest) {
        var request = request
        if addsWPComReferrer {
            request.setValue("https://wordpress.com", forHTTPHeaderField: "Referer")
        }
        webView.load(request)
    }

    @objc func configureNavigation() {
        let closeButton = UIBarButtonItem(image: Gridicon.iconOfType(.cross), style: .plain, target: self, action: #selector(WebKitViewController.close))
        closeButton.accessibilityLabel = NSLocalizedString("Dismiss", comment: "Dismiss a view. Verb")

        titleView.titleLabel.text = NSLocalizedString("Loading...", comment: "Loading. Verb")
        if let title = customTitle {
            self.title = title
        } else {
            navigationItem.titleView = titleView
        }

        let refreshButton = UIBarButtonItem(image: Gridicon.iconOfType(.refresh), style: .plain, target: self, action: #selector(WebKitViewController.refresh))
        if let customOptionsButton = customOptionsButton {
            navigationItem.rightBarButtonItems = [refreshButton, customOptionsButton]
        } else if !secureInteraction {
            navigationItem.rightBarButtonItem = refreshButton
        }

        // Modal styling
        // Proceed only if this Modal, and it's the only view in the stack.
        // We're not changing the NavigationBar style, if we're sharing it with someone else!
        guard isModal() else {
            return
        }

        navigationItem.leftBarButtonItem = closeButton

        let navigationBar = navigationController?.navigationBar
        navigationBar?.shadowImage = UIImage(color: WPStyleGuide.webViewModalNavigationBarShadow())
        navigationBar?.barStyle = .default
        navigationBar?.setBackgroundImage(UIImage(color: WPStyleGuide.webViewModalNavigationBarBackground()), for: .default)

        titleView.titleLabel.textColor = WPStyleGuide.darkGrey()
        titleView.subtitleLabel.textColor = WPStyleGuide.grey()
        closeButton.tintColor = WPStyleGuide.greyLighten10()
        refreshButton.tintColor = WPStyleGuide.greyLighten10()
        customOptionsButton?.tintColor = WPStyleGuide.greyLighten10()
    }

    @objc func configureToolbar() {
        navigationController?.isToolbarHidden = secureInteraction
        navigationController?.toolbar.barTintColor = UIColor.white

        backButton = UIBarButtonItem(image: Gridicon.iconOfType(.chevronLeft).imageFlippedForRightToLeftLayoutDirection(),
                                     style: .plain,
                                     target: self,
                                     action: #selector(WebKitViewController.goBack))

        forwardButton = UIBarButtonItem(image: Gridicon.iconOfType(.chevronRight).imageFlippedForRightToLeftLayoutDirection(),
                                        style: .plain,
                                        target: self,
                                        action: #selector(WebKitViewController.goForward))

        shareButton = UIBarButtonItem(image: Gridicon.iconOfType(.shareIOS),
                                      style: .plain,
                                      target: self,
                                      action: #selector(WebKitViewController.share))

        safariButton = UIBarButtonItem(image: Gridicon.iconOfType(.globe),
                                       style: .plain,
                                       target: self,
                                       action: #selector(WebKitViewController.openInSafari))

        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let items = [
            backButton!,
            space,
            forwardButton!,
            space,
            shareButton!,
            space,
            safariButton!
        ]

        items.forEach({ (button) in
            button.tintColor = WPStyleGuide.greyLighten10()
        })

        setToolbarItems(items, animated: false)
    }

    @objc func close() {
        dismiss(animated: true, completion: nil)
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
        present(activityViewController, animated: true, completion: nil)

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
            titleView.subtitleLabel.text = webView.url?.host
        case #keyPath(WKWebView.estimatedProgress):
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress == 1
        case #keyPath(WKWebView.isLoading):
            backButton?.isEnabled = webView.canGoBack
            forwardButton?.isEnabled = webView.canGoForward
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
            present(navController, animated: true, completion: nil)
        }
        return nil
    }

    func webViewDidClose(_ webView: WKWebView) {
        dismiss(animated: true, completion: nil)
    }
}
