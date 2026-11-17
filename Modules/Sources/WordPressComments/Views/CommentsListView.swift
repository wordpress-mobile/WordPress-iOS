import SwiftUI

struct CommentsListView: View {
    @State private var selectedComment: CommentListItem?

    @ObservedObject var viewModel: CommentsListViewModel
    @ObservedObject var titleResolver: PostTitleResolver
    let context: CommentDetailContext
    /// Starts a review session over the loaded pending comments.
    let review: ([CommentListItem]) -> Void

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                CommentRowButton(
                    item: item,
                    titleState: titleResolver.titleState(for: item.postID),
                    showsPendingStatus: viewModel.filter == .all
                ) {
                    selectedComment = item
                }
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
        .background(detailLink)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.canReview {
                    Button(Strings.Review.review) { review(viewModel.reviewBatch) }
                        .accessibilityLabel(Strings.Review.reviewAccessibility)
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .overlay {
            if viewModel.state == .loading, viewModel.items.isEmpty {
                ProgressView()
            } else if case .failed = viewModel.state {
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

    // Moderation can remove the selected row while its detail is still open.
    private var detailLink: some View {
        NavigationLink(
            isActive: Binding(
                get: { selectedComment != nil },
                set: { isActive in
                    if !isActive { selectedComment = nil }
                }
            )
        ) {
            if let selectedComment {
                CommentDetailView(commentID: selectedComment.id, seed: selectedComment, context: context)
                    .id(selectedComment.id)
            }
        } label: {
            EmptyView()
        }
        .hidden()
    }
}
