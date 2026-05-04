import Logging
import UIKit
@preconcurrency import WebKit
import WordPressShared

/// A minimal `WKWebView` host for the Publicize OAuth kick-off flow.
///
/// Navigation routing is delegated to
/// `PublicizeConnectionURLMatcher.authorizeAction(for:)`, which handles
/// every wp.com Publicize service (Mastodon, Bluesky, Facebook, LinkedIn, …).
///
/// Success is fired from `didFinish` after the `action=verify` URL loads,
/// because the wp.com server needs that request to actually complete in
/// order to persist the keyring record; cancelling the navigation earlier
/// would leave the user staring at a "request couldn't be completed" page.
public final class SocialOAuthWebViewController: UIViewController, WKNavigationDelegate {
    public enum Outcome: Sendable {
        case success
        case cancelled
        case failure(Error)
    }

    private let startURL: URL
    private let serviceLabel: String
    private let authenticator: any SocialOAuthAuthenticator
    private let onOutcome: (Outcome) -> Void

    private var loadingVerify = false
    private var didReport = false

    private let titleLabel = UILabel()
    private let hostLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private var kvoObservations: [NSKeyValueObservation] = []

    private static let log = Logger(label: "org.wordpress.jetpack-social.oauth-webview")

    public init(
        startURL: URL,
        serviceLabel: String,
        authenticator: any SocialOAuthAuthenticator,
        onOutcome: @escaping (Outcome) -> Void
    ) {
        self.startURL = startURL
        self.serviceLabel = serviceLabel
        self.authenticator = authenticator
        self.onOutcome = onOutcome
        super.init(nibName: nil, bundle: nil)
    }

    private var defaultTitle: String {
        String.localizedStringWithFormat(Strings.OAuthWebView.connectTitleFormat, serviceLabel)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        // A non-persistent data store keeps OAuth cookies local to this
        // webview instance. Persisting them across attempts leaks
        // half-finished session state into subsequent retries, which for
        // services like Mastodon surfaces as a 404 after Authorize.
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let web = WKWebView(frame: .zero, configuration: configuration)
        web.translatesAutoresizingMaskIntoConstraints = false
        web.navigationDelegate = self
        web.customUserAgent = WPUserAgent.wordPress()
        view.addSubview(web)
        NSLayoutConstraint.activate([
            web.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            web.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            web.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        configureTitleView()
        configureProgressView(on: web)
        observeWebView(web)

        let cookieStore = web.configuration.websiteDataStore.httpCookieStore
        Task { [weak self, weak web] in
            guard let self else { return }
            let request = await self.authenticator.authenticatedRequest(
                for: self.startURL,
                into: cookieStore
            )
            await MainActor.run { [weak web] in web?.load(request) }
        }
    }

    private func report(_ outcome: Outcome) {
        guard !didReport else { return }
        didReport = true
        onOutcome(outcome)
    }

    private func dismissSelf() {
        if let navigationController {
            navigationController.dismiss(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - Navigation bar title + progress

    private func configureTitleView() {
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.text = defaultTitle

        hostLabel.font = .preferredFont(forTextStyle: .caption2)
        hostLabel.textColor = .secondaryLabel
        hostLabel.textAlignment = .center
        hostLabel.lineBreakMode = .byTruncatingTail
        hostLabel.text = startURL.host

        let stack = UIStackView(arrangedSubviews: [titleLabel, hostLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        navigationItem.titleView = stack
    }

    private func configureProgressView(on webView: WKWebView) {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true
        view.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func observeWebView(_ webView: WKWebView) {
        kvoObservations.append(
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] web, _ in
                Task { @MainActor [weak self] in
                    self?.updateProgress(Float(web.estimatedProgress))
                }
            }
        )
        kvoObservations.append(
            webView.observe(\.title, options: [.new]) { [weak self] web, _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let pageTitle = web.title ?? ""
                    self.titleLabel.text = pageTitle.isEmpty ? self.defaultTitle : pageTitle
                }
            }
        )
        kvoObservations.append(
            webView.observe(\.url, options: [.new]) { [weak self] web, _ in
                Task { @MainActor [weak self] in
                    self?.hostLabel.text = web.url?.host ?? self?.startURL.host
                }
            }
        )
    }

    private func updateProgress(_ progress: Float) {
        progressView.progress = progress
        progressView.isHidden = progress >= 1.0 || progress <= 0.0
    }

    // MARK: - WKNavigationDelegate

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        // Prevent a second verify load by someone happy-clicking.
        guard !loadingVerify, let url = navigationAction.request.url else {
            return .cancel
        }

        switch PublicizeConnectionURLMatcher.authorizeAction(for: url) {
        case .none, .unknown, .request:
            return .allow
        case .verify:
            loadingVerify = true
            return .allow
        case .deny:
            report(.cancelled)
            dismissSelf()
            return .cancel
        }
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        let nsError = error as NSError
        // Some services (historically Facebook, Twitter) return a spurious
        // `NSURLErrorCancelled` during the verify step even though the
        // connection actually succeeded on the server. Treat that as success.
        if loadingVerify && nsError.code == NSURLErrorCancelled {
            report(.success)
            return
        }
        Self.log.error(
            "OAuth navigation failed: url=\(webView.url?.absoluteString ?? "nil") domain=\(nsError.domain) code=\(nsError.code) description=\(nsError.localizedDescription)"
        )
        report(.failure(error))
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        Self.log.error("OAuth web content process terminated: url=\(webView.url?.absoluteString ?? "nil")")
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if loadingVerify {
            report(.success)
        }
    }
}
