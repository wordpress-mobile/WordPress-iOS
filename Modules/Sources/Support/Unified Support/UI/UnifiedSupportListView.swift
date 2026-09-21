import SwiftUI

/// The "Get help" screen, listing the user's AI Assistant conversations and support tickets.
public struct UnifiedSupportListView: View {

    @StateObject private var viewModel: UnifiedSupportListViewModel

    public init(context: UnifiedSupportContext) {
        _viewModel = StateObject(
            wrappedValue: UnifiedSupportListViewModel(dataProvider: context.dataProvider, tracker: context.tracker)
        )
    }

    public var body: some View {
        content
            .navigationTitle(UnifiedSupportLocalization.conversationsTitle)
            .navigationBarTitleDisplayMode(.large)
            .overlay {
                OverlayProgressView(shouldBeVisible: viewModel.isUpdatingCachedConversations)
            }
            .unifiedSupportNotice($viewModel.notice)
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
            UnifiedSupportConversationRow(conversation: conversation)
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
        }
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
        UnifiedSupportListView(context: .testing)
    }
}

#Preview("Empty") {
    NavigationStack {
        UnifiedSupportListView(context: .testing(dataProvider: InternalUnifiedSupportDataProvider(conversations: [])))
    }
}

#Preview("Offline") {
    NavigationStack {
        UnifiedSupportListView(
            context: .testing(
                dataProvider: InternalUnifiedSupportDataProvider(loadingError: UnifiedSupportError.offline)
            )
        )
    }
}
