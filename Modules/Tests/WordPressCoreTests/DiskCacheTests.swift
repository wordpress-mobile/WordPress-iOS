import Foundation
import Testing

@testable import WordPressCore

struct DiskCacheTests {

    /// Each test gets its own root so a run never reads, writes, or deletes anything in the real
    /// caches directory.
    private func makeCache() throws -> (DiskCache, URL) {
        let root = URL.temporaryDirectory.appending(path: "DiskCacheTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return (DiskCache(cacheRoot: root), root)
    }

    @Test func storesAndReadsBackAValue() async throws {
        let (cache, root) = try makeCache()
        defer { try? FileManager.default.removeItem(at: root) }

        try await cache.store(["a", "b"], forKey: "key")

        #expect(try await cache.read([String].self, forKey: "key") == ["a", "b"])
    }

    /// A freshly-written entry is inside any sane window, so it has to come back. Before the fix
    /// the comparison was inverted and this returned `nil`.
    @Test func readsBackAnEntryThatIsStillFresh() async throws {
        let (cache, root) = try makeCache()
        defer { try? FileManager.default.removeItem(at: root) }

        try await cache.store("value", forKey: "key")

        #expect(try await cache.read(String.self, forKey: "key", notOlderThan: 3600) == "value")
    }

    /// The counterpart: a zero-length window expires the entry immediately.
    @Test func treatsAnExpiredEntryAsAMiss() async throws {
        let (cache, root) = try makeCache()
        defer { try? FileManager.default.removeItem(at: root) }

        try await cache.store("value", forKey: "key")
        // The entry was written in the past, however narrowly, so any elapsed window excludes it.
        try await Task.sleep(for: .milliseconds(50))

        #expect(try await cache.read(String.self, forKey: "key", notOlderThan: 0) == nil)
    }

    /// Passing no interval skips the age check entirely.
    @Test func readsBackAnEntryWhenNoIntervalIsGiven() async throws {
        let (cache, root) = try makeCache()
        defer { try? FileManager.default.removeItem(at: root) }

        try await cache.store("value", forKey: "key")

        #expect(try await cache.read(String.self, forKey: "key") == "value")
    }

    @Test func returnsNilForAKeyThatWasNeverStored() async throws {
        let (cache, root) = try makeCache()
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(try await cache.read(String.self, forKey: "missing") == nil)
        #expect(try await cache.read(String.self, forKey: "missing", notOlderThan: 3600) == nil)
    }

    /// The age check used to resolve the file through a percent-encoded path string, which named a
    /// file that doesn't exist whenever the key needed encoding.
    @Test func handlesAKeyThatNeedsPercentEncoding() async throws {
        let (cache, root) = try makeCache()
        defer { try? FileManager.default.removeItem(at: root) }

        try await cache.store("value", forKey: "conversation 1 of 100%")

        #expect(try await cache.read(String.self, forKey: "conversation 1 of 100%", notOlderThan: 3600) == "value")
    }

    @Test func removesAStoredEntry() async throws {
        let (cache, root) = try makeCache()
        defer { try? FileManager.default.removeItem(at: root) }

        try await cache.store("value", forKey: "key")
        try await cache.remove(key: "key")

        #expect(try await cache.read(String.self, forKey: "key") == nil)
    }

    /// `removeAll` only touches the injected root, which is what keeps these tests from clearing a
    /// developer's real cache.
    @Test func removeAllClearsOnlyTheInjectedRoot() async throws {
        let (cache, root) = try makeCache()
        defer { try? FileManager.default.removeItem(at: root) }

        try await cache.store("a", forKey: "one")
        try await cache.store("b", forKey: "two")
        #expect(try await cache.count() == 2)

        try await cache.removeAll()

        #expect(try await cache.count() == 0)
    }
}
