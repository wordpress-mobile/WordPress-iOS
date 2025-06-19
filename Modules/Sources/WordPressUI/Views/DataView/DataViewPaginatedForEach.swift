import SwiftUI

/// A view that displays paginated data using ForEach with automatic loading triggers.
public struct DataViewPaginatedForEach<Response: DataViewPaginatedResponseProtocol, Content: View>: View {
    @ObservedObject private var response: Response
    private let content: (Response.Element) -> Content

    /// Creates a paginated ForEach view.
    ///
    /// - Parameters:
    ///   - response: The paginated response handler that manages the data.
    ///   - content: A view builder that creates the content for each item.
    public init(
        response: Response,
        @ViewBuilder content: @escaping (Response.Element) -> Content
    ) {
        self.response = response
        self.content = content
    }

    public var body: some View {
        ForEach(response.items) { item in
            content(item)
                .onAppear {
                    response.onRowAppeared(item)
                }
        }
        if response.isLoading {
            DataViewPagingFooterView(.loading)
        } else if response.error != nil {
            DataViewPagingFooterView(.failure)
                .onRetry { response.loadMore() }
        }
    }
}
