import Foundation

final class DomainDetailsWebViewController: WebKitViewController {

    // MARK: - Properties

    private var observation: NSKeyValueObservation?

    // MARK: - Init

    init(url: URL, analyticsSource: String? = nil) {
        let configuration = WebViewControllerConfiguration(url: url)
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
                // Open URL in device browser then go back to Domain Management page.
                self.open(url)
                self.goBack()
            }
        }
    }

    // MARK: - Navigation

    override func goBack() {
        if webView.canGoBack {
            webView.goBack()
        } else if let navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - Helpers

    private func shouldAllowNavigation(for url: URL) -> Bool {
        return self.url?.absoluteString == url.absoluteString
    }

    private func open(_ url: URL) {
        UIApplication.shared.open(url)
    }
}
