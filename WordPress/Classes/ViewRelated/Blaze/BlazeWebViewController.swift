import UIKit
import WebKit

class BlazeWebViewController: UIViewController {

    // MARK: Private Variables

    let blog: Blog
    let postID: NSNumber?
    let webView: WKWebView
    let progressView = WebProgressView()

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
        progressView.observeProgress(webView: webView)
    }

    private func configureNavBar() {
        // set title
        // set button
    }

    private func startBlazeFlow() {
        // load url
    }
}

extension BlazeWebViewController: WKNavigationDelegate {

}
