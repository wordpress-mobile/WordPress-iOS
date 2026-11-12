import SwiftUI

struct CommentsSearchView: View {
    @ObservedObject var viewModel: CommentsSearchViewModel
    @ObservedObject var titleResolver: PostTitleResolver
    let openComment: (CommentListItem) -> Void

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                CommentRowButton(
                    item: item,
                    titleState: titleResolver.titleState(for: item.postID),
                    showsPendingStatus: true
                ) {
                    openComment(item)
                }
                // The list draws a separator above the first result, under the
                // search field. Only the first row hides it, because hiding every
                // row's top edge also removed the separators between rows.
                .listRowSeparator(item.id == viewModel.items.first?.id ? .hidden : .automatic, edges: .top)
            }
            if viewModel.state == .refreshFailed || viewModel.loadMoreFailed {
                VStack {
                    Text(Strings.errorTitle)
                    Button(Strings.errorRetry) { Task { await viewModel.retry() } }
                }
                .frame(maxWidth: .infinity)
            } else if viewModel.canLoadMore || viewModel.isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .task(id: viewModel.nextPage) { await viewModel.loadMore() }
            }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.refresh() }
        .overlay { overlay }
    }

    @ViewBuilder
    private var overlay: some View {
        switch viewModel.state {
        case .prompt:
            ContentUnavailableView(Strings.Search.prompt, systemImage: "magnifyingglass")
        case .loading:
            ProgressView()
        case .failed:
            ContentUnavailableView {
                Label(Strings.errorTitle, systemImage: "exclamationmark.triangle")
            } actions: {
                Button(Strings.errorRetry) { Task { await viewModel.retry() } }
                    .buttonStyle(.borderedProminent)
            }
        case .loaded:
            if viewModel.items.isEmpty {
                ContentUnavailableView(Strings.Search.noResults, systemImage: "magnifyingglass")
            }
        case .refreshing, .refreshFailed:
            EmptyView()
        }
    }
}
