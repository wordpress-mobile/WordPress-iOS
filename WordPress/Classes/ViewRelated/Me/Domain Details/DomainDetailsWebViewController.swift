import Foundation

final class DomainDetailsWebViewController: WebKitViewController {

    // MARK: - Properties

    private var observation: NSKeyValueObservation?

    // MARK: - Init

    init(url: URL, analyticsSource: String? = nil) {
        var configuration = WebViewControllerConfiguration(url: url)
        configuration.analyticsSource = analyticsSource
        configuration.secureInteraction = true
        configuration.authenticateWithDefaultAccount()
        super.init(configuration: configuration)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.observeURL()
    }

    // MARK: - Handling URL Changes

    private func observeURL() {
        self.observation = webView.observe(\.url) { [weak self] webView, _ in
            guard let self, let url = webView.url else {
                return
            }
            if !self.shouldAllowNavigation(for: url) {
                // Open URL in device browser then reset webview.
                UIApplication.shared.open(url)
                self.loadWebViewRequest()
            }
        }
    }

    private func shouldAllowNavigation(for url: URL) -> Bool {
        let isAuthenticationURL = authenticator?.isLogin(url: url) ?? false
        let isDomainManagementURL = self.url?.absoluteString == url.absoluteString
        return isAuthenticationURL || isDomainManagementURL
    }
}
