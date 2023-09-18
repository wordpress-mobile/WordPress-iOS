import WebKit
import WordPressFlux
import SVProgressHUD
import WordPressShared

protocol SupportChatBotCreatedTicketDelegate: AnyObject {
    func onTicketCreated()
}

final class SupportChatBotViewController: UIViewController {
    private let viewModel: SupportChatBotViewModel
    private weak var delegate: SupportChatBotCreatedTicketDelegate?
    private lazy var webView: WKWebView = {
        let contentController = WKUserContentController()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        webView.configuration.userContentController.add(self, name: Constants.supportCallback)
        webView.configuration.userContentController.add(self, name: Constants.errorCallback)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        /// Message handlers need to be removed to prevent memory leaks
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
    }

    override func loadView() {
        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.title
        setupNavigationBar()
        loadChatBot()

        viewModel.track(.supportChatbotStarted)
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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.track(.supportChatbotEnded)
    }

    /// Creating DocsBotAI JavaScript code so we could tweak configuration from within Swift code
    /// https://docsbot.ai/docs/embeddable-chat-widget
    private func createDocsBotInitCode() -> String {
        """
        (function() {
            // support_chat_widget.js
            window.prepareDocsBotForPresentation();

            DocsBotAI.init({
                id: '\(viewModel.docsBotId)',
                identify: {
                    chatId: '\(viewModel.chatId)',
                },
                supportCallback: function (event, history) {
                    event.preventDefault()
                    window.webkit.messageHandlers.supportCallback.postMessage(history)
                },
                options: {
                    color: "#9dd977",
                    supportLink: "#",
                    questions: \(encodedQuestions()),
                    labels: {
                        inputPlaceholder: "\(Strings.inputPlaceholder)",
                        firstMessage: "\(Strings.firstMessage)",
                        sources: "\(Strings.sources)",
                        helpful: "\(Strings.helpful)",
                        unhelpful: "\(Strings.unhelpful)",
                        getSupport: "\(Strings.getSupport)",
                        suggestions: "\(Strings.suggestions)",
                        thinking: "\(Strings.thinking)",
                      },
                },
            })
        })();
        """
    }

    /// Encoding array of Swift strings into JS string representing an array
    private func encodedQuestions() -> String {
        do {
            let encodedQuestions = try JSONEncoder().encode(Strings.questions)
            return String(data: encodedQuestions, encoding: .utf8) ?? ""
        } catch {
            DDLogError("Couldn't encode default questions for support chat bot: \(error)")
            return ""
        }
    }
}

private extension SupportChatBotViewController {
    func setupNavigationBar() {
        if isModal() {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.closeButton,
                                                               style: WPStyleGuide.barButtonStyleForBordered(),
                                                               target: self,
                                                               action: #selector(closeTapped))
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
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

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated:
            if let url = navigationAction.request.url {
                // Open links tapped from within the chat in the system browser
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        default:
            decisionHandler(.allow)
        }
    }

}

// MARK: - Support Callback

extension SupportChatBotViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == Constants.supportCallback, let messageHistory = message.body as? [[String]] {
            let history = SupportChatHistory(messageHistory: messageHistory)
            createTicket(with: history)
        } else if message.name == Constants.errorCallback, let payload = message.body as? [String: Any], let errorMessage = payload["message"] as? String {
            viewModel.track(.supportChatbotWebViewError, errorMessage: errorMessage)
        }
    }
}

extension SupportChatBotViewController {
    private enum Strings {
        static let title = NSLocalizedString("support.chatBot.title", value: "Contact Support", comment: "Title of the view that shows support chat bot.")
        static let closeButton = NSLocalizedString("support.chatBot.close.title", value: "Close", comment: "Dismiss the current view")
        static let ticketCreationLoadingMessage = NSLocalizedString("support.chatBot.ticketCreationLoading", value: "Creating support ticket...", comment: "Notice informing user that their support ticket is being created.")
        static let ticketCreationSuccessMessage = NSLocalizedString("support.chatBot.ticketCreationSuccess", value: "Ticket created", comment: "Notice informing user that their support ticket has been created.")
        static let ticketCreationFailureMessage = NSLocalizedString("support.chatBot.ticketCreationFailure", value: "Error submitting support ticket", comment: "Notice informing user that there was an error submitting their support ticket.")
        static let questions: [String] = [
            NSLocalizedString("support.chatBot.questionOne", value: "What is my site address?", comment: "An example question shown to a user seeking support"),
            NSLocalizedString("support.chatBot.questionTwo", value: "Help, my site is down!", comment: "An example question shown to a user seeking support"),
            NSLocalizedString("support.chatBot.questionThree", value: "I can't upload photos/videos", comment: "An example question shown to a user seeking support"),
            NSLocalizedString("support.chatBot.questionFour", value: "Why can't I login?", comment: "An example question shown to a user seeking support"),
            NSLocalizedString("support.chatBot.questionFive", value: "I forgot my login information", comment: "An example question shown to a user seeking support"),
            NSLocalizedString("support.chatBot.questionSix", value: "How can I use my custom domain in the app?", comment: "An example question shown to a user seeking support"),
        ]
        static let inputPlaceholder = NSLocalizedString("support.chatBot.inputPlaceholder",
                                                        value: "Send a message...",
                                                        comment: "Placeholder text for the chat input field.")
        static let firstMessage = NSLocalizedString("support.chatBot.firstMessage",
                                                    value: "Hi there, I'm the Jetpack AI Assistant.\\n\\nWhat can we help you with?\\n\\nIf I can't answer your question, I'll help you open a support ticket with our team!",
                                                    comment: "Initial message shown to the user when the chat starts.")
        static let sources = NSLocalizedString("support.chatBot.sources",
                                               value: "Sources",
                                               comment: "Button title referring to the sources of information.")
        static let helpful = NSLocalizedString("chat.rateHelpful",
                                               value: "Rate as helpful",
                                               comment: "Option for users to rate a chat bot answer as helpful.")
        static let unhelpful = NSLocalizedString("support.chatBot.reportInaccuracy",
                                                 value: "Report as inaccurate",
                                                 comment: "Option for users to report a chat bot answer as inaccurate.")
        static let getSupport = NSLocalizedString("support.chatBot.contactSupport",
                                                  value: "Contact support",
                                                  comment: "Button for users to contact the support team directly.")
        static let suggestions = NSLocalizedString("support.chatBot.suggestionsPrompt",
                                                   value: "Not sure what to ask?",
                                                   comment: "Prompt for users suggesting to select a default question from the list to start a support chat.")
        static let thinking = NSLocalizedString("support.chatBot.botThinkingIndicator",
                                                value: "Thinking...",
                                                comment: "Indicator that the chat bot is processing user's input.")

    }

    private enum Constants {
        static let supportCallback = "supportCallback"
        static let errorCallback = "errorCallback"
    }
}

// MARK: - Helpers

extension SupportChatBotViewController {
    func createTicket(with history: SupportChatHistory) {
        SVProgressHUD.show(withStatus: Strings.ticketCreationLoadingMessage)

        viewModel.contactSupport(including: history, in: self) { [weak self] result in
            SVProgressHUD.dismiss()

            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.viewModel.track(.supportChatbotTicketSuccess)
                    self.showTicketCreatedSuccessNotice()
                case .failure(let failure):
                    self.viewModel.track(.supportChatbotTicketFailure, errorMessage: failure.localizedDescription)
                    self.showTicketCreatedFailureNotice()
                }
            }
        }
    }

    func showTicketCreatedSuccessNotice() {
        let notice = Notice(title: Strings.ticketCreationSuccessMessage, feedbackType: .success)
        ActionDispatcher.dispatch(NoticeAction.post(notice))

        delegate?.onTicketCreated()
    }

    func showTicketCreatedFailureNotice() {
        let notice = Notice(title: Strings.ticketCreationFailureMessage, feedbackType: .error)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }
}
