
import UIKit
import WebKit

// MARK: AssembledSiteView

/// This view is intended for use as a subview of `SiteAssemblyContentView`.
/// It depicts an address bar and a picture of scrollable web content.
final class AssembledSiteView: UIView {

    // MARK: Properties

    /// A collection of parameters uses for animation & layout of the view.
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

    /// This value displays in the address bar.
    private let siteName: String

    /// This value is what the web view loads.
    private let siteURLString: String

    /// This subview fulfills the role of address bar.
    private let textField: UITextField

    /// At the moment, we are loading the assembled site in a web view. This underscores that.
    private let activityIndicator: UIActivityIndicatorView

    /// The web view that renders our newly assembled site
    private let webView: WKWebView

    /// The request formulated to present the site to the user for first time.
    private var initialSiteRequest: URLRequest?

    /// This interacts with our `WKNavigationDelegate` to influence the policy behavior before & after site loading.
    /// After the site has been loaded, we want to disable user interaction with the rendered site.
    private var webViewHasLoadedContent: Bool = false

    /// Haptic feedback generator
    private let generator = UINotificationFeedbackGenerator()

    /// This informs constraints applied to the view. It _may_ be possible to transition this to intrinsicContentSize.
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

    // MARK: AssembledSiteView

    /// The designated initializer.
    ///
    /// - Parameter domainName: the domain associated with the site pending assembly.
    init(domainName: String, siteURLString: String) {
        self.siteName = domainName
        self.siteURLString = siteURLString

        textField = {
            let textField = UITextField(frame: .zero)

            textField.translatesAutoresizingMaskIntoConstraints = false

            textField.backgroundColor = .listBackground
            textField.font = WPStyleGuide.fontForTextStyle(.footnote)
            textField.isEnabled = false
            textField.textAlignment = .center
            textField.textColor = .textSubtle
            textField.text = domainName

            textField.layer.cornerRadius = Parameters.textFieldCornerRadius

            textField.sizeToFit()

            return textField
        }()

        self.activityIndicator = {
            let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)

            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.hidesWhenStopped = true
            activityIndicator.color = .textSubtle
            activityIndicator.startAnimating()

            return activityIndicator
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

    // MARK: Internal behavior

    /// Triggers the new site to load, once, and only once.
    ///
    func loadSiteIfNeeded() {
        guard initialSiteRequest == nil, let siteURL = URL(string: siteURLString) else {
            return
        }

        let siteRequest = URLRequest(url: siteURL)
        self.initialSiteRequest = siteRequest

        generator.prepare()
        webView.customUserAgent = WPUserAgent.wordPress()
        webView.load(siteRequest)
    }

    // MARK: Private behavior

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white

        webView.navigationDelegate = self

        addSubviews([ textField, webView, activityIndicator ])

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
            activityIndicator.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -Parameters.textFieldHeight)
        ])

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = Parameters.shadowOffset
        layer.shadowOpacity = Parameters.shadowOpacity
        layer.shadowRadius = Parameters.shadowRadius

        // Used to prevent touch highlights on the webview
        let tapRecognizer = UITapGestureRecognizer(target: nil, action: nil)
        tapRecognizer.delegate = self
        webView.addGestureRecognizer(tapRecognizer)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension AssembledSiteView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // This prevents WKWebView's touch highlighting from activating
        return true
    }
}

// MARK: - WKNavigationDelegate

extension AssembledSiteView: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        WPAnalytics.track(.enhancedSiteCreationSuccessPreviewViewed)
    }

    func webView(_ webView: WKWebView, decidePolicyFor: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        guard webViewHasLoadedContent else {
            decisionHandler(.allow)
            return
        }
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewHasLoadedContent = true
        activityIndicator.stopAnimating()
        webView.prepareWPComPreview()
        generator.notificationOccurred(.success)
        WPAnalytics.track(.enhancedSiteCreationSuccessPreviewLoaded)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugPrint(#function + " ERROR : \(error.localizedDescription)")
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }
}
