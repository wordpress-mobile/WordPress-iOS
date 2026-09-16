import SwiftUI

struct CommentsSearchView: View {
    @ObservedObject var viewModel: CommentsSearchViewModel
    @ObservedObject var titleResolver: PostTitleResolver
    let openComment: (Int64, CommentListItem?) -> Void

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                Button {
                    openComment(item.id, item)
                } label: {
                    CommentRowView(
                        item: item,
                        titleState: titleResolver.titleState(for: item.postID),
                        showsPendingStatus: true
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
