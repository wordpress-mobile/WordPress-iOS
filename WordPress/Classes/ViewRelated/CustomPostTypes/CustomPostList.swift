import Foundation
import SwiftUI
import WordPressCore
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache
import WordPressUI
import WordPressData

private struct DisplayPost: Equatable {
    let date: Date
    let title: String?
    let excerpt: String?

    init(date: Date, title: String?, excerpt: String?) {
        self.date = date
        self.title = title
        self.excerpt = excerpt
    }

    init(_ entity: AnyPostWithEditContext, excerptLimit: Int = 100) {
        self.date = entity.dateGmt
        self.title = entity.title?.raw
        self.excerpt = entity.excerpt?.raw
            ?? String((entity.content.raw ?? entity.content.rendered).prefix(excerptLimit))
    }

    static let placeholder = DisplayPost(
        date: .now,
        title: "Lorem ipsum dolor sit amet",
        excerpt: "Lorem ipsum dolor sit amet consectetur adipiscing elit"
    )
}

private enum ListItem: Identifiable, Equatable {
    case ready(id: Int64, post: DisplayPost, fullPost: AnyPostWithEditContext)
    case stale(id: Int64, post: DisplayPost)
    case refreshing(id: Int64, post: DisplayPost)
    case fetching(id: Int64)
    case missing(id: Int64)
    case error(id: Int64, message: String)
    case errorWithData(id: Int64, message: String, post: DisplayPost)

    var id: Int64 {
        switch self {
        case .ready(let id, _, _),
             .stale(let id, _),
             .refreshing(let id, _),
             .fetching(let id),
             .missing(let id),
             .error(let id, _),
             .errorWithData(let id, _, _):
            return id
        }
    }

    init(item: PostMetadataCollectionItem) {
        let id = item.id

        switch item.state {
        case .fresh(let entity):
            self = .ready(id: id, post: DisplayPost(entity.data), fullPost: entity.data)

        case .stale(let entity):
            self = .stale(id: id, post: DisplayPost(entity.data))

        case .fetchingWithData(let entity):
            self = .refreshing(id: id, post: DisplayPost(entity.data))

        case .fetching:
            self = .fetching(id: id)

        case .missing:
            self = .missing(id: id)

        case .failed(let error):
            self = .error(id: id, message: error)

        case .failedWithData(let error, let entity):
            self = .errorWithData(id: id, message: error, post: DisplayPost(entity.data, excerptLimit: 50))
        }
    }
}

private struct PostList: View {
    let items: [ListItem]
    let onLoadNextPage: () async throws -> Void
    let onSelectPost: (AnyPostWithEditContext) -> Void

    @State var isLoadingMore = false
    @State var loadMoreError: Error?

    var body: some View {
        List {
            ForEach(items) { item in
                listRow(item)
                    .task {
                        if !isLoadingMore, items.suffix(5).contains(where: { $0.id == item.id }) {
                            await loadNextPage()
                        }
                    }
            }

            makeFooterView()
        }
        .listStyle(.plain)
    }

    private func loadNextPage() async {
        guard !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        self.loadMoreError = nil

        do {
            try await onLoadNextPage()
        } catch {
            self.loadMoreError = error
        }
    }

    @ViewBuilder
    private func listRow(_ item: ListItem) -> some View {
        switch item {
        case .error(_, let message):
            ErrorRow(message: message)

        case .errorWithData(_, let message, let post):
            VStack(spacing: 4) {
                PostRowView(post: post)
                ErrorRow(message: message)
            }

        case .fetching, .missing, .refreshing:
            PostRowView(
                post: DisplayPost(
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
                PostRowView(post: displayPost)
            }
            .buttonStyle(.plain)

        case .stale(_, let post):
            PostRowView(post: post)
        }
    }

    @ViewBuilder
    private func makeFooterView() -> some View {
        if isLoadingMore {
            ProgressView()
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                .id(UUID()) // A hack to show the ProgressView after cell reusing.
        } else if loadMoreError != nil {
            Button {
                Task { await loadNextPage() }
            } label: {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                    Text(SharedStrings.Button.retry)
                }
            }
        }
    }
}

private struct PostRowView: View {
    let post: DisplayPost

    init(post: DisplayPost) {
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

struct CustomPostList: View {
    let client: WordPressClient
    let service: WpSelfHostedService
    let endpoint: PostEndpointType
    let details: PostTypeDetailsWithEditContext
    let blog: Blog

    @State var filter: WordPressAPIInternal.PostListFilter = .default
    @State private var listInfo: ListInfo?

    @State var searchText = ""

    @State private var selectedPost: AnyPostWithEditContext?

    private var isFiltered: Bool {
        filter.status != [.custom("any")]
    }

    var body: some View {
        ZStack {
            if searchText.isEmpty {
                CustomPostCollectionView(
                    client: client,
                    service: service,
                    endpoint: endpoint,
                    details: details,
                    listInfo: $listInfo,
                    filter: filter,
                    showInitialLoading: false,
                    onSelectPost: { selectedPost = $0 }
                )
            } else {
                CustomPostSearchResultView(
                    client: client,
                    service: service,
                    endpoint: endpoint,
                    details: details,
                    baseFilter: .default,
                    searchText: $searchText,
                    onSelectPost: { selectedPost = $0 }
                )
            }
        }
        .searchable(text: $searchText)
        .fullScreenCover(item: $selectedPost) { post in
            // TODO: Check if the post supports Gutenberg first?
            CustomPostEditor(client: client, post: post, details: details, blog: blog) {
                Task {
                    _ = try await service.posts().refreshPost(postId: post.id, endpointType: endpoint)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                makeTitleView()
            }
            ToolbarItem(placement: .topBarTrailing) {
                makeFilterMenu()
            }
        }
    }

    @ViewBuilder
    private func makeTitleView() -> some View {
        Text(details.labels.itemsList)
            .overlay(alignment: .leading) {
                if listInfo?.state == .fetchingFirstPage {
                    ProgressView()
                        .offset(x: -24)
                }
            }
    }

    @ViewBuilder
    private func makeFilterMenu() -> some View {
        Menu {
            FilterMenuItem(filter: $filter, status: .custom("any"), title: Strings.filterAll)
            FilterMenuItem(filter: $filter, status: .publish, title: Strings.filterPublished)
            FilterMenuItem(filter: $filter, status: .draft, title: Strings.filterDraft)
            FilterMenuItem(filter: $filter, status: .future, title: Strings.filterScheduled)
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
        }
        .foregroundStyle(isFiltered ? Color.white : .primary)
        .background {
            if isFiltered {
                Circle()
                    .fill(Color.accentColor)
            }
        }
    }
}

struct CustomPostCollectionView: View {
    let client: WordPressClient
    let service: WpSelfHostedService
    let endpoint: PostEndpointType
    let details: PostTypeDetailsWithEditContext
    @Binding var listInfo: ListInfo?
    let filter: WordPressAPIInternal.PostListFilter
    let showInitialLoading: Bool
    let onSelectPost: (AnyPostWithEditContext) -> Void

    @State private var collection: PostMetadataCollectionWithEditContext?
    @State private var items: [ListItem] = []

    var body: some View {
        PostList(
            items: items,
            onLoadNextPage: { try await loadNextPage() },
            onSelectPost: onSelectPost
        )
        .overlay {
            if items.isEmpty, listInfo?.isSyncing == false {
                let emptyText = details.labels.notFound.isEmpty
                    ? "No \(details.name)"
                    : details.labels.notFound
                EmptyStateView(emptyText, systemImage: "doc.text")
            } else if showInitialLoading, items.isEmpty, listInfo?.isSyncing == true {
                ProgressView()
            }
        }
        .refreshable {
            do {
                _ = try await collection?.refresh()
            } catch {
                DDLogError("Pull to refresh failed: \(error)")
            }
        }
        .task(id: filter) {
            // Reset when filter changes.
            if collection == nil || collection?.filter() != filter {
                self.collection = service
                    .posts()
                    .createPostMetadataCollectionWithEditContext(
                        endpointType: endpoint,
                        filter: filter,
                        perPage: 20
                    )
                self.listInfo = nil
                self.items = []
            }

            do {
                _ = try await collection?.refresh()
            } catch {
                DDLogError("Failed to refresh: \(error)")
            }
        }
        .task(id: filter) {
            await handleDataChanges()
        }
    }

    private func loadNextPage() async throws {
        if let listInfo, listInfo.isSyncing || !listInfo.hasMorePages {
            return
        }

        if listInfo?.currentPage == nil {
            _ = try await collection?.refresh()
        } else {
            _ = try await collection?.loadNextPage()
        }
    }

    private func handleDataChanges() async {
        guard let cache = await client.cache else { return }

        let updates = cache.databaseUpdatesPublisher()
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .values
        for await hook in updates {
            guard let collection, collection.isRelevantUpdate(hook: hook) else { continue }

            DDLogInfo("WpApiCache update: \(hook.action) to \(hook.table) at row \(hook.rowId)")

            let listInfo = collection.listInfo()

            NSLog("List info: \(String(describing: listInfo))")

            do {
                let items = try await collection.loadItems().map(ListItem.init)
                withAnimation {
                    if self.listInfo != listInfo {
                        self.listInfo = listInfo
                    }
                    if self.items != items {
                        self.items = items
                    }
                }
            } catch {
                DDLogError("Failed to get collection items: \(error)")
            }
        }
    }
}

struct CustomPostSearchResultView: View {
    let client: WordPressClient
    let service: WpSelfHostedService
    let endpoint: PostEndpointType
    let details: PostTypeDetailsWithEditContext
    let baseFilter: WordPressAPIInternal.PostListFilter
    @Binding var searchText: String
    let onSelectPost: (AnyPostWithEditContext) -> Void

    @State var listInfo: ListInfo? = nil

    var body: some View {
        CustomPostCollectionView(
            client: client,
            service: service,
            endpoint: endpoint,
            details: details,
            listInfo: $listInfo,
            filter: {
                var search = baseFilter
                // TODO: Support author?
                search.searchColumns = [.postTitle, .postContent, .postExcerpt]
                search.search = searchText
                return search
            }(),
            showInitialLoading: true,
            onSelectPost: onSelectPost
        )
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

private extension ListInfo {
    var isSyncing: Bool {
        state == .fetchingFirstPage || state == .fetchingNextPage
    }

    var hasMorePages: Bool {
        guard let currentPage, let totalPages else { return true }
        return currentPage < totalPages
    }
}

private extension WordPressAPIInternal.PostListFilter {
    static var `default`: Self {
        Self(status: [.custom("any")])
    }
}

private enum Strings {
    static let sortByDateCreated = NSLocalizedString(
        "postList.menu.sortByDateCreated",
        value: "Sort by Date Created",
        comment: "Menu item to sort posts by creation date"
    )
    static let sortByDateModified = NSLocalizedString(
        "postList.menu.sortByDateModified",
        value: "Sort by Date Modified",
        comment: "Menu item to sort posts by modification date"
    )
    static let filter = NSLocalizedString(
        "postList.menu.filter",
        value: "Filter",
        comment: "Menu item to access filter options"
    )
    static let filterAll = NSLocalizedString(
        "postList.menu.filter.all",
        value: "All",
        comment: "Filter option to show all posts"
    )
    static let filterPublished = NSLocalizedString(
        "postList.menu.filter.published",
        value: "Published",
        comment: "Filter option to show only published posts"
    )
    static let filterDraft = NSLocalizedString(
        "postList.menu.filter.draft",
        value: "Draft",
        comment: "Filter option to show only draft posts"
    )
    static let filterScheduled = NSLocalizedString(
        "postList.menu.filter.scheduled",
        value: "Scheduled",
        comment: "Filter option to show only scheduled posts"
    )
}

private struct FilterMenuItem: View {
    @Binding var filter: WordPressAPIInternal.PostListFilter
    let status: PostStatus
    let title: String

    var body: some View {
        Button {
            filter.status = [status]
        } label: {
            Label {
                Text(title)
            } icon: {
                if filter.status == [status] {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Fetching Placeholders") {
    PostList(
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
    PostList(
        items: [
            .error(id: 1, message: "Failed to load post"),
            .error(id: 2, message: "Network connection lost")
        ],
        onLoadNextPage: {},
        onSelectPost: { _ in }
    )
}

#Preview("Stale Content") {
    PostList(
        items: [
            .stale(
                id: 1,
                post: DisplayPost(
                    date: .now,
                    title: "First Draft Post",
                    excerpt: "This is a preview of the first post that might be outdated."
                )
            ),
            .stale(
                id: 2,
                post: DisplayPost(
                    date: .now.addingTimeInterval(-86400),
                    title: "Second Post",
                    excerpt: "Another post with stale data showing in the list."
                )
            ),
            .stale(
                id: 3,
                post: DisplayPost(
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
    PostList(
        items: [
            .stale(
                id: 1,
                post: DisplayPost(
                    date: .now,
                    title: "Published Post",
                    excerpt: "This post has stale data and is being refreshed."
                )
            ),
            .refreshing(
                id: 2,
                post: DisplayPost(
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
                post: DisplayPost(
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
