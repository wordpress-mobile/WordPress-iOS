import Foundation
import WordPressData
import WordPressShared
import WordPressKit

final class DomainDetailsWebViewController: WebKitViewController {

    // MARK: - Types

    private enum Constants {
        static let basePath = "https://wordpress.com"
        static let domainsPath = "\(basePath)/domains"
        static let manageAllDomainsPath = "\(domainsPath)/manage/all"
    }

    // MARK: - Properties

    private var observation: NSKeyValueObservation?

    // MARK: - Init

    init(domain: String, siteSlug: String, type: DomainType, analyticsSource: String? = nil) {
        let url = Self.wpcomDetailsURL(domain: domain, siteSlug: siteSlug, type: type)
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.customTitle = domain
        configuration.analyticsSource = analyticsSource
        configuration.secureInteraction = true
        if let url {
            configuration.linkBehavior = .urlOnly(url)
        }
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
        self.trackWebViewShownEvent(url: url)
    }

    // MARK: - Handling URL Changes

    private func observeURL() {
        self.observation = webView.observe(\.url) { [weak self] webView, _ in
            guard let self, let url = webView.url else {
                return
            }
            if !Self.shouldAllowNavigation(
                to: url,
                domainDetailsURL: self.url,
                isLoading: webView.isLoading
            ) {
                // Open URL in device browser then go back to Domain Management page.
                UIApplication.shared.open(url)
                self.goBack()
            }
        }
    }

    // MARK: - Navigation

    override func goBack() {
        if webView.canGoBack {
            self.webView.goBack()
        } else {
            self.popOrDismiss()
        }
    }

    private func popOrDismiss(animated: Bool = true) {
        if let navigationController {
            navigationController.popViewController(animated: animated)
        } else {
            dismiss(animated: animated)
        }
    }

    // MARK: - Helpers

    private func trackWebViewShownEvent(url: URL?) {
        let properties = ["url": url?.absoluteString ?? ""]
        WPAnalytics.track(.allDomainsDomainDetailsWebViewShown, properties: properties)
    }

    static func shouldAllowNavigation(
        to url: URL,
        domainDetailsURL: URL?,
        isLoading: Bool
    ) -> Bool {
        isLoading || url == domainDetailsURL
    }

    private static func wpcomDetailsURL(domain: String, siteSlug: String, type: DomainType) -> URL? {
        let viewSlug = {
            switch type {
            case .siteRedirect: return "redirect"
            case .transfer: return "transfer/in"
            default: return "edit"
            }
        }()

        let url = "\(Constants.manageAllDomainsPath)/\(domain)/\(viewSlug)/\(siteSlug)"

        if let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: encodedURL)
        } else {
            return nil
        }
    }
}
