import Foundation
import CryptoKit
import WordPressShared
import WordPressData

final actor BlockEditorCache {
    static let shared = BlockEditorCache()

    private let rootURL: URL
    private let blockSettingsURL: URL

    private init() {
        rootURL = URL.cachesDirectory
            .appendingPathComponent("GutenbergKit", isDirectory: true)
        blockSettingsURL = rootURL
            .appendingPathComponent("BlockSettings", isDirectory: true)
    }

    // MARK: - Block Settings
    func saveBlockSettings(_ settings: Data, for blogID: String) throws {
        try FileManager.default.createDirectory(at: blockSettingsURL, withIntermediateDirectories: true)

        let fileURL = makeBlockSettingsURL(for: blogID)
        try settings.write(to: fileURL)
    }

    func getBlockSettings(for blogID: String) throws -> Data? {
        let fileURL = makeBlockSettingsURL(for: blogID)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return try Data(contentsOf: fileURL)
    }

    func deleteBlockSettings(for blogID: String) throws {
        let fileURL = makeBlockSettingsURL(for: blogID)
        try FileManager.default.removeItem(at: fileURL)
    }

    func makeBlockSettingsURL(for blogID: String) -> URL {
        return blockSettingsURL.appendingPathComponent("\(blogID).json")
    }

    // MARK: - Misc
    func deleteAll() throws {
        try FileManager.default.removeItem(at: rootURL)
    }
}
