
import UIKit
import WebKit

// MARK: AssembledSiteView

/// This view is intended for use as a subview of `SiteAssemblyContentView`.
/// It depicts an address bar and a picture of scrollable web content.
///
final class AssembledSiteView: UIView {

    // MARK: Properties

    private struct Parameters {
        static let iPadWidthPortrait        = CGFloat(512)
        static let iPadWidthLandscape       = CGFloat(704)
        static let iPhoneWidthScaleFactor   = CGFloat(0.79)
        static let minimumHeightScaleFactor = CGFloat(0.79)
        static let shadowOffset             = CGSize(width: 0, height: 5)
        static let shadowOpacity            = Float(0.2)
        static let shadowRadius             = CGFloat(8)
        static let textFieldCornerRadius    = CGFloat(8)
        static let textFieldEdgeInset       = CGFloat(8)
        static let textFieldHeight          = CGFloat(36)
    }

    private let domainName: String

    private let textField: UITextField

    private let webView: WKWebView

    private var webViewHasLoadedContent: Bool = false

    var preferredSize: CGSize {
        let screenBounds = UIScreen.main.bounds

        let preferredWidth: CGFloat
        if WPDeviceIdentification.isiPad() {
            if UIDevice.current.orientation.isLandscape {
                preferredWidth = Parameters.iPadWidthLandscape
            } else {
                preferredWidth = Parameters.iPadWidthPortrait
            }
        } else {
            preferredWidth = screenBounds.width * Parameters.iPhoneWidthScaleFactor
        }

        let preferredHeight = screenBounds.height * Parameters.minimumHeightScaleFactor

        return CGSize(width: preferredWidth, height: preferredHeight)
    }

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

            textField.layer.cornerRadius = Parameters.textFieldCornerRadius

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
            textField.topAnchor.constraint(equalTo: topAnchor, constant: Parameters.textFieldEdgeInset),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Parameters.textFieldEdgeInset),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Parameters.textFieldEdgeInset),
            textField.heightAnchor.constraint(equalToConstant: Parameters.textFieldHeight),
            textField.centerXAnchor.constraint(equalTo: centerXAnchor),
            webView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: Parameters.textFieldEdgeInset),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = Parameters.shadowOffset
        layer.shadowOpacity = Parameters.shadowOpacity
        layer.shadowRadius = Parameters.shadowRadius
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
