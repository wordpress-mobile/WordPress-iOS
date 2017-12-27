import UIKit
import WebKit
import Gridicons

protocol JetpackConnectionWebDelegate {
    func jetpackConnectionCompleted()
    func jetpackConnectionCanceled()
}

class JetpackConnectionWebViewController: UIViewController {
    let blog: Blog
    let webView: WKWebView
    let progressView = WebProgressView()
    var delegate: JetpackConnectionWebDelegate?

    // Sometimes wp-login doesn't redirect to the expected URL, so we're storing
    // it and redirecting manually
    fileprivate var pendingSiteRedirect: URL?

    init(blog: Blog) {
        self.blog = blog
        let configuration = WKWebViewConfiguration()
        if Debug.enabled {
            configuration.websiteDataStore = .nonPersistent()
        }
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(nibName: nil, bundle: nil)
        webView.navigationDelegate = self
        title = NSLocalizedString("Install Jetpack", comment: "Title for the Jetpack Installation")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        progressView.observeProgress(webView: webView)

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(JetpackConnectionWebViewController.cancel))

        startConnectionFlow()
    }

    func startConnectionFlow() {
        guard let escapedSiteURL = blog.homeURL?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://wordpress.com/jetpack/connect?url=\(escapedSiteURL)&mobile_redirect=\(mobileRedirectURL)") else {
                // FIXME: We should handle this error better
                preconditionFailure()
        }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    @objc func cancel() {
        delegate?.jetpackConnectionCanceled()
    }
}

extension JetpackConnectionWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url,
            navigationAction.request.httpMethod == "GET",
            navigationAction.targetFrame?.isMainFrame ?? false,
            let step = flowStep(url: url) else {
                decisionHandler(.allow)
                return
        }

        Debug.log("🚀🔌 Step: \(step)")
        switch step {
        case .siteAuth(let redirect):
            performSiteLogin(redirect: redirect, decisionHandler: decisionHandler)
        case .dotComAuth:
            decisionHandler(.allow)
        case .siteAdmin:
            if let redirect = pendingSiteRedirect {
                pendingSiteRedirect = nil
                decisionHandler(.cancel)
                webView.load(URLRequest(url: redirect))
            } else {
                decisionHandler(.allow)
            }
        case .mobileRedirect:
            decisionHandler(.cancel)
            delegate?.jetpackConnectionCompleted()
        default:
            decisionHandler(.allow)
        }
    }
}

private extension URL {
    var isHTTP: Bool {
        return scheme == "http"
            || scheme == "https"
    }

    func matchesPath(in other: URL) -> Bool {
        return scheme == other.scheme
            && host == other.host
            && port == other.port
            && path == other.path
    }
}

private extension JetpackConnectionWebViewController {
    enum FlowStep: CustomStringConvertible {
        case siteAuth(redirect: URL)
        case sitePluginDetail
        case sitePluginInstallation
        case sitePlugins
        case siteAdmin
        case dotComAuth(redirect: URL)
        case mobileRedirect

        var description: String {
            switch self {
            case .siteAuth(let redirect):
                return "Site login form, redirecting to \(redirect)"
            case .sitePluginDetail:
                return "Plugin detail page"
            case .sitePluginInstallation:
                return "Plugin installation page"
            case .sitePlugins:
                return "Installed plugins page"
            case .siteAdmin:
                return "Unknown wp-admin page"
            case .dotComAuth(let redirect):
                return "WordPress.com login, redirecting to \(redirect)"
            case .mobileRedirect:
                return "Mobile Redirect, end of the connection flow"
            }
        }
    }

    func flowStep(url: URL) -> FlowStep? {
        switch url {
        case isSiteLogin:
            return extractRedirect(url: url)
                .map(FlowStep.siteAuth)
        case isDotComLogin:
            return extractRedirect(url: url)
                .map(FlowStep.dotComAuth)
        case isSiteAdmin(path: "plugin-install.php"):
            return .sitePluginDetail
        case isSiteAdmin(path: "update.php?action=install-plugin"):
            return .sitePluginInstallation
        case isSiteAdmin(path: "plugins.php"):
            return .sitePlugins
        case isSiteAdmin(path: ""):
            return .siteAdmin
        case mobileRedirectURL:
            return .mobileRedirect
        default:
            return nil
        }
    }

    var mobileRedirectURL: URL {
        return URL(string: "wordpress://jetpack-connection")!
    }

    func isSiteLogin(url: URL) -> Bool {
        guard let loginURL = URL(string: blog.loginUrl()) else {
            return false
        }

        return url.matchesPath(in: loginURL)
    }

    func isSiteAdmin(path: String) -> (URL) -> Bool {
        guard let adminURL = URL(string: blog.adminUrl(withPath: path)) else {
            return { _ in return false }
        }
        return { url in
            return url.absoluteString.hasPrefix(adminURL.absoluteString)
        }
    }

    func isDotComLogin(url: URL) -> Bool {
        let dotComLoginURL = URL(string: "https://wordpress.com/log-in")!
        return url.matchesPath(in: dotComLoginURL)
    }

    func extractRedirect(url: URL) -> URL? {
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "redirect_to" })?
            .value?
            .removingPercentEncoding
            .flatMap(URL.init(string:))
    }

    func performSiteLogin(redirect: URL, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let authenticator = WebViewAuthenticator(blog: blog) else {
                decisionHandler(.allow)
                return
        }
        decisionHandler(.cancel)
        let request = authenticator.authenticatedRequest(url: redirect)
        DDLogDebug("Performing site login to \(String(describing: request.url))")
        pendingSiteRedirect = redirect
        webView.load(request)
    }

    enum Debug {
        static var enabled: Bool {
            return CommandLine.arguments.contains("-debugJetpackConnectionFlow")
        }

        static func log(_ message: String) {
            guard enabled else {
                return
            }
            DDLogDebug(message)
        }
    }
}
