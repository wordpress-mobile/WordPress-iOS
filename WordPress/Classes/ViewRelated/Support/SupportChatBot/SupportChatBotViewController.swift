import WebKit
import WordPressFlux
import SVProgressHUD

protocol SupportChatBotCreatedTicketDelegate: class {
    func onTicketCreated()
}

final class SupportChatBotViewController: UIViewController {
    private let viewModel: SupportChatBotViewModel
    private weak var delegate: SupportChatBotCreatedTicketDelegate?
    private lazy var webView: WKWebView = {
        let contentController = WKUserContentController()
        contentController.add(self, name: Constants.supportCallback)
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        return webView
    }()

    init(viewModel: SupportChatBotViewModel, delegate: SupportChatBotCreatedTicketDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
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
            // support_chat_widget.js
            window.prepareDocsBotForPresentation();

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
        if message.name == Constants.supportCallback, let messageHistory = message.body as? [[String]] {
            let history = SupportChatHistory(messageHistory: messageHistory)
            createTicket(with: history)
        }
    }
}

extension SupportChatBotViewController {
    private enum Strings {
        static let title = NSLocalizedString("support.chatBot.title", value: "Contact Support", comment: "Title of the view that shows support chat bot.")
        static let ticketCreationLoadingMessage = NSLocalizedString("support.chatBot.ticketCreationLoading", value: "Creating support ticket...", comment: "Notice informing user that their support ticket is being created.")
        static let ticketCreationSuccessMessage = NSLocalizedString("support.chatBot.ticketCreationSuccess", value: "Ticket created", comment: "Notice informing user that their support ticket has been created.")
        static let ticketCreationFailureMessage = NSLocalizedString("support.chatBot.ticketCreationFailure", value: "Error submitting support ticket", comment: "Notice informing user that there was an error submitting their support ticket.")
    }

    private enum Constants {
        static let supportCallback = "supportCallback"
    }
}

// MARK: - Helpers

extension SupportChatBotViewController {
    func createTicket(with history: SupportChatHistory) {
        SVProgressHUD.show(withStatus: Strings.ticketCreationLoadingMessage)

        viewModel.contactSupport(including: history) { [weak self] success in
            SVProgressHUD.dismiss()

            guard let self else { return }
            DispatchQueue.main.async {
                if success {
                    self.showTicketCreatedSuccessNotice()
                } else {
                    self.showTicketCreatedFailureNotice()
                }
            }
        }
    }

    func showTicketCreatedSuccessNotice() {
        let notice = Notice(title: Strings.ticketCreationSuccessMessage,
                            feedbackType: .success,
                            actionTitle: "See ticket",
                            actionHandler: { [weak self] _ in
            guard let self else { return }

            self.delegate?.onTicketCreated()
        })
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func showTicketCreatedFailureNotice() {
        let notice = Notice(title: Strings.ticketCreationFailureMessage, feedbackType: .error)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }
}
