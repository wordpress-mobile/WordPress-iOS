import Foundation
import Testing
import WordPressCore

@Suite(.timeLimit(.minutes(1)))
struct InMemoryDataStoreTests {

    @Test
    func testUpdatesAfterCreation() async {
        let store: InMemoryUserDataStore = InMemoryUserDataStore()
        let stream = await store.listStream(query: .all)

        await confirmation("The stream produces an update") { confirmation in
            for await _ in stream.prefix(1) {
                confirmation()
            }
        }
    }

    @Test
    func testUpdatesAfterStore() async {
        let store: InMemoryUserDataStore = InMemoryUserDataStore()
        let stream = await store.listStream(query: .all)

        Task.detached {
            try await Task.sleep(for: .milliseconds(50))
            try await store.store([.mockUser])
        }

        await confirmation("The stream produces an update", expectedCount: 2) { confirmation in
            for await _ in stream.prefix(2) {
                confirmation()
            }
        }
    }

    @Test
    func testUpdatesAfterDelete() async throws {
        let store: InMemoryUserDataStore = InMemoryUserDataStore()
        try await store.store([.mockUser])

        let stream = await store.listStream(query: .all)

        Task.detached {
            try await Task.sleep(for: .milliseconds(50))
            try await store.delete(query: .all)
        }

        await confirmation("The stream produces an update", expectedCount: 2) { confirmation in
            for await _ in stream.prefix(2) {
                confirmation()
            }
        }
    }

    @Test
    func testStreamTerminates() async {
        var store: InMemoryUserDataStore? = InMemoryUserDataStore()
        let stream = await store!.listStream(query: .all)

        Task.detached {
            try await Task.sleep(for: .milliseconds(50))
            store = nil
        }

        await confirmation("The stream produces one update and then terminates", expectedCount: 1) { confirmation in
            for await _ in stream {
                // Do nothing
            }
            confirmation()
        }
    }

}
