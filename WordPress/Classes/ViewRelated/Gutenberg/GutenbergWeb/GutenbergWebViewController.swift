import UIKit
import WebKit
import Gutenberg

class GutenbergWebViewController: UIViewController, WebKitAuthenticatable {
    enum GutenbergWebError: Error {
        case wrongEditorUrl(String?)
    }

    let authenticator: RequestAuthenticator?
    var onSave: ((Block) -> Void)?

    private let url: URL
    private let block: Block
    private let jsInjection: GutenbergWebJavascriptInjection

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = jsInjection.userContent(messageHandler: self, blockHTML: block.content)
        return WKWebView(frame: .zero, configuration: configuration)
    }()

    init(with post: AbstractPost, block: Block) throws {
        authenticator = RequestAuthenticator(blog: post.blog)
        self.block = block

        jsInjection = try GutenbergWebJavascriptInjection(blockHTML: block.content, userId: "\(post.blog.userID ?? 1)")
        guard
            let siteURL = post.blog.homeURL,
            // Use wp-admin URL since Calypso URL won't work retriving the block content.
            let editorURL = URL(string: "\(siteURL)/wp-admin/post-new.php")
        else {
            throw GutenbergWebError.wrongEditorUrl(post.blog.homeURL as String?)
        }

        url = editorURL

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        addNavigationBarElements()
        loadWebView()
    }

    private func loadWebView() {
        authenticatedRequest(for: url, on: webView) { [weak self] (request) in
            self?.webView.load(request)
        }
    }

    @objc func onSaveButtonPressed() {
        evaluateJavascript(jsInjection.getHtmlContentScript)
    }

    @objc func onCloseButtonPressed() {
        dismiss()
    }

    private func addNavigationBarElements() {
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(onSaveButtonPressed))
        let cancelButton = WPStyleGuide.buttonForBar(with: UIImage.gridicon(.cross), target: self, selector: #selector(onCloseButtonPressed))

        navigationItem.rightBarButtonItem = saveButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        let localizedTitle = NSLocalizedString("Edit %@", comment: "Title of Gutenberg WEB editor running on a Web View. %@ is the localized block name.")
        title = String(format: localizedTitle, block.name)
    }

    private func evaluateJavascript(_ script: WKUserScript) {
        webView.evaluateJavaScript(script.source) { (response, error) in
            if let response = response {
                DDLogVerbose("\(response)")
            }
            if let error = error {
                DDLogError("\(error)")
            }
        }
    }

    private func save(_ newContent: String) {
        onSave?(block.replacingContent(with: newContent))
        dismiss()
    }

    private func dismiss() {
        cleanUpWebView()
        presentingViewController?.dismiss(animated: true)
    }

    private func cleanUpWebView() {
        webView.configuration.userContentController.removeAllUserScripts()
        GutenbergWebJavascriptInjection.JSMessage.allCases.forEach {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: $0.rawValue)
        }
    }
}

extension GutenbergWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.response.url?.absoluteString.contains("/wp-admin/post-new.php") ?? false {
            evaluateJavascript(jsInjection.insertBlockScript)
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // At this point, user scripts are not loaded yet, so we need to inject the
        // script that inject css manually before actually injecting the css.
        evaluateJavascript(jsInjection.injectCssScript)
        evaluateJavascript(jsInjection.injectEditorCssScript)
        evaluateJavascript(jsInjection.injectWPBarsCssScript)
        evaluateJavascript(jsInjection.injectLocalStorageScript)

    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Sometimes the editor takes longer loading and its CSS can override what
        // Injectic Editor specific CSS when everything is loaded to avoid overwritting parameters if gutenberg CSS load later.
        evaluateJavascript(jsInjection.injectEditorCssScript)
    }
}

extension GutenbergWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            let messageType = GutenbergWebJavascriptInjection.JSMessage(rawValue: message.name),
            let body = message.body as? String
        else {
            return
        }

        handle(messageType, body: body)
    }

    private func handle(_ message: GutenbergWebJavascriptInjection.JSMessage, body: String) {
        switch message {
        case .log:
            print("---> JS: " + body)
        case .htmlPostContent:
            save(body)
        }
    }
}
