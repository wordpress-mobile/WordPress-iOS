import SwiftUI

/// A view that displays paginated data using ForEach with automatic loading triggers.
public struct DataViewPaginatedForEach<Response: DataViewPaginatedResponseProtocol, Content: View>: View {
    @ObservedObject private var response: Response
    /// Control which items are displayed on screen.
    private let filter: ((Response.Element) -> Bool)?
    private let content: (Response.Element) -> Content

    /// Creates a paginated ForEach view.
    ///
    /// - Parameters:
    ///   - response: The paginated response handler that manages the data.
    ///   - content: A view builder that creates the content for each item.
    public init(
        response: Response,
        filter: ((Response.Element) -> Bool)? = nil,
        @ViewBuilder content: @escaping (Response.Element) -> Content
    ) {
        self.response = response
        self.content = content
        self.filter = filter
    }

    public var body: some View {
        let items = if let filter {
            response.items.filter(filter)
        } else {
            response.items
        }

        ForEach(items) { item in
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
