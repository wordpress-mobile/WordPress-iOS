import Foundation
import SwiftUI
import WordPressCore
import WordPressAPI
import WordPressAPIInternal

public struct PostsListView: View {
    @StateObject
    private var viewModel: PostsListViewModel

    public init(client: WordPressClient) {
        _viewModel = .init(wrappedValue: PostsListViewModel(client: client))
    }

    public var body: some View {
        List(viewModel.posts) { post in
            Text(post.data.title.rendered)
        }
        .listStyle(.plain)
        .task {
            await viewModel.fetchAll()
        }
        .task {
            await viewModel.performQuery()
        }
    }
}

@MainActor
final class PostsListViewModel: ObservableObject {
    private let client: WordPressClient
    private let dataStore: ApiCacheDataStore<PostCollectionWithEditContext>
    private var service: PostService {
        get {
            self.client.service!.posts()
        }
    }

    @Published private(set) var posts: [FullEntityAnyPostWithEditContext] = []
    @Published private(set) var error: Error?

    init(client: WordPressClient) {
        self.client = client
        let collection = client.service!.posts().createPostCollectionWithEditContext(filter: .init(status: .publish))
        self.dataStore = ApiCacheDataStore(collection: collection)
    }

    func fetchAll() async {
        var page: UInt32 = 1
        while true {
            let result: FetchResult
            do {
                result = try await dataStore.collection.fetchPage(page: page, perPage: 100)
            } catch {
                self.error = error
                break
            }

            if let pages = result.totalPages, page >= pages {
                break
            }
            if result.entityIds.isEmpty {
                break
            }

            page += 1
        }
    }

    func performQuery() async {
        let stream = await dataStore.listStream()
        for await result in stream {
            switch result {
            case let .success(posts):
                self.posts = posts
                self.error = nil
            case let .failure(error):
                self.error = error
            }
        }
    }
}
