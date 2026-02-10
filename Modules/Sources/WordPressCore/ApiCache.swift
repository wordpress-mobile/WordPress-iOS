import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache

extension WordPressApiCache {
    static func bootstrap() -> WordPressApiCache {
        let instance: WordPressApiCache = .onDiskCache() ?? .memoryCache()
        instance.startListeningForUpdates()
        return instance
    }

    // TODO:
    // - Log errors to sentry: https://github.com/wordpress-mobile/WordPress-iOS/pull/25157#discussion_r2785458461
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
                NSLog("Failed to delete sqlite database: \(error)")
            }
        }

        return nil
    }

    private static func onDiskCache(file: URL) -> WordPressApiCache? {
        let cache: WordPressApiCache
        do {
            cache = try WordPressApiCache(url: file)
        } catch {
            NSLog("Failed to create an instance: \(error)")
            return nil
        }

        do {
            _ = try cache.performMigrations()
        } catch {
            NSLog("Failed to migrate database: \(error)")
            return nil
        }

        do {
            var url = file
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try url.setResourceValues(values)
        } catch {
            NSLog("Failed exclude the database file from iCloud backup: \(error)")
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
