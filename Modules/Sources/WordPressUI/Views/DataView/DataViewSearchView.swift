import SwiftUI

/// A generic search view that works with DataViewPaginatedResponse.
/// Provides search functionality with debouncing, loading states, and error handling.
public struct DataViewSearchView<Response: DataViewPaginatedResponseProtocol, Content: View>: View {
    /// The search text to monitor for changes
    let searchText: String

    /// The async function to perform the search
    let search: () async throws -> Response

    /// Content builder for the paginated list
    let content: (Response) -> Content

    /// Delay in milliseconds before executing search (default: 500ms)
    let delay: Duration

    @State private var response: Response?
    @State private var error: Error?

    public init(
        searchText: String,
        delay: Duration = .milliseconds(500),
        search: @escaping () async throws -> Response,
        @ViewBuilder content: @escaping (Response) -> Content
    ) {
        self.searchText = searchText
        self.delay = delay
        self.search = search
        self.content = content
    }

    public var body: some View {
        List {
            if let response {
                content(response)
            } else if error == nil {
                DataViewPagingFooterView(.loading)
            }
        }
        .listStyle(.plain)
        .overlay {
            if let response, response.items.isEmpty {
                EmptyStateView.search()
            } else if let error {
                EmptyStateView.failure(error: error)
            }
        }
        .task(id: searchText) {
            error = nil
            do {
                try await Task.sleep(for: delay)
                let response = try await search()
                guard !Task.isCancelled else { return }
                self.response = response
            } catch {
                guard !Task.isCancelled else { return }
                self.response = nil
                self.error = error
            }
        }
    }
}
