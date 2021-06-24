import UIKit
import WebKit
import Gutenberg

class GutenbergWebViewController: GutenbergWebSingleBlockViewController, WebKitAuthenticatable, NoResultsViewHost {
    enum GutenbergWebError: Error {
        case wrongEditorUrl(String?)
    }

    let authenticator: RequestAuthenticator?
    private let url: URL
    private let progressView = WebProgressView()
    private let userId: String
    let gutenbergReadySemaphore = DispatchSemaphore(value: 0)

    init(with post: AbstractPost, block: Block) throws {
        authenticator = GutenbergRequestAuthenticator(blog: post.blog)
        userId = "\(post.blog.userID ?? 1)"

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
        showLoadingMessage()
        addProgressView()
        startObservingWebView()
        waitForGutenbergToLoad(fallback: showTroubleshootingInstructions)
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

    override func onPageLoadScripts() -> [WKUserScript] {
        return [
            loadCustomScript(named: "extra-localstorage-entries", with: userId)
        ].compactMap { $0 }
    }

    override func onGutenbergReadyScripts() -> [WKUserScript] {
        return [
            loadCustomScript(named: "remove-nux")
        ].compactMap { $0 }
    }

    override func onGutenbergReady() {
        super.onGutenbergReady()
        navigationItem.rightBarButtonItem?.isEnabled = true
        DispatchQueue.main.async { [weak self] in
            self?.hideNoResults()
            self?.gutenbergReadySemaphore.signal()
        }
    }

    private func loadCustomScript(named name: String, with argument: String? = nil) -> WKUserScript? {
        do {
            return try SourceFile(name: name, type: .js).jsScript(with: argument)
        } catch {
            assertionFailure("Failed to load `\(name)` JS script for Unsupported Block Editor: \(error)")
            return nil
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
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    private func showLoadingMessage() {
        let title = NSLocalizedString("Loading the block editor.", comment: "Loading message shown while the Unsupported Block Editor is loading.")
        let subtitle = NSLocalizedString("Please ensure the block editor is enabled on your site. If it is not enabled, it will not load.", comment: "Message asking users to make sure that the block editor is enabled on their site in order for the Unsupported Block Editor to load properly.")
        configureAndDisplayNoResults(on: view, title: title, subtitle: subtitle, accessoryView: NoResultsViewController.loadingAccessoryView())
    }

    private func waitForGutenbergToLoad(fallback: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            let timeout: TimeInterval = 15
            // blocking call
            if self?.gutenbergReadySemaphore.wait(timeout: .now() + timeout) == .timedOut {
                DispatchQueue.main.async {
                    fallback()
                }
            }
        }
    }

    private func showTroubleshootingInstructions() {
        let title = NSLocalizedString("Unable to load the block editor right now.", comment: "Title message shown when the Unsupported Block Editor fails to load.")
        let subtitle = NSLocalizedString("Please ensure the block editor is enabled on your site and try again.", comment: "Subtitle message shown when the Unsupported Block Editor fails to load. It asks users to verify that the block editor is enabled on their site before trying again.")
        // This does nothing if the "no results" screen is not currently displayed, which is the intended behavior
        updateNoResults(title: title, subtitle: subtitle, image: "cloud")
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

extension GutenbergWebViewController {
    override func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        super.webView(webView, didCommit: navigation)
        if webView.url?.absoluteString.contains("reauth=1") ?? false {
            hideNoResults()
            removeCoverViewAnimated()
        }
    }
}
