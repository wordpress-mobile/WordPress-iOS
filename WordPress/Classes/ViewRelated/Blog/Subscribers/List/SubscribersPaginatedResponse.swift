import Foundation
import SwiftUI
import WordPressShared
import WordPressKit

/// Loads paginated subscribers for the given parameters.
@MainActor
final class SubscribersPaginatedResponse: ObservableObject {
    @Published private(set) var total = 0
    @Published private(set) var items: [SubscriberRowViewModel] = []
    @Published private(set) var hasMore = true
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    let parameters: SubscribersServiceRemote.GetSubscribersParameters
    var isEmpty: Bool { items.isEmpty }

    private var currentPage = 1
    private let blog: SubscribersBlog
    private let search: String?

    init(blog: SubscribersBlog, parameters: SubscribersServiceRemote.GetSubscribersParameters = .init(), search: String? = nil) async throws {
        self.blog = blog
        self.parameters = parameters
        self.search = search

        let response = try await next()
        didLoad(response)
    }

    func loadMore() {
        guard hasMore && !isLoading else {
            return
        }
        error = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let response = try await next()
                didLoad(response)
            } catch {
                self.error = error
            }
        }
    }

    private func didLoad(_ response: SubscribersServiceRemote.GetSubscribersResponse) {
        total = response.total
        currentPage += 1
        hasMore = response.page < response.pages

        let existingIDs = Set(items.map(\.subscriberID))
        let newItems = response.subscribers.filter {
            !existingIDs.contains($0.subscriberID)
        }
        items += newItems.map {
            let viewModel = SubscriberRowViewModel(blog: blog, subscriber: $0)
            viewModel.response = self
            return viewModel
        }
    }

    func onRowAppear(_ row: SubscriberRowViewModel) {
        guard items.suffix(10).contains(where: { $0.id == row.id }) else {
            return
        }
        if error == nil {
            loadMore()
        }
    }

    func deleteSubscriber(withID subscriberID: Int) {
        items.removeAll { $0.subscriberID == subscriberID }
    }

    private func next() async throws -> SubscribersServiceRemote.GetSubscribersResponse {
        guard let api = blog.getRestAPI() else {
            throw URLError(.unknown)
        }
        let service = SubscribersServiceRemote(wordPressComRestApi: api)
        return try await service.getSubscribers(
            siteID: blog.dotComSiteID,
            page: currentPage,
            perPage: 50,
            parameters: parameters,
            search: search
        )
    }
}
