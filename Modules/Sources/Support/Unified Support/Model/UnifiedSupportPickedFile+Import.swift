import CoreTransferable
import Foundation
import ImageIO
import UniformTypeIdentifiers

extension UnifiedSupportPickedFile: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            try UnifiedSupportAttachmentStorage.store(received.file, compressingImage: true)
        }
        FileRepresentation(importedContentType: .movie) { received in
            try UnifiedSupportAttachmentStorage.store(received.file)
        }
    }
}

/// Keeps the files picked for a reply until they're sent or the reply is discarded.
enum UnifiedSupportAttachmentStorage {

    private static let directoryName = "unified-support-attachments"

    /// The longest edge a picked image is scaled down to, which is enough for a Happiness Engineer to read a
    /// screenshot while keeping a photo from taking the whole upload allowance on its own.
    private static let maximumImagePixelSize = 2048

    private static let imageCompressionQuality = 0.8

    /// Copies a picked file to a directory of its own, so deleting one attachment never touches the others.
    ///
    /// Images are scaled down and re-encoded on the way in: a photo straight from the camera is several times the
    /// size of what support needs to see, and a handful of them wouldn't fit in one reply.
    static func store(_ file: URL, compressingImage: Bool = false) throws -> UnifiedSupportPickedFile {
        let id = UUID()
        let directory = URL.cachesDirectory
            .appendingPathComponent(directoryName)
            .appendingPathComponent(id.uuidString)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var destination = directory.appendingPathComponent(file.lastPathComponent)

        // Falling back to the original keeps an image the system can't re-encode attachable.
        if compressingImage, let compressed = compressImage(at: file, in: directory) {
            destination = compressed
        } else {
            try FileManager.default.copyItem(at: file, to: destination)
        }

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

    /// Writes a scaled down JPEG copy of an image next to it, and returns where it landed.
    ///
    /// Returns `nil` when the image can't be read or written, leaving the caller to send the original.
    private static func compressImage(at file: URL, in directory: URL) -> URL? {
        guard let source = CGImageSourceCreateWithURL(file as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            // Scaling as the image is decoded keeps a large photo from being held in memory in full.
            kCGImageSourceThumbnailMaxPixelSize: maximumImagePixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let destination = directory
            .appendingPathComponent(file.deletingPathExtension().lastPathComponent)
            .appendingPathExtension(for: .jpeg)
        guard
            let writer = CGImageDestinationCreateWithURL(
                destination as CFURL,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else {
            return nil
        }

        CGImageDestinationAddImage(
            writer,
            image,
            [kCGImageDestinationLossyCompressionQuality: imageCompressionQuality] as CFDictionary
        )
        guard CGImageDestinationFinalize(writer) else {
            try? FileManager.default.removeItem(at: destination)
            return nil
        }

        return destination
    }

    /// The size of the file in bytes, or `0` when the system doesn't report one.
    private static func size(of file: URL) -> UInt64 {
        let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize
        return UInt64(size ?? 0)
    }
}
