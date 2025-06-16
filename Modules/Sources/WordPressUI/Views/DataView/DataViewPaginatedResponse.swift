import Foundation
import SwiftUI

/// A generic paginated response handler that manages loading items in pages.
/// This class is designed to be used in the UI in conjunction with `PaginatedForEach`.
@MainActor
public final class DataViewPaginatedResponse<Element: Identifiable>: ObservableObject {
    @Published public private(set) var total = 0
    @Published public private(set) var items: [Element] = []
    @Published public private(set) var hasMore = true
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?

    public var isEmpty: Bool { items.isEmpty }

    private var currentPage = 1
    private let _loadMore: (Int) async throws -> (items: [Element], total: Int, hasMore: Bool)

    /// Creates a new paginated response handler.
    ///
    /// - Parameter loadMore: A closure that loads a specific page of items.
    ///   - Parameter page: The page number to load (1-based).
    ///   - Returns: A tuple containing the items for the page, the total count, and whether more pages exist.
    /// - Throws: Any error from the initial page load.
    public init(loadMore: @escaping (Int) async throws -> (items: [Element], total: Int, hasMore: Bool)) async throws {
        self._loadMore = loadMore

        let response = try await loadMore(currentPage)
        didLoad(response)
    }

    /// Loads the next page of items.
    ///
    /// This method will do nothing if:
    /// - There are no more pages to load
    /// - A page is currently being loaded
    @discardableResult
    public func loadMore() -> Task<Void, Error>? {
        guard hasMore && !isLoading else {
            return nil
        }
        error = nil
        isLoading = true
        return Task {
            defer { isLoading = false }
            do {
                let response = try await _loadMore(currentPage)
                didLoad(response)
            } catch {
                self.error = error
                throw error
            }
        }
    }

    private func didLoad(_ response: (items: [Element], total: Int, hasMore: Bool)) {
        total = response.total
        currentPage += 1
        hasMore = response.hasMore

        let existingIDs = Set(items.map(\.id))
        let newItems = response.items.filter {
            !existingIDs.contains($0.id)
        }
        items += newItems
    }

    /// Triggers loading more items when a row appears.
    ///
    /// Call this method when a row becomes visible. If the row is within the last 10 items
    /// and there's no current error, it will trigger loading the next page.
    ///
    /// - Parameter row: The row that appeared.
    public func onRowAppear(_ row: Element) {
        guard items.suffix(16).contains(where: { $0.id == row.id }) else {
            return
        }
        if error == nil {
            loadMore()
        }
    }

    /// Removes an item with the specified ID from the loaded items.
    ///
    /// - Parameter id: The ID of the item to remove.
    public func deleteItem(withID id: Element.ID) {
        items.removeAll { $0.id == id }
    }
}
