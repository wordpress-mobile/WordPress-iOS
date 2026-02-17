import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache
import WordPressShared

extension WordPressApiCache {
    static func bootstrap() -> WordPressApiCache {
        let instance: WordPressApiCache = .onDiskCache() ?? .memoryCache()
        instance.startListeningForUpdates()
        return instance
    }

    private static func onDiskCache() -> WordPressApiCache? {
        let cacheURL = URL.libraryDirectory.appending(path: "app.sqlite")

        if let cache = WordPressApiCache.onDiskCache(file: cacheURL) {
            return cache
        }

        if FileManager.default.fileExists(at: cacheURL) {
            do {
                try FileManager.default.removeItem(at: cacheURL)

                if let cache = WordPressApiCache.onDiskCache(file: cacheURL) {
                    return cache
                }
            } catch {
                wpAssertionFailure("Failed to delete sqlite database")
            }
        }

        return nil
    }

    private static func onDiskCache(file: URL) -> WordPressApiCache? {
        let cache: WordPressApiCache
        do {
            cache = try WordPressApiCache(url: file)
        } catch {
            wpAssertionFailure("Failed to create an instance")
            return nil
        }

        do {
            _ = try cache.performMigrations()
        } catch {
            wpAssertionFailure("Failed to migrate database")
            return nil
        }

        do {
            var url = file
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try url.setResourceValues(values)
        } catch {
            wpAssertionFailure("Failed exclude the database file from iCloud backup")
        }

        return cache
    }

    private static func memoryCache() -> WordPressApiCache {
        // Creating an in-memory database should always succeed.
        let cache = try! WordPressApiCache()
        _ = try! cache.performMigrations()
        return cache
    }
}
