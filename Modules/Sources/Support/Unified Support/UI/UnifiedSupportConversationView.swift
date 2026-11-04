import SwiftUI

/// A support conversation: a chat with the AI Assistant until the server hands it to the support team, a ticket
/// afterwards.
struct UnifiedSupportConversationView: View {

    @StateObject private var viewModel: UnifiedSupportConversationViewModel
    @EnvironmentObject private var context: UnifiedSupportContext

    /// A conversation is read from the bottom, so that's where it opens and where it stays.
    @State private var scrollPosition = ScrollPosition(edge: .bottom)

    /// Whether a ticket's subject is on screen, which is what keeps the navigation bar from repeating it.
    @State private var isTitleVisible = true

    init(viewModel: @autoclosure @escaping () -> UnifiedSupportConversationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    private var isReplyFailureShown: Binding<Bool> {
        Binding(
            get: { viewModel.replyFailure != nil },
            set: { isShown in
                if !isShown {
                    viewModel.replyFailure = nil
                }
            }
        )
    }

    var body: some View {
        ScrollView {
            content
                .padding(.top, 8)
        }
        .scrollPosition($scrollPosition)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: viewModel.messages.last?.id) {
            scrollToBottom()
        }
        .onChange(of: viewModel.isAssistantTyping) {
            scrollToBottom()
        }
        // A notice takes a bottom inset of its own, which moves the bar below the conversation up. Following
        // it keeps the last message from ending up behind that bar.
        .onChange(of: viewModel.notice?.id) {
            // The inset is only applied once this update is laid out, so following it waits for the next
            // one.
            DispatchQueue.main.async {
                scrollToBottom()
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .overlay {
            if viewModel.isLoading && viewModel.messages.isEmpty {
                FullScreenProgressView(UnifiedSupportLocalization.loadingConversation)
            }
        }
        .unifiedSupportNotice($viewModel.notice)
        // A ticket's subject scrolls away with the conversation, so the bar picks it up once it's gone.
        // Showing it in both places at once would just say the same thing twice.
        .navigationTitle(isTitleVisible ? "" : viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .unifiedSupportAutoRefresh(every: .seconds(60)) {
            await viewModel.refreshSilently()
        }
        .sheet(isPresented: $viewModel.isReplySheetPresented) {
            UnifiedSupportReplySheet(viewModel: viewModel, supportDataProvider: context.supportDataProvider)
        }
        .alert(
            UnifiedSupportLocalization.replyFailedTitle,
            isPresented: isReplyFailureShown,
            presenting: viewModel.replyFailure
        ) { _ in
            Button(UnifiedSupportLocalization.replyFailedTryAgain) {
                viewModel.isReplySheetPresented = true
            }
            Button(UnifiedSupportLocalization.ok, role: .cancel) {}
        } message: { failure in
            Text(failure.message)
        }
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
            UnifiedSupportTicketContentView(viewModel: viewModel, isTitleVisible: $isTitleVisible)
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
            UnifiedSupportReplyButton(action: viewModel.replyAction, isSending: viewModel.isSending) {
                viewModel.isReplySheetPresented = true
            }
            .background(.bar)
        } else {
            UnifiedSupportClosedBanner()
                .background(.bar)
        }
    }

    private func scrollToBottom() {
        withAnimation {
            scrollPosition.scrollTo(edge: .bottom)
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
