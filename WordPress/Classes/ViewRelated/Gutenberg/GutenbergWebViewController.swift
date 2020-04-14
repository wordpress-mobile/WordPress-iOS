import UIKit
import WebKit

class GutenbergWebViewController: UIViewController, WebKitAuthenticatable {
    let authenticator: WebViewAuthenticator?
    let url: URL
    var onSave: ((String) -> Void)?

    var webView: WKWebView {
        return view as! WKWebView
    }

    init(with post: AbstractPost) {
        authenticator = WebViewAuthenticator(blog: post.blog)

        guard let postID = post.postID as? Int, let siteURL = post.blog.hostURL else {
            url = URL(string: "https://wordpress.com/block-editor/post/new-post")!
            super.init(nibName: nil, bundle: nil)
            return
        }

        url = URL(string: "https://wordpress.com/block-editor/post/\(siteURL)/\(postID)")!

        super.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .fullScreen
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = GutenbergWebJavascriptInjection.userContent(messageHandler: self)
        view = WKWebView(frame: .zero, configuration: configuration)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        authenticatedRequest(for: url, on: webView) { [weak self] (request) in
            self?.webView.load(request)
        }
    }

    deinit {
        print("---> DEINITED")
    }
}

private struct SaveResponse: Decodable {
    let content: String
}

extension GutenbergWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "onSave":
            if let content = message.body as? String, let data = content.data(using: .utf8) {
                do {
                    let response = try JSONDecoder().decode(SaveResponse.self, from: data)
                    onSave?(response.content)
                    webView.configuration.userContentController.removeAllUserScripts()
                    presentingViewController?.dismiss(animated: true)
                } catch {
                    DDLogError(error.localizedDescription)
                }
            }
        case "log":
            if let content = message.body as? String {
                print("---> JS: " + content)
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
    static func userContent(messageHandler handler: WKScriptMessageHandler) -> WKUserContentController {
        let userContent = WKUserContentController()
        userContent.addUserScripts([
//            WKUserScript(source: requestInterceptionScript, injectionTime: .atDocumentStart, forMainFrameOnly: false),
            WKUserScript(source: cleanUIScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        ])
        userContent.add(handler, name: "onSave")
        userContent.add(handler, name: "log")

        return userContent
    }

    private static var requestInterceptionScript = """
window.webkit.messageHandlers.log.postMessage("--> HELLO WORLD v2!!");
"""

    private static var cleanUIScript = """
$(document).bind('DOMSubtreeModified',function(){
    window.webkit.messageHandlers.log.postMessage("Changed!!");
    const header = document.getElementsByClassName("edit-post-header")[0];
    window.webkit.messageHandlers.log.postMessage(String(header));
    if (header) {
        const publishButton = header.getElementsByClassName("editor-post-publish-button")[0]
        if (publishButton) {
            publishButton.textContent = "Save"
        }
        const settingsBar = header.getElementsByClassName("edit-post-header__settings")[0]
        const listArray = Array.from( settingsBar.children );
        listArray.forEach( (item) => { settingsBar.removeChild(item) } );
        settingsBar.appendChild(publishButton);
    }
});
"""
}
