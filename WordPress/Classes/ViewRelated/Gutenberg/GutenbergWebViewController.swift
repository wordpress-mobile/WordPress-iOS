import UIKit
import WebKit

class GutenbergWebViewController: UIViewController, WebKitAuthenticatable {
    let authenticator: RequestAuthenticator?
    let url: URL
    let blockHTML: String
    var onSave: ((String) -> Void)?

    var webView: WKWebView {
        return view as! WKWebView
    }

    init(with post: AbstractPost, blockHTML: String) {
        authenticator = RequestAuthenticator(blog: post.blog)
        self.blockHTML = blockHTML

        guard let siteURL = post.blog.homeURL else {
            // TODO: This URL won't work. We need to return an error if we don't have an URL.
            url = URL(string: "https://wordpress.com/block-editor/post/new-post")!
            super.init(nibName: nil, bundle: nil)
            return
        }

        // Use wp-admin URL since Calypso URL won't work retriving the block content.
        url = URL(string: "\(siteURL)/wp-admin/post-new.php")!

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = GutenbergWebJavascriptInjection.userContent(messageHandler: self, blockHTML: blockHTML)
        view = WKWebView(frame: .zero, configuration: configuration)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self;
        addNavigationButtons()
        authenticatedRequest(for: url, on: webView) { [weak self] (request) in
            self?.webView.load(request)
        }
    }

    deinit {
        print("---> DEINITED")
    }

    func addNavigationButtons() {
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(onSaveButtonPressed))
        let cancelButton = WPStyleGuide.buttonForBar(with: UIImage.gridicon(.cross), target: self, selector: #selector(onCloseButtonPressed))

        navigationItem.rightBarButtonItem = saveButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        title = NSLocalizedString("Edit on Web", comment: "Title of Gutenberg WEB editor running on a Web View")
    }

    @objc func onSaveButtonPressed() {
        evaluateJavascript("window.getHTMLPostContent()")
    }

    @objc func onCloseButtonPressed() {
        presentingViewController?.dismiss(animated: true)
    }

    func evaluateJavascript(_ script: String) {
        webView.evaluateJavaScript(script) { (response, error) in
            if let response = response {
                print(response)
            }
            if let error = error {
                print(error)
            }
        }
    }

    func save(_ newContent: String) {
        onSave?(newContent)
        webView.configuration.userContentController.removeAllUserScripts()
        presentingViewController?.dismiss(animated: true)
    }

    private let insertCSSScript: String = {
        let css = """
#wp-toolbar {
    display: none;
}

#wpadminbar {
    display: none;
}

#post-title-0 {
    display: none;
}

.block-list-appender {
    display: none;
}

.edit-post-header {
    height: 0px;
    overflow: hidden;
}

.edit-post-header-toolbar__block-toolbar {
    top: 0px;
}

.block-editor-editor-skeleton {
    top: 0px;
}

.edit-post-layout__metaboxes {
    display: none;
}
"""

        return """
const style = document.createElement('style');
style.innerHTML = `\(css)`;
style.type = 'text/css';
document.head.appendChild(style);
"CSS Injected"
"""
    }()
}

extension GutenbergWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        evaluateJavascript(insertCSSScript)
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

        switch messageType {
        case .log:
            print("---> JS: " + body)
        case .htmlPostContent:
            save(body)
        }
    }
}

private extension WKUserContentController {
    func addUserScripts(_ scripts: [WKUserScript]) {
        scripts.forEach {
            addUserScript($0)
        }
    }
}

struct GutenbergWebJavascriptInjection {
    enum JSMessage: String, CaseIterable {
        case htmlPostContent
        case log
    }
    static func userContent(messageHandler handler: WKScriptMessageHandler, blockHTML: String) -> WKUserContentController {
        let userContent = WKUserContentController()
        userContent.addUserScripts([
            WKUserScript(source: incertBlockScript(blockHTML: blockHTML), injectionTime: .atDocumentEnd, forMainFrameOnly: false),
            WKUserScript(source: mutationObserverScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false),
            WKUserScript(source: retriveContentHTMLScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false),
        ])
        JSMessage.allCases.forEach {
            userContent.add(handler, name: $0.rawValue)
        }
        return userContent
    }

    private static let retriveContentHTMLScript = """
window.getHTMLPostContent = () => {
    const blocks = window.wp.data.select('core/block-editor').getBlocks();
    const HTML = window.wp.blocks.serialize( blocks );
    window.webkit.messageHandlers.htmlPostContent.postMessage(HTML);
}
"""

    private static func incertBlockScript(blockHTML: String) -> String { return """
window.insertBlock = () => {
    window.setTimeout(() => {
        window.webkit.messageHandlers.log.postMessage("HEADER READY!!");
        const blockHTML = `\(blockHTML)`;
        let blocks = window.wp.blocks.parse(blockHTML);
        window.wp.data.dispatch('core/block-editor').resetBlocks(blocks);
    }, 0);
};
"""
    }

    /// Script that observe DOM mutations and calls `insertBlock` when it's appropiate.
    private static let mutationObserverScript = """
window.onload = () => {
    const content = document.getElementById('wpbody-content');
    if (content) {
        window.insertBlock();
        const callback = function(mutationsList, observer) {
            window.webkit.messageHandlers.log.postMessage("UPDATED!");
            const header = document.getElementsByClassName("edit-post-header")[0];
            if (header) {
                window.insertBlock();
                observer.disconnect();
            }
        };
        const observer = new MutationObserver(callback);
        const config = { attributes: true, childList: true, subtree: true };
        observer.observe(content, config);
    }
}
"""
}
