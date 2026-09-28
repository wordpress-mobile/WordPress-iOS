import SwiftUI

/// A support conversation: a chat with the AI Assistant until the server hands it to the support team, a ticket
/// afterwards.
struct UnifiedSupportConversationView: View {

    @StateObject private var viewModel: UnifiedSupportConversationViewModel
    @Namespace private var bottom

    init(viewModel: @autoclosure @escaping () -> UnifiedSupportConversationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                content
                    .padding(.top, 8)

                Color.clear
                    .frame(height: 1)
                    .id(bottom)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) {
                scrollToBottom(using: proxy, animated: true)
            }
            .onChange(of: viewModel.isAssistantTyping) {
                scrollToBottom(using: proxy, animated: true)
            }
            .onAppear {
                scrollToBottom(using: proxy, animated: false)
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .overlay {
            if viewModel.isLoading && viewModel.messages.isEmpty {
                FullScreenProgressView(UnifiedSupportLocalization.loadingConversation)
            }
        }
        .unifiedSupportNotice($viewModel.notice)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
            viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isBot {
            UnifiedSupportChatContentView(viewModel: viewModel)
        } else {
            UnifiedSupportTicketContentView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if viewModel.isBot {
            if viewModel.canAcceptReply {
                UnifiedSupportComposer(
                    text: $viewModel.draft,
                    isSendEnabled: viewModel.canSend,
                    send: viewModel.sendMessage
                )
            }
        } else if viewModel.canAcceptReply {
            UnifiedSupportReplyButton(action: viewModel.replyAction) {
                // TODO: Open the reply form.
            }
            .background(.bar)
        } else {
            UnifiedSupportClosedBanner()
                .background(.bar)
        }
    }

    private func scrollToBottom(using proxy: ScrollViewProxy, animated: Bool) {
        guard animated else {
            proxy.scrollTo(bottom, anchor: .bottom)
            return
        }
        withAnimation {
            proxy.scrollTo(bottom, anchor: .bottom)
        }
    }
}

/// A conversation with the AI Assistant.
struct UnifiedSupportChatContentView: View {

    @ObservedObject var viewModel: UnifiedSupportConversationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ConversationBotIntro(currentUser: viewModel.currentUser)

            ForEach(viewModel.messages) { message in
                UnifiedSupportChatBubble(message: message)
            }

            if viewModel.isAssistantTyping {
                ThinkingView()
                    .accessibilityLabel(UnifiedSupportLocalization.assistantIsTyping)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

#Preview("Chat") {
    NavigationStack {
        UnifiedSupportConversationView(
            viewModel: UnifiedSupportConversationViewModel(
                source: .existing(UnifiedSupportConversation.previewBotConversation.summary),
                dataProvider: InternalUnifiedSupportDataProvider(),
                tracker: InternalUnifiedSupportTracker(),
                currentUser: SupportDataProvider.supportUser
            )
        )
    }
    .environmentObject(UnifiedSupportContext.testing)
}

#Preview("New chat") {
    NavigationStack {
        UnifiedSupportConversationView(
            viewModel: UnifiedSupportConversationViewModel(
                source: .newBotConversation,
                dataProvider: InternalUnifiedSupportDataProvider(),
                tracker: InternalUnifiedSupportTracker(),
                currentUser: SupportDataProvider.supportUser
            )
        )
    }
    .environmentObject(UnifiedSupportContext.testing)
}

#Preview("Ticket") {
    NavigationStack {
        UnifiedSupportConversationView(
            viewModel: UnifiedSupportConversationViewModel(
                source: .existing(UnifiedSupportConversation.previewEscalatedConversation.summary),
                dataProvider: InternalUnifiedSupportDataProvider(),
                tracker: InternalUnifiedSupportTracker(),
                currentUser: SupportDataProvider.supportUser
            )
        )
    }
    .environmentObject(UnifiedSupportContext.testing)
}

#Preview("Closed ticket") {
    NavigationStack {
        UnifiedSupportConversationView(
            viewModel: UnifiedSupportConversationViewModel(
                source: .existing(UnifiedSupportConversation.previewClosedConversation.summary),
                dataProvider: InternalUnifiedSupportDataProvider(),
                tracker: InternalUnifiedSupportTracker(),
                currentUser: SupportDataProvider.supportUser
            )
        )
    }
    .environmentObject(UnifiedSupportContext.testing)
}
