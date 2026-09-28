import SwiftUI

/// The "Get help" screen, listing the user's AI Assistant conversations and support tickets.
public struct UnifiedSupportListView: View {

    @StateObject private var viewModel: UnifiedSupportListViewModel

    private let context: UnifiedSupportContext
    private let currentUser: SupportUser

    public init(context: UnifiedSupportContext, currentUser: SupportUser) {
        self.context = context
        self.currentUser = currentUser
        _viewModel = StateObject(
            wrappedValue: UnifiedSupportListViewModel(dataProvider: context.dataProvider, tracker: context.tracker)
        )
    }

    public var body: some View {
        content
            .navigationTitle(UnifiedSupportLocalization.conversationsTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    newConversationLink {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel(UnifiedSupportLocalization.newConversation)
                }
            }
            .overlay {
                OverlayProgressView(shouldBeVisible: viewModel.isUpdatingCachedConversations)
            }
            .unifiedSupportNotice($viewModel.notice)
            .environmentObject(context)
            .onAppear {
                viewModel.onAppear()
                viewModel.loadIfNeeded()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            FullScreenProgressView(UnifiedSupportLocalization.loadingConversations)
        case .loaded(let conversations) where conversations.isEmpty:
            emptyView
        case .loaded(let conversations):
            conversationList(conversations)
        case .offline:
            unavailableView(
                title: UnifiedSupportLocalization.offlineTitle,
                message: UnifiedSupportLocalization.offlineMessage,
                systemImage: "wifi.slash"
            )
        case .failed(let error):
            unavailableView(
                title: UnifiedSupportLocalization.genericErrorTitle,
                message: error.unifiedSupportMessage,
                systemImage: "exclamationmark.triangle"
            )
        }
    }

    private func conversationList(_ conversations: [UnifiedSupportConversationSummary]) -> some View {
        List(conversations) { conversation in
            NavigationLink {
                conversationView(for: .existing(conversation))
            } label: {
                UnifiedSupportConversationRow(conversation: conversation)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label(UnifiedSupportLocalization.emptyConversationsTitle, systemImage: "bubble.left.and.text.bubble.right")
        } description: {
            Text(UnifiedSupportLocalization.emptyConversationsMessage)
        } actions: {
            newConversationLink {
                Text(UnifiedSupportLocalization.startConversation)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func newConversationLink<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        NavigationLink {
            conversationView(for: .newBotConversation)
        } label: {
            label()
        }
    }

    private func conversationView(for source: UnifiedSupportConversationViewModel.Source) -> some View {
        UnifiedSupportConversationView(
            viewModel: UnifiedSupportConversationViewModel(
                source: source,
                dataProvider: context.dataProvider,
                tracker: context.tracker,
                currentUser: currentUser,
                onConversationUpdated: { [weak viewModel] conversation in
                    viewModel?.upsert(conversation)
                }
            )
        )
        // Required until SwiftUI owns the nav controller
        .environmentObject(context)
    }

    private func unavailableView(title: String, message: String, systemImage: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            Button(UnifiedSupportLocalization.tryAgain) {
                Task {
                    await viewModel.retry()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview("Conversations") {
    NavigationStack {
        UnifiedSupportListView(context: .testing, currentUser: SupportDataProvider.supportUser)
    }
}

#Preview("Empty") {
    NavigationStack {
        UnifiedSupportListView(
            context: .testing(dataProvider: InternalUnifiedSupportDataProvider(conversations: [])),
            currentUser: SupportDataProvider.supportUser
        )
    }
}

#Preview("Offline") {
    NavigationStack {
        UnifiedSupportListView(
            context: .testing(
                dataProvider: InternalUnifiedSupportDataProvider(loadingError: UnifiedSupportError.offline)
            ),
            currentUser: SupportDataProvider.supportUser
        )
    }
}
