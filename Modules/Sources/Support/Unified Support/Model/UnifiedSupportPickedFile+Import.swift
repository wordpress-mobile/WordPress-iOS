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
    ///
    /// The re-encoding is only kept when it came back smaller. A screenshot is already a fraction of a photo's
    /// size and comes out of JPEG larger than it went in, so sending the original is both smaller and sharper.
    static func store(_ file: URL) throws -> UnifiedSupportPickedFile {
        let id = UUID()
        let directory = URL.cachesDirectory
            .appendingPathComponent(directoryName)
            .appendingPathComponent(id.uuidString)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var destination = directory.appendingPathComponent(file.lastPathComponent)
        let compressed = shouldCompress(file) ? compressImage(at: file, in: directory) : nil

        // Falling back to the original keeps an image the system can't re-encode attachable, and one the
        // re-encoding only made worse.
        if let compressed, isWorthKeeping(compressed, insteadOf: file) {
            destination = compressed
        } else {
            if let compressed {
                // Removed before the copy: an image already named `.jpeg` was re-encoded to the very path
                // the copy is about to need, and it would otherwise sit in the directory unused.
                try? FileManager.default.removeItem(at: compressed)
            }
            try FileManager.default.copyItem(at: file, to: destination)
        }

        return UnifiedSupportPickedFile(id: id, url: destination, fileSize: size(of: destination))
    }

    /// Copies a file picked from outside the photo library, which the app may only read while it holds the
    /// file's security scope.
    ///
    /// The scope is let go of again straight away: the copy is the only thing that needs the original, and iOS
    /// hands out a limited number of them.
    ///
    /// The coordination is handed in so the caller can stop a fetch it no longer wants.
    static func store(
        securityScoped file: URL,
        coordination: UnifiedSupportFileCoordination = UnifiedSupportFileCoordination()
    ) throws -> UnifiedSupportPickedFile {
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
        coordination.coordinate(readingItemAt: file, error: &coordinationError) { url in
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

    /// Whether the re-encoded copy earns its place over the original.
    ///
    /// `maximumImagePixelSize` only ever scales an image down, so one already smaller than it comes back the
    /// same size and only loses quality — and a screenshot of text comes out of JPEG several times the size of
    /// its PNG, which would take more of the upload allowance than the original asked for. A copy the system
    /// reports no size for isn't taken on trust either.
    private static func isWorthKeeping(_ compressed: URL, insteadOf original: URL) -> Bool {
        let compressedSize = size(of: compressed)
        return compressedSize > 0 && compressedSize < size(of: original)
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

/// Owns the file coordinator a browsed file is read through, so that leaving the reply form can stop a fetch
/// the coordinator hasn't granted yet.
///
/// The copy runs on a detached task, which inherits no cancellation of its own, so there is otherwise nothing
/// to stop an iCloud Drive document being downloaded in full for a reply the user has already thrown away.
/// Cancelling only helps before the read is granted — once the file is on the device the coordinator waits for
/// the copy to finish — which is exactly the case worth stopping: the download is what the read waits on.
///
/// `NSFileCoordinator` is not `Sendable`, but `cancel()` is documented as callable from any thread, which is
/// the only thing done to it from outside the task doing the reading.
final class UnifiedSupportFileCoordination: @unchecked Sendable {

    private let coordinator = NSFileCoordinator()

    func coordinate(readingItemAt url: URL, error: NSErrorPointer, by reader: (URL) -> Void) {
        coordinator.coordinate(readingItemAt: url, error: error, byAccessor: reader)
    }

    /// Stops a read that hasn't been granted yet, failing it with `NSUserCancelledError`.
    func cancel() {
        coordinator.cancel()
    }
}
