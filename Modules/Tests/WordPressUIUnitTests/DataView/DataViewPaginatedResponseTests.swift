import Foundation
import Testing
import WordPressUI

@MainActor
@Suite final class DataViewPaginatedResponseTests {
    struct TestItem: Identifiable, Equatable {
        let id: Int
        let name: String
    }

    @Test func initLoadFirstPage() async throws {
        // GIVEN
        let expectedItems = [
            TestItem(id: 1, name: "Item 1"),
            TestItem(id: 2, name: "Item 2")
        ]

        // WHEN
        let response = try await DataViewPaginatedResponse<TestItem, Int> { pageIndex in
            #expect(pageIndex == nil) // Initial load
            return DataViewPaginatedResponse<TestItem, Int>.Page(
                items: expectedItems,
                total: 10,
                hasMore: true,
                nextPage: 2
            )
        }

        // THEN
        #expect(response.items == expectedItems)
        #expect(response.total == 10)
        #expect(response.hasMore == true)
        #expect(response.isEmpty == false)
        #expect(response.isLoading == false)
        #expect(response.error == nil)
    }

    @Test func initThrowsError() async throws {
        // GIVEN
        struct TestError: Error {}

        // WHEN/THEN
        await #expect(throws: TestError.self) {
            _ = try await DataViewPaginatedResponse<TestItem, Int> { _ in
                throw TestError()
            }
        }
    }

    @Test func loadMoreSuccessfully() async throws {
        // GIVEN
        var pageRequests: [Int?] = []
        let response = try await DataViewPaginatedResponse<TestItem, Int> { pageIndex in
            pageRequests.append(pageIndex)

            switch pageIndex {
            case nil:
                return DataViewPaginatedResponse<TestItem, Int>.Page(
                    items: [TestItem(id: 1, name: "Item 1")],
                    total: 3,
                    hasMore: true,
                    nextPage: 2
                )
            case 2:
                return DataViewPaginatedResponse<TestItem, Int>.Page(
                    items: [TestItem(id: 2, name: "Item 2")],
                    total: 3,
                    hasMore: true,
                    nextPage: 3
                )
            case 3:
                return DataViewPaginatedResponse<TestItem, Int>.Page(
                    items: [TestItem(id: 3, name: "Item 3")],
                    total: 3,
                    hasMore: false,
                    nextPage: nil
                )
            default:
                fatalError("Unexpected page: \(String(describing: pageIndex))")
            }
        }

        #expect(pageRequests == [nil])

        // WHEN loading page 2
        do {
            let task = response.loadMore()
            #expect(response.isLoading)
            try await task?.value
        }

        // THEN
        #expect(response.items.count == 2)
        #expect(response.items.map(\.id) == [1, 2])
        #expect(response.hasMore == true)
        #expect(pageRequests == [nil, 2])

        // WHEN loading page 3
        do {
            let task = response.loadMore()
            #expect(response.isLoading)
            try await task?.value
        }

        // THEN
        #expect(response.items.count == 3)
        #expect(response.items.map(\.id) == [1, 2, 3])
        #expect(response.hasMore == false)
        #expect(pageRequests == [nil, 2, 3])

        // WHEN trying to load more when hasMore is false
        do {
            let task = response.loadMore()
            #expect(response.isLoading == false)
            #expect(task == nil)
        }

        // THEN no additional requests are made
        #expect(pageRequests == [nil, 2, 3])
    }

    @Test func loadMoreHandlesError() async throws {
        // GIVEN
        struct TestError: Error {}
        var shouldThrow = false

        let response = try await DataViewPaginatedResponse<TestItem, Int> { pageIndex in
            if shouldThrow {
                throw TestError()
            }
            let id = pageIndex ?? 1
            return DataViewPaginatedResponse<TestItem, Int>.Page(
                items: [TestItem(id: id, name: "Item \(id)")],
                total: 10,
                hasMore: true,
                nextPage: (pageIndex ?? 1) + 1
            )
        }

        // WHEN loading successfully
        do {
            let task = response.loadMore()
            #expect(response.isLoading)
            try await task?.value
        }
        #expect(response.items.count == 2)
        #expect(response.error == nil)

        // WHEN error occurs
        shouldThrow = true
        do {
            let task = response.loadMore()
            #expect(response.isLoading)
            do {
                try await task?.value
                Issue.record("Expected it to fail")
            } catch {
                // Do nothing
            }
        }

        // THEN
        #expect(response.error != nil)
        #expect(response.error is TestError)
        #expect(response.items.count == 2) // Items remain unchanged

        // WHEN retrying after error
        shouldThrow = false
        do {
            let task = response.loadMore()
            #expect(response.isLoading)
            try await task?.value
        }

        // THEN retry succeeds
        #expect(response.error == nil)
        #expect(response.items.count == 3)
    }

    @Test func filtersDuplicateItems() async throws {
        // GIVEN
        let response = try await DataViewPaginatedResponse<TestItem, Int> { pageIndex in
            if pageIndex == nil {
                return DataViewPaginatedResponse<TestItem, Int>.Page(
                    items: [
                        TestItem(id: 1, name: "Item 1"),
                        TestItem(id: 2, name: "Item 2")
                    ],
                    total: 4,
                    hasMore: true,
                    nextPage: 2
                )
            } else {
                // Page 2 includes a duplicate item
                return DataViewPaginatedResponse<TestItem, Int>.Page(
                    items: [
                        TestItem(id: 2, name: "Item 2 Duplicate"),
                        TestItem(id: 3, name: "Item 3"),
                        TestItem(id: 4, name: "Item 4")
                    ],
                    total: 4,
                    hasMore: false,
                    nextPage: nil
                )
            }
        }

        // WHEN
        do {
            let task = response.loadMore()
            #expect(response.isLoading)
            try await task?.value
        }

        // THEN duplicates are filtered out
        #expect(response.items.count == 4)
        #expect(response.items.map(\.id) == [1, 2, 3, 4])
        #expect(response.items[1].name == "Item 2") // Original item is kept
    }

    @Test func preventsConcurrentLoads() async throws {
        // GIVEN
        var loadCount = 0
        let response = try await DataViewPaginatedResponse<TestItem, Int> { pageIndex in
            loadCount += 1
            let id = pageIndex ?? 1
            return DataViewPaginatedResponse<TestItem, Int>.Page(
                items: [TestItem(id: id, name: "Item \(id)")],
                total: 10,
                hasMore: true,
                nextPage: (pageIndex ?? 1) + 1
            )
        }

        // WHEN multiple loadMore calls are made concurrently
        let task = response.loadMore()
        #expect(response.loadMore() == nil)
        #expect(response.loadMore() == nil)

        try await task?.value

        // THEN only one load occurs
        #expect(loadCount == 2) // Counting the initial load
        #expect(response.items.count == 2)
    }

    @Test func onRowAppearedTriggersLoad() async throws {
        // GIVEN
        var items: [TestItem] = []
        for i in 1...20 {
            items.append(TestItem(id: i, name: "Item \(i)"))
        }

        let response = try await DataViewPaginatedResponse<TestItem, Int> { pageIndex in
            if pageIndex == nil {
                return DataViewPaginatedResponse<TestItem, Int>.Page(
                    items: Array(items.prefix(20)),
                    total: 30,
                    hasMore: true,
                    nextPage: 2
                )
            } else {
                return DataViewPaginatedResponse<TestItem, Int>.Page(
                    items: Array(items.suffix(10)),
                    total: 30,
                    hasMore: false,
                    nextPage: nil
                )
            }
        }

        // WHEN row in the middle appears
        response.onRowAppeared(response.items[0])

        // THEN no load is triggered
        #expect(response.isLoading == false)

        // WHEN row in the last 16 items appears
        response.onRowAppeared(response.items[15])
        #expect(response.isLoading)
    }

    @Test func onRowAppearedDoesNotLoadWhenError() async throws {
        // GIVEN
        struct TestError: Error {}
        var shouldThrow = false
        var loadAttempts = 0

        let response = try await DataViewPaginatedResponse<TestItem, Int> { pageIndex in
            loadAttempts += 1
            if shouldThrow {
                throw TestError()
            }

            let page = pageIndex ?? 1
            var items: [TestItem] = []
            for i in 1...20 {
                items.append(TestItem(id: i + (page - 1) * 20, name: "Item \(i)"))
            }

            return DataViewPaginatedResponse<TestItem, Int>.Page(
                items: items,
                total: 40,
                hasMore: page < 2,
                nextPage: page < 2 ? page + 1 : nil
            )
        }

        // WHEN error occurs on second page
        shouldThrow = true
        do {
            let task = response.loadMore()
            #expect(response.isLoading)
            do {
                try await task?.value
                Issue.record("Expected it to fail")
            } catch {
                // Do nothing
            }
        }

        #expect(response.error != nil)

        // WHEN row appears after error
        response.onRowAppeared(response.items[15])
        #expect(response.isLoading == false)

        // THEN no additional load attempts are made
    }

    @Test func deleteItem() async throws {
        // GIVEN
        let response = try await DataViewPaginatedResponse<TestItem, Int> { _ in
            return DataViewPaginatedResponse<TestItem, Int>.Page(
                items: [
                    TestItem(id: 1, name: "Item 1"),
                    TestItem(id: 2, name: "Item 2"),
                    TestItem(id: 3, name: "Item 3")
                ],
                total: 3,
                hasMore: false,
                nextPage: nil
            )
        }

        #expect(response.items.count == 3)

        // WHEN
        response.deleteItem(withID: 2)

        // THEN
        #expect(response.items.count == 2)
        #expect(response.items.map(\.id) == [1, 3])
        #expect(response.total == 2) // Total is updated
    }

    @Test func deleteNonExistentItem() async throws {
        // GIVEN
        let response = try await DataViewPaginatedResponse<TestItem, Int> { _ in
            return DataViewPaginatedResponse<TestItem, Int>.Page(
                items: [
                    TestItem(id: 1, name: "Item 1"),
                    TestItem(id: 2, name: "Item 2")
                ],
                total: 2,
                hasMore: false,
                nextPage: nil
            )
        }

        // WHEN deleting non-existent item
        response.deleteItem(withID: 999)

        // THEN nothing changes
        #expect(response.items.count == 2)
        #expect(response.items.map(\.id) == [1, 2])
        #expect(response.total == 2) // Total remains unchanged
    }
}
