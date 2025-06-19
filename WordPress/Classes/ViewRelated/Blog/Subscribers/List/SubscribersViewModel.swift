import SwiftUI
import WordPressKit
import WordPressUI

typealias SubscribersPaginatedResponse = DataViewPaginatedResponse<SubscriberRowViewModel, Int>

@MainActor
final class SubscribersViewModel: ObservableObject {
    let blog: SubscribersBlog

    @Published var parameters = SubscribersServiceRemote.GetSubscribersParameters()
    @Published var searchText = ""

    @Published var totalCount: Int?

    @Published private(set) var isLoading = false
    @Published private(set) var response: SubscribersPaginatedResponse?
    @Published private(set) var error: Error?

    private var didAppear = false
    private var refreshTask: Task<Void, Never>?

    init(blog: SubscribersBlog) {
        self.blog = blog
    }

    func onAppear() {
        if !didAppear {
            didAppear = true
            onRefreshNeeded()
        }
    }

    func onRefreshNeeded() {
        refreshTask?.cancel()
        refreshTask = Task {
            await refresh()
        }
    }

    func refresh() async {
        error = nil
        isLoading = true
        do {
            let response = try await makeResponse(parameters: parameters)
            guard !Task.isCancelled else { return }
            self.isLoading = false
            self.response = response
            if parameters.filters.isEmpty {
                totalCount = response.total
            }
        } catch {
            guard !Task.isCancelled else { return }
            self.isLoading = false
            self.error = error
            if response != nil {
                Notice(error: error).post()
            }
        }
    }

    func search() async throws -> SubscribersPaginatedResponse {
        try await makeResponse(parameters: parameters, search: searchText)
    }

    func makeFormattedSubscribersCount(for response: SubscribersPaginatedResponse) -> String? {
        guard let count = response.total else {
            return nil
        }
        guard !parameters.filters.isEmpty, let totalCount else {
            return "\(count)"
        }
        return String(format: Strings.nOutOf, count.description, totalCount.description)
    }

    private func makeResponse(
        parameters: SubscribersServiceRemote.GetSubscribersParameters,
        search: String? = nil
    ) async throws -> SubscribersPaginatedResponse {
        return try await SubscribersPaginatedResponse { [blog] page in
            let service = try blog.makeSubscribersService()
            let response = try await service.getSubscribers(
                siteID: blog.dotComSiteID,
                page: page ?? 1,
                perPage: 50,
                parameters: parameters,
                search: search
            )
            let items = response.subscribers.map { subscriber in
                SubscriberRowViewModel(blog: blog, subscriber: subscriber)
            }
            return SubscribersPaginatedResponse.Page(
                items: items,
                total: response.total,
                hasMore: response.page < response.pages,
                nextPage: response.page + 1
            )
        }
    }
}

private enum Strings {
    static let nOutOf = NSLocalizedString("subscribers.menu.nOutOf", value: "%1$@ out of %2$@", comment: "Part of the label in the menu showing how many subscribers are displayed (has to have two arguments!)")
}
