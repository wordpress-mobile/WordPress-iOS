import SwiftUI

public struct ConversationView: View {

    enum ViewState: Equatable {
        case idle
        case loadingMessages
        case loadingMessagesError(Error)
        case startingNewConversation
        case conversationNotFound
        case sendingMessage(String, Task<Void, Never>)
        case sendingMessageError(Error)

        static func == (lhs: ConversationView.ViewState, rhs: ConversationView.ViewState) -> Bool {
            return switch (lhs, rhs) {
            case (.idle, .idle): true
            case (.loadingMessages, .loadingMessages): true
            case (.loadingMessagesError, .loadingMessagesError): true
            case (.startingNewConversation, .startingNewConversation): true
            case (.conversationNotFound, .conversationNotFound): true
            case (.sendingMessage, .sendingMessage): true
            case (.sendingMessageError, .sendingMessageError): true
            default: false
            }
        }
    }

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    @State
    var conversation: BotConversation?

    @State
    var currentUser: SupportUser

    @State
    var state: ViewState = .idle

    @State
    private var showThinkingView = false

    @Namespace
    var bottom

    var messages: [BotMessage] {
        self.conversation?.messages ?? []
    }

    var isSendingMessage: Bool {
        return switch self.state {
        case .sendingMessage: true
        default: false
        }
    }

    var title: String {
        self.conversation?.title ?? "New Conversation"
    }

    private var loadingTask: Task<Void, Error>?

    public init(conversation: BotConversation?, currentUser: SupportUser) {
        self.conversation = conversation
        self.currentUser = currentUser
    }

    public var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                List() {
                    Section {
                        ConversationBotIntro(currentUser: currentUser)
                    }

                    loadingMessagesError

                    Section {
                        ForEach(self.messages) { message in
                            MessageView(message: message).id(message.id)
                        }

                        sendingMessageView(proxy: proxy).onChange(of: self.state) { oldValue, newValue in
                            self.scrollToBottom(using: proxy, animated: true)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
                    .listRowBackground(Color.clear)

                    sendingMessageError

                    switchToHumanSupport

                    Text("").padding(.bottom, 0)
                        .listRowInsets(.zero)
                        .listRowBackground(Color.clear)
                        .listRowSpacing(0)
                        .id(self.bottom)
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    scrollToBottom(using: proxy, animated: false)
                }
            }
            .navigationTitle(self.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            VStack {
                Spacer()
                CompositionView(
                    disabled: self.isSendingMessage,
                    action: self.sendMessage
                )
            }
        }
        .task {
            if case .idle = self.state {
                await self.loadExistingConversation()
            }
        }
        .onChange(of: state) { _, newState in
            switch newState {
            case .sendingMessage:
                // Start a timer to show ThinkingView after 1.5 seconds
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    await MainActor.run {
                        // Only show if we're still in sendingMessage state
                        if case .sendingMessage = self.state {
                            withAnimation(.easeInOut) {
                                self.showThinkingView = true
                            }
                        }
                    }
                }
            default:
                // Hide ThinkingView when leaving sendingMessage state
                withAnimation(.easeInOut) {
                    showThinkingView = false
                }
            }
        }
    }

    @ViewBuilder
    func sendingMessageView(proxy: ScrollViewProxy) -> some View {
        if case .sendingMessage(let message, _) = self.state {
            MessageView(message: BotMessage(
                id: 0,
                text: message,
                date: Date(),
                userWantsToTalkToHuman: false,
                isWrittenByUser: true
            ))
            .onAppear {
                withAnimation {
                    proxy.scrollTo(0, anchor: .bottom)
                }
            }
            .onDisappear {
                scrollToBottom(using: proxy, animated: true)
            }

            if showThinkingView {
                HStack {
                    Spacer()
                    ThinkingView()
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
                .onAppear {
                    scrollToBottom(using: proxy, animated: true)
                }
                .onDisappear {
                    scrollToBottom(using: proxy, animated: true)
                }
            }
        }
    }

    @ViewBuilder
    var loadingMessagesError: some View {
        if case .loadingMessagesError(let error) = self.state {
            ErrorView(
                title: "Unable to load messages",
                message: error.localizedDescription
            )
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }

    @ViewBuilder
    var sendingMessageError: some View {
        if case .sendingMessageError(let error) = self.state {
            ErrorView(
                title: "Unable to send message",
                message: error.localizedDescription
            )
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }

    @ViewBuilder
    var switchToHumanSupport: some View {
        if let conversation, conversation.userWantsHumanSupport {
            Section {
                // Deliberately left empty
            } footer: {
                if #available(iOS 26.0, *) {
                    openSupportTicketButton
                    .buttonStyle(.glassProminent)
                } else {
                    openSupportTicketButton
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    @ViewBuilder
    var openSupportTicketButton: some View {
        NavigationLink {
            SupportForm(
                supportIdentity: self.currentUser
            ).environmentObject(self.dataProvider) // Required until SwiftUI owns the nav controller
        } label: {
            Text("Open a Support Ticket")
                .font(.headline)
                .padding(.vertical)
                .frame(maxWidth: .infinity)
        }
    }

    private func scrollToBottom(using proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation {
                proxy.scrollTo(bottom, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(bottom, anchor: .bottom)
        }
    }

    private func loadExistingConversation() async {
        self.state = .loadingMessages

        do {
            guard let conversationId = self.conversation?.id else {
                await MainActor.run {
                    self.state = .startingNewConversation
                }
                return
            }

            guard let conversation = try await self.dataProvider.loadConversation(id: conversationId) else {
                await MainActor.run {
                    self.state = .conversationNotFound
                }
                return
            }

            await MainActor.run {
                self.conversation = conversation
                self.state = .idle
            }

        } catch {
            await MainActor.run {
                self.state = .loadingMessagesError(error)
            }
        }
    }

    private func sendMessage(_ message: String) {
        let sendTask = Task {
            do {
                let conversation = try await self.dataProvider.sendMessage(
                    message: message,
                    in: self.conversation
                )

                await MainActor.run {
                    self.conversation = conversation
                    self.state = .idle
                }
            } catch {
                debugPrint("🚩 Error: \(error.localizedDescription)")
                self.state = .sendingMessageError(error)
            }
        }

        self.state = .sendingMessage(message, sendTask)
    }
}

#Preview("Default chat") {
    NavigationView {
        ConversationView(
            conversation: SupportDataProvider.botConversation,
            currentUser: SupportDataProvider.supportUser
        ).environmentObject(SupportDataProvider.testing)
    }
}

#Preview("User wants to chat with a human") {
    NavigationView {
        ConversationView(
            conversation: SupportDataProvider.conversationReferredToHuman,
            currentUser: SupportDataProvider.supportUser
        ).environmentObject(SupportDataProvider.testing)
    }
}
