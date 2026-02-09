import Foundation
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressShared

@MainActor
final class CustomPostListViewModel: ObservableObject {
    private let client: WordPressClient
    private let endpoint: PostEndpointType
    let filter: CustomPostListFilter

    private var collection: PostMetadataCollectionWithEditContext?

    @Published private(set) var items: [CustomPostCollectionItem] = []
    @Published private(set) var listInfo: ListInfo?
    @Published private var error: Error?

    var shouldDisplayEmptyView: Bool {
        items.isEmpty && listInfo?.isSyncing == false
    }

    var shouldDisplayInitialLoading: Bool {
        items.isEmpty && listInfo?.isSyncing == true
    }

    func errorToDisplay() -> Error? {
        items.isEmpty ? error : nil
    }

    init(
        client: WordPressClient,
        service: WpSelfHostedService,
        endpoint: PostEndpointType,
        filter: CustomPostListFilter
    ) {
        self.client = client
        self.endpoint = endpoint
        self.filter = filter

        collection = service
            .posts()
            .createPostMetadataCollectionWithEditContext(
                endpointType: endpoint,
                filter: filter.asPostListFilter(),
                perPage: 20
            )
    }

    func refresh() async {
        do {
            _ = try await collection?.refresh()
        } catch {
            DDLogError("Failed to refresh posts: \(error)")
            self.show(error: error)
        }
    }

    func loadNextPage() async throws {
        if let listInfo, listInfo.isSyncing || !listInfo.hasMorePages {
            return
        }

        if listInfo?.currentPage == nil {
            _ = try await collection?.refresh()
        } else {
            _ = try await collection?.loadNextPage()
        }
    }

    func handleDataChanges() async {
        let updates = await client.cache.databaseUpdatesPublisher()
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .values
        for await hook in updates {
            guard let collection, collection.isRelevantUpdate(hook: hook) else { continue }

            DDLogInfo("WpApiCache update: \(hook.action) to \(hook.table) at row \(hook.rowId)")

            let listInfo = collection.listInfo()

            DDLogInfo("List info: \(String(describing: listInfo))")

            do {
                let items = try await collection.loadItems().map(CustomPostCollectionItem.init)
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

    private func show(error: Error) {
        self.error = error

        if !items.isEmpty {
            // Show an error notice, on top of the list content.
            Notice(error: error).post()
        }
    }
}

struct CustomPostCollectionDisplayPost: Equatable {
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
            ?? GutenbergExcerptGenerator
                .firstParagraph(
                    from: entity.content.rendered,
                    maxLength: excerptLimit
                )
                .replacingOccurrences(
                    of: "[\n]{2,}",
                    with: "\n",
                    options: .regularExpression
                )
    }

    static let placeholder = CustomPostCollectionDisplayPost(
        date: .now,
        title: "Lorem ipsum dolor sit amet",
        excerpt: "Lorem ipsum dolor sit amet consectetur adipiscing elit"
    )
}

// TODO: Decouple the "display item" from the internall states of the `PostMetadataCollectionItem`
enum CustomPostCollectionItem: Identifiable, Equatable {
    case ready(id: Int64, post: CustomPostCollectionDisplayPost, fullPost: AnyPostWithEditContext)
    case stale(id: Int64, post: CustomPostCollectionDisplayPost)
    case refreshing(id: Int64, post: CustomPostCollectionDisplayPost)
    case fetching(id: Int64)
    case missing(id: Int64)
    case error(id: Int64, message: String)
    case errorWithData(id: Int64, message: String, post: CustomPostCollectionDisplayPost)

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
            self = .ready(id: id, post: CustomPostCollectionDisplayPost(entity.data), fullPost: entity.data)

        case .stale(let entity):
            self = .stale(id: id, post: CustomPostCollectionDisplayPost(entity.data))

        case .fetchingWithData(let entity):
            self = .refreshing(id: id, post: CustomPostCollectionDisplayPost(entity.data))

        case .fetching:
            self = .fetching(id: id)

        case .missing:
            self = .missing(id: id)

        case .failed(let error):
            self = .error(id: id, message: error)

        case .failedWithData(let error, let entity):
            self = .errorWithData(id: id, message: error, post: CustomPostCollectionDisplayPost(entity.data, excerptLimit: 50))
        }
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
