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

    init(blog: Blog) {
        self.blog = blog
        webView = WKWebView()
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

        switch step {
        case .siteAuth(let redirect):
            DDLogDebug("Site login detected with redirect: \(redirect)")
            decisionHandler(.allow)
        case .dotComAuth(let redirect):
            DDLogDebug("WordPress.com login detected with redirect \(redirect)")
            decisionHandler(.allow)
        case .mobileRedirect:
            decisionHandler(.cancel)
            delegate?.jetpackConnectionCompleted()
        }
    }
}

private extension URL {
    var isHTTP: Bool {
        return scheme == "http"
            || scheme == "https"
    }

    func matchesPath(in other: URL, scheme matchScheme: Bool = true) -> Bool {
        let matchesScheme = matchScheme
            ? scheme == other.scheme
            : isHTTP && other.isHTTP
        return matchesScheme
            && host == other.host
            && path == other.path
    }
}

private extension JetpackConnectionWebViewController {
    enum FlowStep {
        case siteAuth(redirect: URL)
        case dotComAuth(redirect: URL)
        case mobileRedirect
    }

    func flowStep(url: URL) -> FlowStep? {
        switch url {
        case isSiteLogin:
            return extractRedirect(url: url)
                .map(FlowStep.siteAuth)
        case isDotComLogin:
            return extractRedirect(url: url)
                .map(FlowStep.dotComAuth)
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

        return url.matchesPath(in: loginURL, scheme: false)
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
}
