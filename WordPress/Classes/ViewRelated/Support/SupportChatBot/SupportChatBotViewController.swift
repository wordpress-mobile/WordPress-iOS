import WebKit
import WordPressFlux
import SVProgressHUD

protocol SupportChatBotCreatedTicketDelegate: AnyObject {
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
                                                    value: "What can I help you with? If I can't answer your question I'll help you open a support ticket with our team!",
                                                    comment: "Initial message shown to the user when the chat starts.")
        static let sources = NSLocalizedString("support.chatBot.sources",
                                               value: "Sources",
                                               comment: "Button title referring to the sources of information.")
        static let helpful = NSLocalizedString("chat.rateHelpful",
                                               value: "Rate as helpful",
                                               comment: "Option for users to rate a chat bot answer as helpful.")
        static let unhelpful = NSLocalizedString("support.chatBot.reportInaccuracy",
                                                 value: "Report as innacurate",
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
