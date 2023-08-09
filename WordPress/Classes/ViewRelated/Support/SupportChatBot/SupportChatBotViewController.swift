import WebKit

final class SupportChatBotViewController: UIViewController {
    private let viewModel: SupportChatBotViewModel
    private lazy var webView: WKWebView = {
        let contentController = WKUserContentController()
        contentController.add(self, name: Constants.supportCallback)
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        return webView
    }()

    init(viewModel: SupportChatBotViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.title
        loadChatBot()
    }

    private func loadChatBot() {
        if let url = viewModel.url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Creating DocsBotAI JavaScript code so we could tweak configuration from within Swift code
    /// https://docsbot.ai/docs/embeddable-chat-widget
    private func createDocsBotInitCode() -> String {
        """
        (function() {
            DocsBotAI.init({
                id: '\(viewModel.id)',
                 supportCallback: function (event, history) {
                    event.preventDefault()
                    window.webkit.messageHandlers.supportCallback.postMessage(history)
                  },
                options: {
                    horizontalMargin: 40,
                    verticalMargin: 60,
                    supportLink: "#"
                },
            })
            setTimeout(() => {
                DocsBotAI.open()
            }, 200);
        })();
        """
    }
}

extension SupportChatBotViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript(createDocsBotInitCode(), completionHandler: { (result, error) in
            if let error = error {
                DDLogError("Failed to initialize docs bot code: \(error)")
            }
        })
    }
}

// MARK: - Support Callback

extension SupportChatBotViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == Constants.supportCallback, let messages = message.body as? [[String]] {

            // TODO: Loading indicators
            viewModel.contactSupport(including: SupportChatHistory(messages: messages)) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
}

extension SupportChatBotViewController {
    private enum Strings {
        static let title = NSLocalizedString("support.chatBot.title", value: "Contact Support", comment: "Title of the view that shows support chat bot.")
    }

    private enum Constants {
        static let supportCallback = "supportCallback"
    }
}
