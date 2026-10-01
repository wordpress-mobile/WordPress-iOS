import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Support

struct UnifiedSupportAttachmentStorageTests {

    /// A photo straight from the camera is several times the size support needs, and a few of them wouldn't fit
    /// in one reply.
    @Test func scalesDownAPickedImage() throws {
        let original = try makeImage(width: 4032, height: 3024)
        defer { try? FileManager.default.removeItem(at: original) }

        let stored = try UnifiedSupportAttachmentStorage.store(original)
        defer { UnifiedSupportAttachmentStorage.delete(stored) }

        let source = try #require(CGImageSourceCreateWithURL(stored.url as CFURL, nil))
        let properties = try #require(
            CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        )
        let width = try #require(properties[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(properties[kCGImagePropertyPixelHeight] as? Int)

        #expect(max(width, height) == 2048)
        #expect(stored.url.pathExtension == "jpeg")
        // What matters for the upload limit: a full size photo comes out as a fraction of the 20 MB allowance.
        #expect(stored.fileSize > 0)
        #expect(stored.fileSize < 2_000_000)
    }

    /// Everything that isn't a still image is left alone: re-encoding a video costs more than it saves, and a
    /// document wouldn't survive it.
    @Test(arguments: ["mov", "pdf", "txt", "zip", "log"])
    func keepsANonImageAsItIs(_ pathExtension: String) throws {
        let original = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).\(pathExtension)")
        try Data(repeating: 0x1, count: 2_048).write(to: original)
        defer { try? FileManager.default.removeItem(at: original) }

        let stored = try UnifiedSupportAttachmentStorage.store(original)
        defer { UnifiedSupportAttachmentStorage.delete(stored) }

        #expect(stored.filename == original.lastPathComponent)
        #expect(stored.fileSize == 2_048)
    }

    /// Re-encoding an animated image keeps nothing but its first frame, which is usually the very thing the
    /// user attached it to show.
    @Test func keepsAnAnimatedImageAsItIs() throws {
        let original = try makeAnimatedGif()
        defer { try? FileManager.default.removeItem(at: original) }

        let stored = try UnifiedSupportAttachmentStorage.store(original)
        defer { UnifiedSupportAttachmentStorage.delete(stored) }

        #expect(stored.url.pathExtension == "gif")

        let source = try #require(CGImageSourceCreateWithURL(stored.url as CFURL, nil))
        #expect(CGImageSourceGetCount(source) == 2)
    }

    /// A browsed file is read through its security scope, which a file already inside the sandbox doesn't have
    /// and doesn't need.
    @Test func storesAFileBrowsedFromOutsideThePhotoLibrary() throws {
        let original = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).pdf")
        try Data(repeating: 0x1, count: 512).write(to: original)
        defer { try? FileManager.default.removeItem(at: original) }

        let stored = try UnifiedSupportAttachmentStorage.store(securityScoped: original)
        defer { UnifiedSupportAttachmentStorage.delete(stored) }

        #expect(stored.filename == original.lastPathComponent)
        #expect(stored.fileSize == 512)
    }

    /// Each file gets a directory of its own, so removing one attachment leaves the others alone.
    @Test func deletingOneFileLeavesTheOthers() throws {
        let original = try makeImage(width: 64, height: 64)
        defer { try? FileManager.default.removeItem(at: original) }

        let first = try UnifiedSupportAttachmentStorage.store(original)
        let second = try UnifiedSupportAttachmentStorage.store(original)
        defer { UnifiedSupportAttachmentStorage.delete(second) }

        UnifiedSupportAttachmentStorage.delete(first)

        #expect(!FileManager.default.fileExists(atPath: first.url.path))
        #expect(FileManager.default.fileExists(atPath: second.url.path))
    }

    private func makeAnimatedGif() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).gif")
        let writer = try #require(
            CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, 2, nil)
        )

        for _ in 0..<2 {
            let frame = try makeImage(width: 16, height: 16)
            defer { try? FileManager.default.removeItem(at: frame) }

            let source = try #require(CGImageSourceCreateWithURL(frame as CFURL, nil))
            let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
            CGImageDestinationAddImage(writer, image, nil)
        }

        #expect(CGImageDestinationFinalize(writer))

        return url
    }

    private func makeImage(width: Int, height: Int) throws -> URL {
        let context = try #require(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
        )
        // A flat colour compresses too well to tell sizes apart, so the image gets some detail.
        for x in stride(from: 0, to: width, by: 8) {
            context.setFillColor(red: Double(x % 255) / 255, green: 0.3, blue: 0.7, alpha: 1)
            context.fill(CGRect(x: x, y: 0, width: 8, height: height))
        }
        let image = try #require(context.makeImage())

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).png")
        let writer = try #require(
            CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        )
        CGImageDestinationAddImage(writer, image, nil)
        #expect(CGImageDestinationFinalize(writer))

        return url
    }
}
