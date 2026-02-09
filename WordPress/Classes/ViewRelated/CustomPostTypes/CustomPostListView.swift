import Foundation
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressUI

/// Displays a paginated list of custom posts.
///
/// Used to show posts filtered by status or search results.
struct CustomPostListView<Header: View>: View {
    @ObservedObject var viewModel: CustomPostListViewModel
    let details: PostTypeDetailsWithEditContext
    let onSelectPost: (AnyPostWithEditContext) -> Void
    @ViewBuilder let header: () -> Header

    init(
        viewModel: CustomPostListViewModel,
        details: PostTypeDetailsWithEditContext,
        onSelectPost: @escaping (AnyPostWithEditContext) -> Void
    ) where Header == EmptyView {
        self.viewModel = viewModel
        self.details = details
        self.onSelectPost = onSelectPost
        self.header = { EmptyView() }
    }

    init(
        viewModel: CustomPostListViewModel,
        details: PostTypeDetailsWithEditContext,
        onSelectPost: @escaping (AnyPostWithEditContext) -> Void,
        @ViewBuilder header: @escaping () -> Header
    ) {
        self.viewModel = viewModel
        self.details = details
        self.onSelectPost = onSelectPost
        self.header = header
    }

    var body: some View {
        PaginatedList(
            items: viewModel.items,
            onLoadNextPage: { try await viewModel.loadNextPage() },
            onSelectPost: onSelectPost,
            header: header
        )
        .overlay {
            if viewModel.shouldDisplayEmptyView {
                let emptyText = details.labels.notFound.isEmpty
                    ? String.localizedStringWithFormat(Strings.emptyStateMessage, details.name)
                    : details.labels.notFound
                EmptyStateView(emptyText, systemImage: "doc.text")
            } else if viewModel.shouldDisplayInitialLoading {
                ProgressView()
            } else if let error = viewModel.errorToDisplay() {
                EmptyStateView.failure(error: error)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task(id: viewModel.filter) {
            await viewModel.refresh()
        }
        .task(id: viewModel.filter) {
            await viewModel.handleDataChanges()
        }
    }
}

private struct PaginatedList<Header: View>: View {
    let items: [CustomPostCollectionItem]
    let onLoadNextPage: () async throws -> Void
    let onSelectPost: (AnyPostWithEditContext) -> Void
    @ViewBuilder let header: () -> Header

    @State var isLoadingMore = false
    @State var loadMoreError: Error?

    init(
        items: [CustomPostCollectionItem],
        onLoadNextPage: @escaping () async throws -> Void,
        onSelectPost: @escaping (AnyPostWithEditContext) -> Void
    ) where Header == EmptyView {
        self.items = items
        self.onLoadNextPage = onLoadNextPage
        self.onSelectPost = onSelectPost
        self.header = { EmptyView() }
    }

    init(
        items: [CustomPostCollectionItem],
        onLoadNextPage: @escaping () async throws -> Void,
        onSelectPost: @escaping (AnyPostWithEditContext) -> Void,
        @ViewBuilder header: @escaping () -> Header
    ) {
        self.items = items
        self.onLoadNextPage = onLoadNextPage
        self.onSelectPost = onSelectPost
        self.header = header
    }

    var body: some View {
        List {
            Section {
                header()
                    .listRowInsets(.zero)
            }
            .listSectionSpacing(0)
            .listSectionSeparator(.hidden)

            ForEach(items) { item in
                ForEachContent(item: item, onSelectPost: onSelectPost)
                    .task {
                        await onRowAppear(item: item)
                    }
            }

            Section {
                makeFooterView()
            }
            .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    private func onRowAppear(item: CustomPostCollectionItem) async {
        if !isLoadingMore, items.suffix(5).contains(where: { $0.id == item.id }) {
            await loadNextPage()
        }
    }

    private func loadNextPage() async {
        guard !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        self.loadMoreError = nil

        do {
            try await onLoadNextPage()
        } catch {
            DDLogError("Failed to load next page: \(error)")
            self.loadMoreError = error
        }
    }

    @ViewBuilder
    private func makeFooterView() -> some View {
        if isLoadingMore {
            ProgressView()
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                .id(UUID()) // A hack to show the ProgressView after cell reusing.
        } else if let loadMoreError {
            VStack {
                Text(verbatim: loadMoreError.localizedDescription)
                Button {
                    Task { await loadNextPage() }
                } label: {
                    Text(verbatim: SharedStrings.Button.retry)
                }
                .buttonStyle(.borderedProminent)
            }.frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct ForEachContent: View {
    let item: CustomPostCollectionItem
    let onSelectPost: (AnyPostWithEditContext) -> Void

    var body: some View {
        switch item {
        case .error(_, let message):
            ErrorRow(message: message)

        case .errorWithData(_, let message, let post):
            VStack(spacing: 4) {
                PostContent(post: post)
                ErrorRow(message: message)
            }

        case .fetching, .missing, .refreshing:
            PostContent(
                post: CustomPostCollectionDisplayPost(
                    date: Date(),
                    title: "Lorem ipsum dolor sit amet",
                    excerpt: "Lorem ipsum dolor sit amet consectetur adipiscing elit"
                )
            )
            .redacted(reason: .placeholder)

        case .ready(_, let displayPost, let post):
            Button {
                onSelectPost(post)
            } label: {
                PostContent(post: displayPost)
            }
            .buttonStyle(.plain)

        case .stale(_, let post):
            PostContent(post: post)
        }
    }
}

private struct PostContent: View {
    let post: CustomPostCollectionDisplayPost

    init(post: CustomPostCollectionDisplayPost) {
        self.post = post
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post.date, format: .dateTime.day().month().year())
                .font(.caption)
                .foregroundStyle(.secondary)

            if let title = post.title {
                Text(verbatim: title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            if let excerpt = post.excerpt {
                Text(verbatim: excerpt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct ErrorRow: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")

            Text(message)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.red)
        .padding(.vertical, 4)
    }
}

private enum Strings {
    static let emptyStateMessage = NSLocalizedString(
        "customPostList.emptyState.message",
        value: "No %1$@",
        comment: "Empty state message when no custom posts exist. %1$@ is the post type name (e.g., 'Podcasts', 'Products')."
    )
}

// MARK: - Previews

#Preview("Fetching Placeholders") {
    PaginatedList(
        items: [
            .fetching(id: 1),
            .fetching(id: 2),
            .fetching(id: 3)
        ],
        onLoadNextPage: {},
        onSelectPost: { _ in }
    )
}

#Preview("Error State") {
    PaginatedList(
        items: [
            .error(id: 1, message: "Failed to load post"),
            .error(id: 2, message: "Network connection lost")
        ],
        onLoadNextPage: {},
        onSelectPost: { _ in }
    )
}

#Preview("Stale Content") {
    PaginatedList(
        items: [
            .stale(
                id: 1,
                post: CustomPostCollectionDisplayPost(
                    date: .now,
                    title: "First Draft Post",
                    excerpt: "This is a preview of the first post that might be outdated."
                )
            ),
            .stale(
                id: 2,
                post: CustomPostCollectionDisplayPost(
                    date: .now.addingTimeInterval(-86400),
                    title: "Second Post",
                    excerpt: "Another post with stale data showing in the list."
                )
            ),
            .stale(
                id: 3,
                post: CustomPostCollectionDisplayPost(
                    date: .now.addingTimeInterval(-86400 * 7),
                    title: nil,
                    excerpt: "Post without a title"
                )
            )
        ],
        onLoadNextPage: {},
        onSelectPost: { _ in }
    )
}

#Preview("Mixed States") {
    PaginatedList(
        items: [
            .stale(
                id: 1,
                post: CustomPostCollectionDisplayPost(
                    date: .now,
                    title: "Published Post",
                    excerpt: "This post has stale data and is being refreshed."
                )
            ),
            .refreshing(
                id: 2,
                post: CustomPostCollectionDisplayPost(
                    date: .now.addingTimeInterval(-86400),
                    title: "Refreshing Post",
                    excerpt: "Currently being refreshed in the background."
                )
            ),
            .fetching(id: 3),
            .error(id: 4, message: "Failed to sync"),
            .errorWithData(
                id: 5,
                message: "Sync failed, showing cached data",
                post: CustomPostCollectionDisplayPost(
                    date: .now.addingTimeInterval(-86400 * 3),
                    title: "Cached Post",
                    excerpt: "This post failed to sync but we have old data."
                )
            ),
        ],
        onLoadNextPage: {},
        onSelectPost: { _ in }
    )
}

#Preview("Load Next Page Error") {
    PaginatedList(
        items: [
            .stale(
                id: 1,
                post: CustomPostCollectionDisplayPost(
                    date: .now,
                    title: "Published Post",
                    excerpt: "This post has stale data and is being refreshed."
                )
            ),
        ],
        onLoadNextPage: { throw CollectionError.DatabaseError(errMessage: "SQL error") },
        onSelectPost: { _ in },
    )
}
