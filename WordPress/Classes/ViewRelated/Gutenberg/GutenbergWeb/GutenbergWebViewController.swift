import UIKit
import WebKit
import Gutenberg

class GutenbergWebViewController: GutenbergWebSingleBlockViewController, WebKitAuthenticatable {
    enum GutenbergWebError: Error {
        case wrongEditorUrl(String?)
    }

    let authenticator: RequestAuthenticator?
    private let url: URL
    private let progressView = WebProgressView()

    init(with post: AbstractPost, block: Block) throws {
        authenticator = GutenbergRequestAuthenticator(blog: post.blog)
        let userId = "\(post.blog.userID ?? 1)"

        guard
            let siteURL = post.blog.homeURL,
            // Use wp-admin URL since Calypso URL won't work retriving the block content.
            let editorURL = URL(string: "\(siteURL)/wp-admin/post-new.php")
        else {
            throw GutenbergWebError.wrongEditorUrl(post.blog.homeURL as String?)
        }
        url = editorURL

        try super.init(block: block, userId: userId, isWPOrg: !post.blog.isHostedAtWPcom)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addNavigationBarElements()
        addProgressView()
        startObservingWebView()
    }

    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard
            let object = object as? WKWebView,
            object == webView,
            let keyPath = keyPath
        else {
            return
        }

        switch keyPath {
        case #keyPath(WKWebView.estimatedProgress):
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress == 1
        default:
            assertionFailure("Observed change to web view that we are not handling")
        }
    }

    override func getRequest(for webView: WKWebView, completion: @escaping (URLRequest) -> Void) {
        authenticatedRequest(for: url, on: webView) { (request) in
            completion(request)
        }
    }

    private func addNavigationBarElements() {
        let buttonTitle = NSLocalizedString("Continue", comment: "Apply changes localy to single block edition in the web block editor")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: buttonTitle,
            style: .done,
            target: self,
            action: #selector(onSaveButtonPressed)
        )
    }

    private func startObservingWebView() {
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: [.new], context: nil)
    }

    private func addProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}
