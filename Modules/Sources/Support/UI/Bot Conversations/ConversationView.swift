import SwiftUI

public struct ConversationView: View {

    enum ViewState: Equatable {
        case start(conversation: BotConversation?)
        case loadingMessages(conversation: BotConversation?, Task<Void, Never>)
        case loadingMessagesError(conversation: BotConversation?, String)
        case partiallyLoaded(conversation: BotConversation, fetchTask: Task<Void, Never>)
        case loaded(conversation: BotConversation, substate: ViewSubstate?)
        case startingNewConversation(substate: ViewSubstate?)

        var conversation: BotConversation? {
            return switch self {
            case .start(let conversation):
                conversation
            case .loadingMessages(let conversation, _):
                conversation
            case .partiallyLoaded(let conversation, _):
                conversation
            case .loaded(conversation: let conversation, _):
                conversation
            case .loadingMessagesError(let conversation, _):
                conversation
            default: nil
            }
        }

        var conversationId: UInt64? {
            self.conversation?.id
        }

        var conversationTitle: String {
            self.conversation?.title ?? "New Support Conversation"
        }

        var messages: [BotMessage] {
            switch self {
            case .partiallyLoaded(let conversation, _): conversation.messages
            case .loaded(conversation: let conversation, _): conversation.messages
            default: []
            }
        }

        var userWantsHumanSupport: Bool {
            switch self {
            case .partiallyLoaded(let conversation, _): conversation.userWantsHumanSupport
            case .loaded(conversation: let conversation, _): conversation.userWantsHumanSupport
            default: false
            }
        }

        var shouldCauseScrollToBottom: Bool {
            switch self {
            case .loaded, .partiallyLoaded: true
            default: false
            }
        }

        private var substate: ViewSubstate? {
            if case .loaded(_, let substate) = self {
                return substate
            }

            if case .startingNewConversation(let substate) = self {
                return substate
            }

            return nil
        }

        var inFlightMessage: String? {
            self.substate?.inflightMessage
        }

        var isSendingMessage: Bool {
            inFlightMessage != nil
        }

        var isThinking: Bool {
            self.substate?.isThinking ?? false
        }

        var isStartingNewConversation: Bool {
            guard case .startingNewConversation = self else {
                return false
            }

            return true
        }

        func transitioningToSendingMessage(message: String, task: Task<Void, Never>) -> Self {
            guard self.substate == nil else {
                preconditionFailure("Cannot send message – operation already in progress")
            }

            if let currentConversation = self.conversation {
                return .loaded(
                    conversation: currentConversation,
                    substate: .sendingMessage(
                        message: message,
                        thinking: false,
                        task
                    )
                )
            } else {
                return .startingNewConversation(
                    substate: .sendingMessage(
                        message: message,
                        thinking: false,
                        task
                    )
                )
            }
        }

        func transitioningToThinking() -> Self {

            guard case .sendingMessage(let message, _, let task) = self.substate else {
                preconditionFailure("Cannot transition to `thinking` because no message is in-flight")
            }

            // If we're not sending a message, don't transition
            guard self.isSendingMessage else {
                return self
            }

            if let currentConversation = self.conversation {
                return .loaded(
                    conversation: currentConversation,
                    substate: .sendingMessage(
                        message: message,
                        thinking: true,
                        task
                    )
                )
            } else {
                return .startingNewConversation(
                    substate: .sendingMessage(
                        message: message,
                        thinking: true,
                        task
                    )
                )
            }
        }

        func transitioningToMessageSent(updatedConversation: BotConversation) -> Self {
            guard self.isSendingMessage, self.substate != nil else {
                preconditionFailure("Cannot transition to message sent – none is in-flight")
            }

            return .loaded(conversation: updatedConversation, substate: nil)
        }

        func transitioningToMessageSendError(_ error: Error) -> Self {
            if let currentConversation = self.conversation {
                guard self.substate != nil else {
                    preconditionFailure("Cannot transition to message send error – none is in-flight")
                }

                return .loaded(
                    conversation: currentConversation,
                    substate: .sendingMessageError(error.localizedDescription)
                )
            } else {
                guard self.substate != nil else {
                    preconditionFailure("Cannot transition to message send error – none is in-flight")
                }

                return .startingNewConversation(
                    substate: .sendingMessageError(error.localizedDescription)
                )
            }
        }

        var isPartiallyLoaded: Bool {
            guard case .partiallyLoaded = self else {
                return false
            }

            return true
        }
    }

    enum ViewSubstate: Equatable {
        case sendingMessage(message: String, thinking: Bool, Task<Void, Never>)
        case sendingMessageError(String)

        var isThinking: Bool {
            if case .sendingMessage(_, let thinking, _) = self {
                return thinking
            }

            return false
        }

        var inflightMessage: String? {
            if case .sendingMessage(let message, _, _) = self {
                return message
            }

            return nil
        }
    }

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    @State
    var currentUser: SupportUser

    @State
    var state: ViewState

    @State
    private var showThinkingView = false

    @Namespace
    var bottom

    public init(conversation: BotConversation?, currentUser: SupportUser) {
        self.state = .start(conversation: conversation)
        self.currentUser = currentUser
    }

    public var body: some View {
        VStack {
            switch self.state {
            case .start, .loadingMessages:
                FullScreenProgressView(Localization.loadingBotConversationMessages)
            case .partiallyLoaded(let conversation, _), .loaded(let conversation, _):
                self.conversationView(messages: conversation.messages)
            case .loadingMessagesError(_, let message):
                FullScreenErrorView(
                    title: Localization.unableToLoadMessages,
                    message: message
                )
            case .startingNewConversation:
                self.conversationView(messages: [])
            }
        }
        .navigationTitle(self.state.conversationTitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .overlay {
            OverlayProgressView(shouldBeVisible: state.isPartiallyLoaded)
        }
        .onAppear {
            if let conversationId = self.state.conversationId {
                self.dataProvider.userDid(.viewSupportBotConversation(conversationId: conversationId))
            } else {
                self.dataProvider.userDid(.startSupportBotConversation)
            }
        }
        .task(self.loadExistingConversation)
        .refreshable(action: self.reloadConversation)
    }

    @ViewBuilder
    func conversationView(messages: [BotMessage]) -> some View {
        ZStack {
            ScrollViewReader { proxy in
                List() {
                    Section {
                        ConversationBotIntro(currentUser: currentUser)
                    }

                    loadingMessagesError

                    Section {
                        ForEach(messages) { message in
                            MessageView(message: message).id(message.id)
                        }

                        sendingMessageView(proxy: proxy)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
                    .listRowBackground(Color.clear)

                    sendingMessageError

                    switchToHumanSupport

                    Text("").padding(.bottom, 4)
                        .listRowInsets(.zero)
                        .listRowBackground(Color.clear)
                        .listRowSpacing(0)
                        .id(self.bottom)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: self.state) { _, newState in
                    if newState.shouldCauseScrollToBottom {
                        scrollToBottom(using: proxy, animated: false)
                    }
                }
                .onAppear {
                    scrollToBottom(using: proxy, animated: false)
                }
            }
            VStack {
                Spacer()
                CompositionView(
                    isDisabled: self.state.isSendingMessage,
                    action: self.sendMessage
                )
            }
        }
    }

    @ViewBuilder
    func sendingMessageView(proxy: ScrollViewProxy) -> some View {
        if let inFlightMessage = state.inFlightMessage {
            MessageView(message: BotMessage(
                id: 0,
                text: inFlightMessage,
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

            if self.state.isThinking {
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
        if case .loadingMessagesError(_, let error) = self.state {
            ErrorView(
                title: "Unable to load messages",
                message: error
            )
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }

    @ViewBuilder
    var sendingMessageError: some View {
        if case .loaded(_, let substate) = state {
            if case .sendingMessageError(let error) = substate {
                ErrorView(
                    title: "Unable to send message",
                    message: error
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
    }

    @ViewBuilder
    var switchToHumanSupport: some View {

        if state.userWantsHumanSupport {
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
            Text(Localization.openSupportTicket)
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
        if let conversation = self.state.conversation {
            self.state = .loadingMessages(conversation: conversation, cacheTask)
        } else {
            self.state = .startingNewConversation(substate: nil)
        }
    }

    private func reloadConversation() async {
        guard case .loaded(let conversation, _) = self.state else {
            return
        }
        self.state = .partiallyLoaded(conversation: conversation, fetchTask: self.fetchTask)
    }

    private var cacheTask: Task<Void, Never> {
        Task {
            guard let conversation = self.state.conversation else {
                return
            }

            do {
                if let cachedResult = try await self.dataProvider.loadConversation(id: conversation.id).cachedResult() {
                    self.state = .partiallyLoaded(conversation: cachedResult, fetchTask: self.fetchTask)
                } else {
                    await self.fetchTask.value
                }
            } catch {
                self.state = .loadingMessagesError(conversation: conversation, error.localizedDescription)
            }
        }
    }

    private var fetchTask: Task<Void, Never> {
        Task {
            guard let conversation = self.state.conversation else {
                return
            }

            do {
                let result = try await self.dataProvider.loadConversation(id: conversation.id).fetchedResult()
                self.state = .loaded(conversation: result, substate: .none)
            } catch {
                self.state = .loadingMessagesError(conversation: conversation, error.localizedDescription)
            }
        }
    }

    @MainActor
    private func sendMessage(_ message: String) {
        self.state = self.state.transitioningToSendingMessage(message: message, task: Task {
            do {
                let thinkingTask = Task.delayedAndRunOnMainActor(for: .seconds(1.5)) {
                    self.state = self.state.transitioningToThinking()
                }

                let updatedConversation: BotConversation

                if let currentConversation = self.state.conversation {
                    updatedConversation = try await self.dataProvider.sendMessage(
                        message: message,
                        in: currentConversation
                    )
                } else {
                    updatedConversation = try await self.dataProvider.sendMessage(
                        message: message
                    )
                }

                // If we somehow got a response before the thinking view shows up, don't show it
                thinkingTask.cancel()

                self.state = self.state.transitioningToMessageSent(
                    updatedConversation: updatedConversation
                )
            } catch {
                self.state = self.state.transitioningToMessageSendError(error)
            }
        })
    }
}

#Preview("Default chat") {
    NavigationStack {
        ConversationView(
            conversation: SupportDataProvider.botConversation,
            currentUser: SupportDataProvider.supportUser
        ).environmentObject(SupportDataProvider.testing)
    }
}

#Preview("User wants to chat with a human") {
    NavigationStack {
        ConversationView(
            conversation: SupportDataProvider.conversationReferredToHuman,
            currentUser: SupportDataProvider.supportUser
        ).environmentObject(SupportDataProvider.testing)
    }
}
