import SwiftUI

struct CommentsListView: View {
    @ObservedObject var viewModel: CommentsListViewModel
    @ObservedObject var titleResolver: PostTitleResolver

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                CommentRowView(item: item, titleState: titleResolver.titleState(for: item.postID))
            }
            if viewModel.canLoadMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        Task { await viewModel.loadMore() }
                    }
            } else if viewModel.loadMoreFailed {
                Button(Strings.errorRetry) {
                    Task { await viewModel.retryLoadMore() }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
        .overlay {
            if viewModel.isLoadingFirstPage && viewModel.items.isEmpty {
                ProgressView()
            } else if viewModel.firstPageFailed {
                ContentUnavailableView {
                    Label(Strings.errorTitle, systemImage: "exclamationmark.triangle")
                } actions: {
                    Button(Strings.errorRetry) {
                        Task { await viewModel.retryFirstPage() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.showsEmptyState {
                ContentUnavailableView(
                    viewModel.filter.emptyStateMessage,
                    systemImage: "bubble.left"
                )
            }
        }
        // Keyed by filter: the tab container swaps the observed view model
        // behind a stable view identity, so an unkeyed task would run only for
        // the first tab and later tabs would never load. onAppear() is a no-op
        // after a tab's first successful load, so re-running it is safe.
        .task(id: viewModel.filter) {
            await viewModel.onAppear()
        }
    }
}
