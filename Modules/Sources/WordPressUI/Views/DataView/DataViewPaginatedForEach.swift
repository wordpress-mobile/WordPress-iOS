import SwiftUI

/// A SwiftUI view that displays paginated data using ForEach with automatic loading triggers.
public struct DataViewPaginatedForEach<Element: Identifiable, Content: View>: View {
    @ObservedObject private var response: DataViewPaginatedResponse<Element>
    private let content: (Element) -> Content
    
    /// Creates a paginated ForEach view.
    ///
    /// - Parameters:
    ///   - response: The paginated response handler that manages the data.
    ///   - content: A view builder that creates the content for each item.
    public init(
        response: DataViewPaginatedResponse<Element>,
        @ViewBuilder content: @escaping (Element) -> Content
    ) {
        self.response = response
        self.content = content
    }
    
    public var body: some View {
        ForEach(response.items) { item in
            content(item)
                .onAppear {
                    response.onRowAppear(item)
                }
        }
        
        if response.isLoading {
            DataViewPagingFooterView(.loading)
        } else if response.error != nil {
            DataViewPagingFooterView(.failure)
                .onRetry {
                    response.loadMore()
                }
        }
    }
}