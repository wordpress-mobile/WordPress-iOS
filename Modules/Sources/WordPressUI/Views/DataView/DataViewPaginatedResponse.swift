import Foundation
import SwiftUI

@MainActor
public protocol DataViewPaginatedResponseProtocol: ObservableObject {
    associatedtype Element: Identifiable

    var items: [Element] { get }
    var isLoading: Bool { get }
    var error: Error? { get }

    func onRowAppeared(_ item: Element)
    @discardableResult func loadMore() -> Task<Void, Error>?
}

/// A generic paginated response handler that manages loading items with flexible pagination.
/// This class is designed to be used in the UI in conjunction with `PaginatedForEach`.
@MainActor
public final class DataViewPaginatedResponse<Element: Identifiable, PageIndex>: DataViewPaginatedResponseProtocol {
    @Published public private(set) var total: Int?
    @Published public private(set) var items: [Element] = []
    @Published public private(set) var hasMore = true
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?

    /// Result of a paginated load operation.
    public struct Page {
        public let items: [Element]
        public let total: Int?
        public let hasMore: Bool
        public let nextPage: PageIndex?

        public init(items: [Element], total: Int? = nil, hasMore: Bool, nextPage: PageIndex?) {
            self.items = items
            self.total = total
            self.hasMore = hasMore
            self.nextPage = nextPage
        }
    }

    public var isEmpty: Bool { items.isEmpty }

    private var nextPage: PageIndex?
    private let loadPage: (PageIndex?) async throws -> Page

    /// Creates a new paginated response handler.
    ///
    /// - Parameter loadPage: A closure that loads items using pagination.
    ///   - Parameter pageIndex: The page index to load (nil for initial load).
    ///   - Returns: A PaginatedResult containing the items, total count, whether more pages exist, and next page index.
    /// - Throws: Any error from the initial page load.
    public init(loadPage: @escaping (PageIndex?) async throws -> Page) async throws {
        self.loadPage = loadPage

        let response = try await loadPage(nil)
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
                let response = try await loadPage(nextPage)
                didLoad(response)
            } catch {
                self.error = error
                throw error
            }
        }
    }

    private func didLoad(_ response: Page) {
        total = response.total
        nextPage = response.nextPage
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
    public func onRowAppeared(_ row: Element) {
        guard items.suffix(10).contains(where: { $0.id == row.id }) else {
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
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }
        items.remove(at: index)
        if let total {
            self.total = total - 1
        }
    }

    public func replace(_ item: Element) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        items[index] = item
    }

    public func prepend(_ newItems: [Element]) {
        self.items = newItems + self.items
        if let total {
            self.total = total + newItems.count
        }
    }
}
