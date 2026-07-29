import Foundation
import Testing
import WordPressApiCache
@testable import WordPressCore

@Suite
struct ApiCacheTests {
    @Test
    func missingFileReturnsNilWithoutCreatingFile() throws {
        let url = makeTemporaryCacheURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let cache = try WordPressApiCache.openExistingOnDiskCache(file: url)

        #expect(cache == nil)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test
    func existingMigratedFileReturnsCache() throws {
        let url = makeTemporaryCacheURL()
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            let cache = try WordPressApiCache(url: url)
            _ = try cache.performMigrations()
        }

        let cache = try WordPressApiCache.openExistingOnDiskCache(file: url)

        #expect(cache != nil)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test
    func invalidFileThrowsWithoutChangingFile() throws {
        let url = makeTemporaryCacheURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let originalData = Data("invalid sqlite database".utf8)
        try originalData.write(to: url)
        var thrownError: (any Error)?

        do {
            _ = try WordPressApiCache.openExistingOnDiskCache(file: url)
        } catch {
            thrownError = error
        }

        #expect(thrownError != nil)
        #expect(try Data(contentsOf: url) == originalData)
    }

    private func makeTemporaryCacheURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "WordPressApiCacheTests-\(UUID().uuidString).sqlite")
    }
}
