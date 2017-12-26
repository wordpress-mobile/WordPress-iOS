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
            let url = URL(string: "https://wordpress.com/jetpack/connect?url=\(escapedSiteURL)&mobile_redirect=wordpress://jetpack-connection") else {
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
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if url.scheme == "wordpress" && url.host == "jetpack-connection" {
            decisionHandler(.cancel)
            delegate?.jetpackConnectionCompleted()
        }
        decisionHandler(.allow)
    }
}
