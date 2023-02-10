import UIKit
import WebKit

class BlazeWebViewController: UIViewController {

    // MARK: Private Variables

    private let blog: Blog
    private let postID: NSNumber?
    private let webView: WKWebView
    private let progressView = WebProgressView()

    // MARK: Computed Variables

    private var initialURL: URL? {
        guard let siteURL = blog.displayURL else {
            return nil
        }
        var urlString: String
        if let postID {
            urlString = String(format: Constants.blazePostURLFormat, siteURL, postID.intValue)
        }
        else {
            urlString = String(format: Constants.blazeSiteURLFormat, siteURL)
        }
        return URL(string: urlString)
    }

    // MARK: Initializers

    init(blog: Blog, postID: NSNumber?) {
        self.blog = blog
        self.postID = postID
        self.webView = WKWebView(frame: .zero)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycles

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configureWebView()
        configureNavBar()
        startBlazeFlow()
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
        // set title
        // set button
    }

    private func startBlazeFlow() {
        guard let initialURL else {
            // TODO: Call delegate with error
            return
        }
        authenticatedRequest(for: initialURL, on: webView) { [weak self] (request) in
            self?.webView.load(request)
        }
    }
}

extension BlazeWebViewController: WKNavigationDelegate {

}

extension BlazeWebViewController: WebKitAuthenticatable {
    var authenticator: RequestAuthenticator? {
        RequestAuthenticator(blog: blog)
    }
}

private extension BlazeWebViewController {
    enum Constants {
        static let blazeSiteURLFormat = "https://wordpress.com/advertising/%@"
        static let blazePostURLFormat = "https://wordpress.com/advertising/%@?blazepress-widget=post-%d"
    }
}
