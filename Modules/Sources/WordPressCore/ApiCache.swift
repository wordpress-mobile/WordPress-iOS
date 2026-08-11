import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache
import WordPressShared

extension WordPressApiCache {
    /// The one cache instance shared by every `WordPressClient`.
    ///
    /// A single SQLite database backs the cache for the whole app, so every
    /// `WordPressApiCache` instance opens and migrates the same file.
    /// Bootstrapping more than one concurrently can fail and destroy a
    /// database still in use by another; sharing one instance keeps that to a
    /// single bootstrap. Swift's once-only static initialization guarantees
    /// it happens once per process.
    public static let shared = WordPressApiCache.bootstrap()

    /// An isolated in-memory cache for unit tests.
    ///
    /// Prefer this over `shared`, which is a process-wide singleton backed by
    /// an on-disk database and reused across the whole test run, so writing
    /// through it leaks state between tests.
    static func forTesting() throws -> WordPressApiCache {
        let cache = try WordPressApiCache()
        _ = try cache.performMigrations()
        return cache
    }

    /// A failure encountered while opening the on-disk cache. It carries the
    /// point of failure and the underlying error so the two can be reported
    /// together for Sentry classification.
    struct OnDiskCacheFailure: Error {
        enum Kind: Equatable {
            case couldNotOpenDatabase
            case migrationFailed
            case couldNotRemoveOrphanedSiblings
            case couldNotDeleteDatabase
            case couldNotRemoveSiblings
        }

        let kind: Kind
        let underlyingError: Error
    }

    /// The result of opening the on-disk cache.
    enum OnDiskCacheOutcome {
        /// Opened an existing or freshly created cache with nothing to report.
        case opened(WordPressApiCache)
        /// Opened only after recovering from a broken database. The failure
        /// that triggered recovery is surfaced for Sentry classification.
        case recovered(WordPressApiCache, from: OnDiskCacheFailure)
        /// Could not open an on-disk cache; the caller falls back to memory.
        case failed(OnDiskCacheFailure)
    }

    private static func bootstrap() -> WordPressApiCache {
        let cacheURL = URL.libraryDirectory.appending(path: "app.sqlite")

        let cache: WordPressApiCache
        switch onDiskCache(at: cacheURL) {
        case .opened(let opened):
            cache = opened
        case .recovered(let recovered, let failure):
            report(failure)
            cache = recovered
        case .failed(let failure):
            report(failure)
            cache = memoryCache()
        }

        cache.startListeningForUpdates()
        return cache
    }

    private static func report(_ failure: OnDiskCacheFailure) {
        // Report each kind from its own call site. `wpAssertionFailure` derives
        // its analytics identity and 7-day suppression key from #file/#line
        // (see AssertionLogger), so a shared call site would let one kind's
        // report suppress the others and collapse their Sentry grouping.
        let userInfo = ["error": "\(failure.underlyingError)"]
        switch failure.kind {
        case .couldNotOpenDatabase:
            wpAssertionFailure("Failed to create an instance", userInfo: userInfo)
        case .migrationFailed:
            wpAssertionFailure("Failed to migrate database", userInfo: userInfo)
        case .couldNotRemoveOrphanedSiblings:
            wpAssertionFailure("Failed to remove orphaned sqlite sibling files", userInfo: userInfo)
        case .couldNotDeleteDatabase:
            wpAssertionFailure("Failed to delete sqlite database", userInfo: userInfo)
        case .couldNotRemoveSiblings:
            wpAssertionFailure("Failed to remove sqlite sibling files", userInfo: userInfo)
        }
    }

    /// Opens (or creates) the on-disk cache at the given URL, recovering from a
    /// broken database by deleting it and starting over. Internal so tests can
    /// exercise the recovery path against a temporary location.
    static func onDiskCache(at cacheURL: URL) -> OnDiskCacheOutcome {
        let fileManager = FileManager.default

        // A previous app version may have deleted the database file without its
        // sibling files. An orphaned journal left next to a freshly created
        // database is a documented SQLite corruption vector, so remove any
        // leftovers first and refuse to continue if that cleanup fails.
        if !fileManager.fileExists(at: cacheURL) {
            do {
                try removeSiblingFiles(of: cacheURL)
            } catch {
                return .failed(OnDiskCacheFailure(kind: .couldNotRemoveOrphanedSiblings, underlyingError: error))
            }
        }

        switch openCache(file: cacheURL) {
        case .success(let cache):
            return .opened(cache)
        case .failure(let failure):
            // Only an existing database can be recovered by recreating it.
            guard fileManager.fileExists(at: cacheURL) else {
                return .failed(failure)
            }

            do {
                try fileManager.removeItem(at: cacheURL)
            } catch {
                return .failed(OnDiskCacheFailure(kind: .couldNotDeleteDatabase, underlyingError: error))
            }

            do {
                // Deleting the database but not its journal is a documented
                // SQLite corruption vector; always remove them together.
                try removeSiblingFiles(of: cacheURL)
            } catch {
                return .failed(OnDiskCacheFailure(kind: .couldNotRemoveSiblings, underlyingError: error))
            }

            switch openCache(file: cacheURL) {
            case .success(let cache):
                return .recovered(cache, from: failure)
            case .failure(let retryFailure):
                return .failed(retryFailure)
            }
        }
    }

    private static func openCache(file: URL) -> Result<WordPressApiCache, OnDiskCacheFailure> {
        let cache: WordPressApiCache
        do {
            cache = try WordPressApiCache(url: file)
        } catch {
            return .failure(OnDiskCacheFailure(kind: .couldNotOpenDatabase, underlyingError: error))
        }

        do {
            _ = try cache.performMigrations()
        } catch {
            return .failure(OnDiskCacheFailure(kind: .migrationFailed, underlyingError: error))
        }

        // Best-effort: keep the database out of iCloud backups. This can only
        // fail in exotic filesystem states, and the cache is usable regardless,
        // so it is not treated as a bootstrap failure.
        var url = file
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)

        return .success(cache)
    }

    private static func removeSiblingFiles(of cacheURL: URL) throws {
        let fileManager = FileManager.default
        for suffix in ["-journal", "-wal", "-shm"] {
            let sibling = URL(fileURLWithPath: cacheURL.path + suffix)
            // Absent siblings are fine; only a genuine failure to remove one
            // that exists is a corruption risk worth surfacing to the caller.
            if fileManager.fileExists(at: sibling) {
                try fileManager.removeItem(at: sibling)
            }
        }
    }

    private static func memoryCache() -> WordPressApiCache {
        // Fallback when the on-disk cache cannot be opened. Because the cache
        // is a process-wide singleton, this degradation lasts the whole
        // session by design; the cache is refetchable, so the cost is a cold
        // cache until relaunch.
        // Creating an in-memory database should always succeed.
        let cache = try! WordPressApiCache()
        _ = try! cache.performMigrations()
        return cache
    }
}
