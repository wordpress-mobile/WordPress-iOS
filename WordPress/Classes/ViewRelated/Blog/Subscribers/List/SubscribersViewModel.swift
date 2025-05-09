import SwiftUI
import WordPressKit

@MainActor
final class SubscribersViewModel: ObservableObject {
    let blog: SubscribersBlog

    @Published var parameters = SubscribersServiceRemote.GetSubscribersParameters()
    @Published var searchText = ""

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
        if let subscriberID = SubsriberDetailsViewModel.deletedSubsciberID {
            SubsriberDetailsViewModel.deletedSubsciberID = nil
            response?.deleteSubscriber(withID: subscriberID)
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
}
