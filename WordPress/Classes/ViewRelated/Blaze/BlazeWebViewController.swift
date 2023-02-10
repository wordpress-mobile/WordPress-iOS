import UIKit
import WebKit

class BlazeWebViewController: UIViewController {

    // MARK: Private Variables

    private let source: BlazeWebViewCoordinator.Source
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
            urlString = String(format: Constants.blazePostURLFormat, siteURL, postID.intValue, source.rawValue)
        }
        else {
            urlString = String(format: Constants.blazeSiteURLFormat, siteURL, source.rawValue)
        }
        return URL(string: urlString)
    }

    // MARK: Lazy Loaded Views

    private lazy var cancelButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: Strings.cancelButtonTitle,
                                     style: .plain,
                                     target: self,
                                     action: #selector(cancelButtonTapped))
        return button
    }()

    // MARK: Initializers

    init(source: BlazeWebViewCoordinator.Source, blog: Blog, postID: NSNumber?) {
        self.source = source
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
        self.isModalInPresentation = true
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
        title = Strings.navigationTitle
        navigationItem.rightBarButtonItem = cancelButton
        configureNavBarAppearance()
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

    private func startBlazeFlow() {
        guard let initialURL else {
            // TODO: Call delegate with error
            return
        }
        authenticatedRequest(for: initialURL, on: webView) { [weak self] (request) in
            self?.webView.load(request)
        }
    }

    // MARK: Actions

    @objc func cancelButtonTapped() {
        dismiss(animated: true)
        // TODO: To be implemented
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
        static let blazeSiteURLFormat = "https://wordpress.com/advertising/%@?source=%@"
        static let blazePostURLFormat = "https://wordpress.com/advertising/%@?blazepress-widget=post-%d&source=%@"
    }

    enum Strings {
        static let navigationTitle = NSLocalizedString("feature.blaze.title",
                                                       value: "Blaze",
                                                       comment: "Name of a feature that allows the user to promote their posts.")
        static let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Cancel. Action.")
    }

    enum Colors {
        static let navigationBarColor = UIColor(hexString: "F2F1F6")?.withAlphaComponent(0.8)
    }
}
