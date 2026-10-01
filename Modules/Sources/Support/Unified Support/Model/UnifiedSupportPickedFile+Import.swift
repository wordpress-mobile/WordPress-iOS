import CoreTransferable
import Foundation
import ImageIO
import UniformTypeIdentifiers

extension UnifiedSupportPickedFile: Transferable {
    /// The photo library offers images and videos under their own content types, so both have to be declared.
    /// They're stored the same way: `store` works out from the file itself whether re-encoding it is worth it.
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

    /// The longest edge a picked image is scaled down to, which is enough for a Happiness Engineer to read a
    /// screenshot while keeping a photo from taking the whole upload allowance on its own.
    private static let maximumImagePixelSize = 2048

    private static let imageCompressionQuality = 0.8

    /// Copies a picked file to a directory of its own, so deleting one attachment never touches the others.
    ///
    /// Still images are scaled down and re-encoded on the way in: a photo straight from the camera is several
    /// times the size of what support needs to see, and a handful of them wouldn't fit in one reply. Everything
    /// else — videos, documents, archives — is copied as it is.
    static func store(_ file: URL) throws -> UnifiedSupportPickedFile {
        let id = UUID()
        let directory = URL.cachesDirectory
            .appendingPathComponent(directoryName)
            .appendingPathComponent(id.uuidString)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var destination = directory.appendingPathComponent(file.lastPathComponent)

        // Falling back to the original keeps an image the system can't re-encode attachable.
        if shouldCompress(file), let compressed = compressImage(at: file, in: directory) {
            destination = compressed
        } else {
            try FileManager.default.copyItem(at: file, to: destination)
        }

        return UnifiedSupportPickedFile(id: id, url: destination, fileSize: size(of: destination))
    }

    /// Copies a file picked from outside the photo library, which the app may only read while it holds the
    /// file's security scope.
    ///
    /// The scope is let go of again straight away: the copy is the only thing that needs the original, and iOS
    /// hands out a limited number of them.
    static func store(securityScoped file: URL) throws -> UnifiedSupportPickedFile {
        let hasScope = file.startAccessingSecurityScopedResource()
        defer {
            if hasScope {
                file.stopAccessingSecurityScopedResource()
            }
        }

        // Read through a coordinator: a document picked from iCloud Drive may not be on the device yet, and
        // copying it straight away would fail rather than fetch it.
        var stored: Result<UnifiedSupportPickedFile, Error>?
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: file, error: &coordinationError) { url in
            stored = Result { try store(url) }
        }

        if let coordinationError {
            throw coordinationError
        }

        guard let stored else {
            throw CocoaError(.fileReadUnknown)
        }

        return try stored.get()
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

    /// Whether re-encoding the file as a smaller JPEG is worth it.
    ///
    /// Only still images are: a video costs more to re-encode than it saves, and a document would be destroyed
    /// by it. Animated images are left alone too, since re-encoding one keeps nothing but its first frame —
    /// which is usually the very thing the user attached it to show.
    private static func shouldCompress(_ file: URL) -> Bool {
        guard let type = try? file.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }

        return type.conforms(to: .image) && !type.conforms(to: .gif)
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
