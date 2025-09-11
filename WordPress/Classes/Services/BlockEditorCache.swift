import Foundation
import CryptoKit
import WordPressShared
import WordPressData

final class BlockEditorCache {
    static let shared = BlockEditorCache()

    private let rootURL: URL
    private let blockSettingsURL: URL

    private init() {
        rootURL = URL.cachesDirectory
            .appendingPathComponent("GutenbergKit", isDirectory: true)
        blockSettingsURL = rootURL
            .appendingPathComponent("BlockSettings", isDirectory: true)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: blockSettingsURL, withIntermediateDirectories: true)
    }

    // MARK: - Block Settings

    func saveBlockSettings(_ settings: Data, for blogID: TaggedManagedObjectID<Blog>) throws {
        let fileURL = makeBlockSettingsURL(for: blogID)
        try settings.write(to: fileURL)
    }

    func getBlockSettings(for blogID: TaggedManagedObjectID<Blog>) -> Data? {
        let fileURL = makeBlockSettingsURL(for: blogID)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            return try Data(contentsOf: fileURL)
        } catch {
            DDLogError("Failed to load block editor settings: \(error)")
            // If the file is corrupted, delete it
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
    }

    func deleteBlockSettings(for blogID: TaggedManagedObjectID<Blog>) {
        let fileURL = makeBlockSettingsURL(for: blogID)

        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            DDLogError("Failed to delete block editor settings: \(error)")
        }
    }

    private func makeBlockSettingsURL(for blogID: TaggedManagedObjectID<Blog>) -> URL {
        let key = sha256(objectID: blogID.objectID)
        return blockSettingsURL.appendingPathComponent("\(key).json")
    }

    private func sha256(objectID: NSManagedObjectID) -> String {
        let uriString = objectID.uriRepresentation().absoluteString
        let data = Data(uriString.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Misc

    func deleteAll() {
        do {
            try FileManager.default.removeItem(at: rootURL)
            // Recreate the directory
            try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        } catch {
            DDLogError("Failed to delete all block editor settings: \(error)")
        }
    }
}
