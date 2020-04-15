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
        webView.evaluateJavaScript("window.onSave()") { (response, error) in
            if let response = response {
                print(response)
            }
            if let error = error {
                print(error)
            }
        }
    }

    @objc func onCloseButtonPressed() {
        presentingViewController?.dismiss(animated: true)
    }

    func save(_ newContent: String) {
        onSave?(newContent)
        webView.configuration.userContentController.removeAllUserScripts()
        presentingViewController?.dismiss(animated: true)
    }
}

extension GutenbergWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "log":
            if let content = message.body as? String {
                print("---> JS: " + content)
            }
        case "onSave":
            if let newContent = message.body as? String {
                save(newContent)
            }
        default: break
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
    static func userContent(messageHandler handler: WKScriptMessageHandler, blockHTML: String) -> WKUserContentController {
        let userContent = WKUserContentController()
        userContent.addUserScripts([
            WKUserScript(source: incertBlockScript(blockHTML: blockHTML), injectionTime: .atDocumentEnd, forMainFrameOnly: false),
            WKUserScript(source: cleanUIScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false),
            WKUserScript(source: retriveContentHTMLScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false),
        ])
        userContent.add(handler, name: "onSave")
        userContent.add(handler, name: "log")

        return userContent
    }

    private static let retriveContentHTMLScript = """
window.onSave = () => {
    const blocks = window.wp.data.select('core/block-editor').getBlocks();
    const HTML = window.wp.blocks.serialize( blocks );
    window.webkit.messageHandlers.onSave.postMessage(HTML);
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

    private static let cleanUIScript = """
window.onload = () => {
    const wpAdminBar = document.getElementById('wpadminbar');
    const wpToolbar = document.getElementById('wp-toolbar');
    if (wpAdminBar) {
        wpAdminBar.style.display = 'none';
    }
    if (wpToolbar) {
        wpToolbar.style.display = 'none';
    }

    const content = document.getElementById('wpbody-content');
    if (content) {
        const callback = function(mutationsList, observer) {
            window.webkit.messageHandlers.log.postMessage("UPDATED!");
            const header = document.getElementsByClassName("edit-post-header")[0];
            const postTitle = document.getElementById('post-title-0');
            if (postTitle && header.id == '') {
                header.id = 'gb-header';
                header.style.height = 0;
                postTitle.style.display = 'none';
                Array.from(header.children).forEach( (child) => {
                    child.style.display = 'none';
                });

                const headerToolbar = header.getElementsByClassName('edit-post-header-toolbar')[0];
                headerToolbar.style.display = null;
                headerToolbar.parentNode.style.display = null;
                const inserterToggle = header.getElementsByClassName('block-editor-inserter__toggle')[0];
                inserterToggle.style.display = 'none';

                const blockToolbar = header.getElementsByClassName('edit-post-header-toolbar__block-toolbar')[0];
                blockToolbar.style.top = '0px';

                const skeleton = document.getElementsByClassName('block-editor-editor-skeleton')[0];
                skeleton.style.top = '0px';

                const appender = document.getElementsByClassName('block-list-appender')[0];
                if (appender && appender.id == '') {
                    appender.id = 'appender';
                    appender.style.display = 'none';
                }

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
