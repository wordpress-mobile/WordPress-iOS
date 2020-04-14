import UIKit
import WebKit

class GutenbergWebViewController: UIViewController, WebKitAuthenticatable {
    let authenticator: RequestAuthenticator?
    let url: URL
    var onSave: ((String) -> Void)?

    var webView: WKWebView {
        return view as! WKWebView
    }

    init(with post: AbstractPost) {
        authenticator = RequestAuthenticator(blog: post.blog)

        guard let postID = post.postID as? Int, let siteURL = post.blog.hostURL else {
            url = URL(string: "https://wordpress.com/block-editor/post/new-post")!
            super.init(nibName: nil, bundle: nil)
            return
        }

        url = URL(string: "https://wordpress.com/block-editor/post/\(siteURL)/\(postID)")!

        super.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .fullScreen

        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(onSaveButtonPressed))
        navigationItem.rightBarButtonItem = saveButton
    }

    @objc func onSaveButtonPressed() {
        webView.evaluateJavaScript("document.test()") { (result, error) in
            if let error = error {
                print(error)
            }
            if let result = result {
                print(result)
            }
        }
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

        webView.navigationDelegate = self
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

extension GutenbergWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("---> DID FINISH!!!")
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
            WKUserScript(source: requestInterceptionScript, injectionTime: .atDocumentStart, forMainFrameOnly: false),
            WKUserScript(source: cleanUIScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false),
            WKUserScript(source: nativeActionsScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false),
        ])
        userContent.add(handler, name: "onSave")
        userContent.add(handler, name: "log")

        return userContent
    }

    private static var requestInterceptionScript = """
(function(open) {
  XMLHttpRequest.prototype.open = function(arg1, arg2) {
    this.URL = arg2;
    this.method = arg1;
    open.apply(this, arguments);
  };
})(XMLHttpRequest.prototype.open);

(function(send) {
  XMLHttpRequest.prototype.send = function(arg1) {
    if (this.URL.includes('/posts/') && this.method === "PUT") {
      window.webkit.messageHandlers.log.postMessage("--> Saving....");
      window.webkit.messageHandlers.onSave.postMessage(arg1);
      this.abort();
      return;
    }
    send.apply(this, arguments);
  };
})(XMLHttpRequest.prototype.send);
"""

    private static var cleanUIScript = """
window.onload = () => {
    $(document).bind('DOMSubtreeModified',function() {
        window.webkit.messageHandlers.log.postMessage("Changed!!");
        const header = document.getElementsByClassName("edit-post-header")[0];
        if (header && header.id == '') {
            header.id = 'gb-header';
    //        header.style.display = 'none';
        }
    });
}

"""

    private static var nativeActionsScript = """
document.test = () => {
    window.webkit.messageHandlers.log.postMessage("Hello world");
}
"""
}
