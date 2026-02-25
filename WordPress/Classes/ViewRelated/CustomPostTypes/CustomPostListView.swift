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
    let client: WordPressClient
    let onSelectPost: (AnyPostWithEditContext) -> Void
    let mediaHost: MediaHost?
    @ViewBuilder let header: () -> Header

    init(
        viewModel: CustomPostListViewModel,
        details: PostTypeDetailsWithEditContext,
        client: WordPressClient,
        onSelectPost: @escaping (AnyPostWithEditContext) -> Void,
        mediaHost: MediaHost? = nil
    ) where Header == EmptyView {
        self.viewModel = viewModel
        self.details = details
        self.client = client
        self.onSelectPost = onSelectPost
        self.mediaHost = mediaHost
        self.header = { EmptyView() }
    }

    init(
        viewModel: CustomPostListViewModel,
        details: PostTypeDetailsWithEditContext,
        client: WordPressClient,
        onSelectPost: @escaping (AnyPostWithEditContext) -> Void,
        mediaHost: MediaHost? = nil,
        @ViewBuilder header: @escaping () -> Header
    ) {
        self.viewModel = viewModel
        self.details = details
        self.client = client
        self.onSelectPost = onSelectPost
        self.mediaHost = mediaHost
        self.header = header
    }

    var body: some View {
        PaginatedList(
            items: viewModel.items,
            onLoadNextPage: { try await viewModel.loadNextPage() },
            client: client,
            onSelectPost: onSelectPost,
            mediaHost: mediaHost,
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
            await viewModel.loadCachedItems()
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
    let client: WordPressClient?
    let onSelectPost: (AnyPostWithEditContext) -> Void
    let mediaHost: MediaHost?
    @ViewBuilder let header: () -> Header

    @State var isLoadingMore = false
    @State var loadMoreError: Error?

    init(
        items: [CustomPostCollectionItem],
        onLoadNextPage: @escaping () async throws -> Void,
        client: WordPressClient? = nil,
        onSelectPost: @escaping (AnyPostWithEditContext) -> Void,
        mediaHost: MediaHost? = nil
    ) where Header == EmptyView {
        self.items = items
        self.onLoadNextPage = onLoadNextPage
        self.client = client
        self.onSelectPost = onSelectPost
        self.mediaHost = mediaHost
        self.header = { EmptyView() }
    }

    init(
        items: [CustomPostCollectionItem],
        onLoadNextPage: @escaping () async throws -> Void,
        client: WordPressClient? = nil,
        onSelectPost: @escaping (AnyPostWithEditContext) -> Void,
        mediaHost: MediaHost? = nil,
        @ViewBuilder header: @escaping () -> Header
    ) {
        self.items = items
        self.onLoadNextPage = onLoadNextPage
        self.client = client
        self.onSelectPost = onSelectPost
        self.mediaHost = mediaHost
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
                ForEachContent(item: item, client: client, onSelectPost: onSelectPost, mediaHost: mediaHost)
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
    let client: WordPressClient?
    let onSelectPost: (AnyPostWithEditContext) -> Void
    let mediaHost: MediaHost?

    var body: some View {
        switch item {
        case .error(_, let message):
            ErrorRow(message: message)

        case .errorWithData(_, let message, let post):
            VStack(spacing: 4) {
                PostContent(post: post, client: client, mediaHost: mediaHost)
                ErrorRow(message: message)
            }

        case .fetching, .missing, .refreshing:
            PostContent(
                post: CustomPostCollectionDisplayPost(
                    date: Date(),
                    title: "Lorem ipsum dolor sit amet",
                    content: "Lorem ipsum dolor sit amet consectetur adipiscing elit"
                ),
                client: client,
                mediaHost: mediaHost
            )
            .redacted(reason: .placeholder)

        case .ready(_, let displayPost, let post):
            Button {
                onSelectPost(post)
            } label: {
                PostContent(post: displayPost, client: client, mediaHost: mediaHost)
            }
            .buttonStyle(.plain)

        case .stale(_, let post):
            PostContent(post: post, client: client, mediaHost: mediaHost)
        }
    }
}

private struct PostContent: View {
    let post: CustomPostCollectionDisplayPost
    let client: WordPressClient?
    let mediaHost: MediaHost?
    var showsEllipsisMenu: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            content
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var header: some View {
        HStack {
            Text(verbatim: post.headerBadges)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()

            if showsEllipsisMenu {
                ellipsisMenu
            }
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: post.titleForDisplay)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let content = post.content, !content.isEmpty {
                    Text(verbatim: content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            if let featuredMedia = post.featuredMedia, let client {
                FeaturedMediaImage(mediaId: featuredMedia, client: client, mediaHost: mediaHost)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if let badges = post.statusBadges {
            Text(verbatim: badges)
                .font(.footnote)
                .foregroundStyle(post.statusColor)
        }
    }

    private var ellipsisMenu: some View {
        // TODO: To be implemented
        Menu {
            Button(action: { Loggers.app.info("View tapped") }) {
                Label(SharedStrings.Button.view, systemImage: "safari")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
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
    static let trashButton = NSLocalizedString(
        "customPostList.action.trash",
        value: "Trash",
        comment: "Button title to move a post to trash"
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
                    content: "This is a preview of the first post that might be outdated."
                )
            ),
            .stale(
                id: 2,
                post: CustomPostCollectionDisplayPost(
                    date: .now.addingTimeInterval(-86400),
                    title: "Second Post",
                    content: "Another post with stale data showing in the list."
                )
            ),
            .stale(
                id: 3,
                post: CustomPostCollectionDisplayPost(
                    date: .now.addingTimeInterval(-86400 * 7),
                    title: nil,
                    content: "Post without a title"
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
                    content: "This post has stale data and is being refreshed."
                )
            ),
            .refreshing(
                id: 2,
                post: CustomPostCollectionDisplayPost(
                    date: .now.addingTimeInterval(-86400),
                    title: "Refreshing Post",
                    content: "Currently being refreshed in the background."
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
                    content: "This post failed to sync but we have old data."
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
                    content: "This post has stale data and is being refreshed."
                )
            ),
        ],
        onLoadNextPage: { throw CollectionError.DatabaseError(errMessage: "SQL error") },
        onSelectPost: { _ in },
    )
}

#Preview("Status Variants") {
    List {
        PostContent(
            post: CustomPostCollectionDisplayPost(
                date: .now,
                title: "My Draft Post",
                content: "This post is still being worked on.",
                status: .draft
            ),
            client: nil,
            mediaHost: nil
        )
        PostContent(
            post: CustomPostCollectionDisplayPost(
                date: .now.addingTimeInterval(-86400),
                title: "Scheduled for Tomorrow",
                content: "This post will be published automatically.",
                status: .future
            ),
            client: nil,
            mediaHost: nil
        )
        PostContent(
            post: CustomPostCollectionDisplayPost(
                date: .now.addingTimeInterval(-86400 * 7),
                title: "Trashed Post",
                content: "This post was moved to trash.",
                status: .trash
            ),
            client: nil,
            mediaHost: nil
        )
    }
    .listStyle(.plain)
}

#Preview("Flags: No Menu") {
    List {
        PostContent(
            post: CustomPostCollectionDisplayPost(
                date: .now,
                title: "Minimal Row",
                content: "No ellipsis menu."
            ),
            client: nil,
            mediaHost: nil,
            showsEllipsisMenu: false
        )
    }
    .listStyle(.plain)
}
