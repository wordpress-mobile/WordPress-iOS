import Foundation
import Testing
import WordPressApiCache
@testable import WordPressCore

@Suite
struct ApiCacheBootstrapTests {
    private let directory: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private var databaseURL: URL {
        directory.appending(path: "app.sqlite")
    }

    private var journalURL: URL {
        URL(fileURLWithPath: databaseURL.path + "-journal")
    }

    private var walURL: URL {
        URL(fileURLWithPath: databaseURL.path + "-wal")
    }

    private var shmURL: URL {
        URL(fileURLWithPath: databaseURL.path + "-shm")
    }

    @Test func createsDatabaseOnFirstBootstrap() {
        let outcome = WordPressApiCache.onDiskCache(at: databaseURL)

        guard case .opened = outcome else {
            Issue.record("Expected .opened, got \(outcome)")
            return
        }
        #expect(FileManager.default.fileExists(at: databaseURL))
    }

    @Test func recoversFromCorruptDatabaseAndRemovesSiblings() throws {
        try Data("not a database".utf8).write(to: databaseURL)
        try Data("stale journal".utf8).write(to: journalURL)
        try Data("stale wal".utf8).write(to: walURL)
        try Data("stale shm".utf8).write(to: shmURL)

        let outcome = WordPressApiCache.onDiskCache(at: databaseURL)

        guard case .recovered(_, let failure) = outcome else {
            Issue.record("Expected .recovered, got \(outcome)")
            return
        }
        // The corrupt file may fail at open or at migration; either is recovery.
        #expect(failure.kind == .couldNotOpenDatabase || failure.kind == .migrationFailed)
        #expect(FileManager.default.fileExists(at: databaseURL))
        #expect(!FileManager.default.fileExists(at: journalURL))
        #expect(!FileManager.default.fileExists(at: walURL))
        #expect(!FileManager.default.fileExists(at: shmURL))
    }

    @Test func removesOrphanedSiblingsBeforeCreatingDatabase() throws {
        // No database file, only leftovers a previous delete-on-failure may
        // have stranded. SQLite ignores an unmatched -wal file in rollback
        // journal mode, so only the pre-open cleanup removes it.
        try Data("stale journal".utf8).write(to: journalURL)
        try Data("stale wal".utf8).write(to: walURL)

        let outcome = WordPressApiCache.onDiskCache(at: databaseURL)

        guard case .opened = outcome else {
            Issue.record("Expected .opened, got \(outcome)")
            return
        }
        #expect(!FileManager.default.fileExists(at: journalURL))
        #expect(!FileManager.default.fileExists(at: walURL))
    }

    @Test func failsWhenOrphanedSiblingCannotBeRemoved() throws {
        // A stale sibling next to a missing database that cannot be removed
        // must not be paired with a freshly created database. Make the
        // directory read-only so removing the journal fails.
        try Data("stale journal".utf8).write(to: journalURL)
        let fileManager = FileManager.default
        try fileManager.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path)
        defer {
            try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
        }

        let outcome = WordPressApiCache.onDiskCache(at: databaseURL)

        guard case .failed(let failure) = outcome else {
            Issue.record("Expected .failed, got \(outcome)")
            return
        }
        #expect(failure.kind == .couldNotRemoveOrphanedSiblings)
        #expect(!fileManager.fileExists(at: databaseURL))
    }

    @Test func failsWhenDatabaseCannotBeCreated() {
        let unwritableURL =
            directory
            .appending(path: "missing-subdirectory")
            .appending(path: "app.sqlite")

        let outcome = WordPressApiCache.onDiskCache(at: unwritableURL)

        guard case .failed(let failure) = outcome else {
            Issue.record("Expected .failed, got \(outcome)")
            return
        }
        #expect(failure.kind == .couldNotOpenDatabase)
    }

    @Test func clientsShareSingleCacheInstance() async {
        let clientA = WordPressClient(api: MockWordPressClientAPI(), siteURL: URL(string: "https://example.com")!)
        let clientB = WordPressClient(api: MockWordPressClientAPI(), siteURL: URL(string: "https://example.org")!)

        let cacheA = await clientA.cache
        let cacheB = await clientB.cache

        #expect(cacheA === cacheB)
        #expect(cacheA === WordPressApiCache.shared)
    }
}
