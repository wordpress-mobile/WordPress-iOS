
import UIKit
import WebKit

// MARK: AssembledSiteView

/// This view is intended for use as a subview of `SiteAssemblyContentView`.
/// It depicts an address bar and a picture of scrollable web content.
///
class AssembledSiteView: UIView {

    // MARK: Properties

    private struct Metrics {
        static let textFieldCornerRadius    = CGFloat(8)
        static let textFieldEdgeInset       = CGFloat(8)
        static let textFieldHeight          = CGFloat(36)
    }

    private let domainName: String

    private let textField: UITextField

    private let webView: WKWebView

    private var webViewHasLoadedContent: Bool = false

    var urlString: String = "" {
        didSet {
            loadSite(urlString: urlString)
        }
    }

    // MARK: AssembledSiteView

    init(domainName: String) {
        self.domainName = domainName

        textField = {
            let textField = UITextField(frame: .zero)

            textField.translatesAutoresizingMaskIntoConstraints = false

            textField.backgroundColor = WPStyleGuide.greyLighten30()
            textField.font = WPStyleGuide.fontForTextStyle(.footnote)
            textField.textAlignment = .center
            textField.textColor = WPStyleGuide.darkGrey()
            textField.text = domainName

            textField.layer.cornerRadius = Metrics.textFieldCornerRadius

            textField.sizeToFit()

            return textField
        }()

        webView = {
            let webView = WKWebView(frame: .zero)

            webView.translatesAutoresizingMaskIntoConstraints = false

            return webView
        }()

        super.init(frame: .zero)

        configure()
    }

    // MARK: UIView

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private behavior

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white

        webView.navigationDelegate = self

        addSubviews([ textField, webView ])

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.textFieldEdgeInset),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.textFieldEdgeInset),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.textFieldEdgeInset),
            textField.heightAnchor.constraint(equalToConstant: Metrics.textFieldHeight),
            textField.centerXAnchor.constraint(equalTo: centerXAnchor),
            webView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: Metrics.textFieldEdgeInset),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func loadSite(urlString: String) {
        let mockURL = URL(string: urlString)!
        let mockRequest = URLRequest(url: mockURL)
        webView.load(mockRequest)
    }
}

// MARK: - WKNavigationDelegate

extension AssembledSiteView: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        guard webViewHasLoadedContent else {
            decisionHandler(.allow)
            return
        }
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewHasLoadedContent = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugPrint(#function + " ERROR : \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }
}
