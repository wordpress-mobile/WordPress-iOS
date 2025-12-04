import Foundation
import WordPressAPI
import WordPressAPIInternal

extension WordPressApiCache {
    static func bootstrap() -> WordPressApiCache? {
        .onDiskCache() ?? .memoryCache()
    }

    private static func onDiskCache() -> WordPressApiCache? {
        let cacheURL: URL
        do {
            cacheURL = try FileManager.default
                .url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appending(path: "app.sqlite")
        } catch {
            NSLog("Failed to create api cache file: \(error)")
            return nil
        }

        let cache: WordPressApiCache
        do {
            cache = try WordPressApiCache(url: cacheURL)
        } catch {
            NSLog("Failed to create an instance: \(error)")
            return nil
        }

        do {
            try cache.performMigrations()
        } catch {
            NSLog("Failed to migrate database: \(error)")
            return nil
        }

        return cache
    }

    private static func memoryCache() -> WordPressApiCache? {
        do {
            return try WordPressApiCache()
        } catch {
            NSLog("Failed to create memory cache: \(error)")
            return nil
        }
    }
}
