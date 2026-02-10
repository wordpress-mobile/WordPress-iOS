import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache

extension WordPressApiCache {
    static func bootstrap() -> WordPressApiCache? {
        let instance: WordPressApiCache? = .onDiskCache() ?? .memoryCache()
        instance?.startListeningForUpdates()
        return instance
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

        return cache
    }

    private static func memoryCache() -> WordPressApiCache? {
        do {
            let cache = try WordPressApiCache()
            _ = try cache.performMigrations()
            return cache
        } catch {
            NSLog("Failed to create memory cache: \(error)")
            return nil
        }
    }
}
