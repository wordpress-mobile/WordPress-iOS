import CoreTransferable
import Foundation
import UniformTypeIdentifiers

extension UnifiedSupportPickedFile: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            try UnifiedSupportAttachmentStorage.store(received.file)
        }
        FileRepresentation(importedContentType: .movie) { received in
            try UnifiedSupportAttachmentStorage.store(received.file)
        }
    }
}

/// Keeps the files picked for a reply until they're sent or the reply is discarded.
enum UnifiedSupportAttachmentStorage {

    private static let directoryName = "unified-support-attachments"

    /// Copies a picked file to a directory of its own, so deleting one attachment never touches the others.
    static func store(_ file: URL) throws -> UnifiedSupportPickedFile {
        let id = UUID()
        let directory = URL.cachesDirectory
            .appendingPathComponent(directoryName)
            .appendingPathComponent(id.uuidString)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let destination = directory.appendingPathComponent(file.lastPathComponent)
        try FileManager.default.copyItem(at: file, to: destination)

        return UnifiedSupportPickedFile(id: id, url: destination, fileSize: size(of: destination))
    }

    static func delete(_ file: UnifiedSupportPickedFile) {
        // The file has a directory of its own, named after its ID.
        try? FileManager.default.removeItem(at: file.url.deletingLastPathComponent())
    }

    static func delete(_ files: [UnifiedSupportPickedFile]) {
        for file in files {
            delete(file)
        }
    }

    /// The size of the file in bytes, or `0` when the system doesn't report one.
    private static func size(of file: URL) -> UInt64 {
        let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize
        return UInt64(size ?? 0)
    }
}
