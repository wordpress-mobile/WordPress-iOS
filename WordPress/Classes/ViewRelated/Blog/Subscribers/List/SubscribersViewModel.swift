import SwiftUI
import WordPressKit

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
            let response = try await SubscribersPaginatedResponse(blog: blog, parameters: parameters)
            guard !Task.isCancelled else { return }
            self.isLoading = false
            self.response = response
            if response.parameters.filters.isEmpty {
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
        try await SubscribersPaginatedResponse(blog: blog, parameters: parameters, search: searchText)
    }

    func makeFormattedSubscribersCount(for response: SubscribersPaginatedResponse) -> String {
        if response.parameters.filters.isEmpty {
            return "\(response.total)"
        }
        guard let totalCount else {
            return "\(response.total)"
        }
        return String(format: Strings.nOutOf, response.total.description, totalCount.description)
    }
}

private enum Strings {
    static let nOutOf = NSLocalizedString("subscribers.menu.nOutOf", value: "%1$@ out of %2$@", comment: "Part of the label in the menu showing how many subscribers are displayed (has to have two arguments!)")
}
