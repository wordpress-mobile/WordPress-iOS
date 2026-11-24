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
        let original = try makePhoto(width: 2600, height: 1950)
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
        #expect(stored.fileSize < size(of: original))
    }

    /// A screenshot is already a fraction of a photo's size, and JPEG gives back more than it takes on flat
    /// colour and crisp text — so re-encoding one costs upload allowance and sharpness for nothing.
    @Test func keepsAnImageTheReEncodingWouldMakeBigger() throws {
        let original = try makeScreenshot(width: 1200, height: 800)
        defer { try? FileManager.default.removeItem(at: original) }

        let stored = try UnifiedSupportAttachmentStorage.store(original)
        defer { UnifiedSupportAttachmentStorage.delete(stored) }

        #expect(stored.url.pathExtension == "png")
        #expect(stored.fileSize == size(of: original))

        // The rejected JPEG doesn't stay behind taking up room next to the file that was kept.
        let directory = stored.url.deletingLastPathComponent()
        let siblings = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        #expect(siblings == [stored.url.lastPathComponent])
    }

    /// Whichever copy is stored, it is never the larger of the two — across the shapes a reply actually gets,
    /// above and below the point at which scaling down starts to help.
    @Test func neverStoresAnImageLargerThanTheOriginal() throws {
        for (width, height) in [(2600, 1950), (1200, 800), (750, 1334)] {
            for original in [
                try makePhoto(width: width, height: height),
                try makeScreenshot(width: width, height: height)
            ] {
                defer { try? FileManager.default.removeItem(at: original) }

                let stored = try UnifiedSupportAttachmentStorage.store(original)
                defer { UnifiedSupportAttachmentStorage.delete(stored) }

                #expect(stored.fileSize > 0)
                #expect(stored.fileSize <= size(of: original))
            }
        }
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

    private func size(of file: URL) -> UInt64 {
        let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize
        return UInt64(size ?? 0)
    }

    /// Continuous tone, like a camera photo: smooth gradients with fine grain over the top, which is the
    /// content JPEG was built for and PNG stores at close to full cost.
    private func makePhoto(width: Int, height: Int) throws -> URL {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        var seed: UInt64 = 0x9E37_79B9_7F4A_7C15

        for y in 0..<height {
            for x in 0..<width {
                seed ^= seed << 13
                seed ^= seed >> 7
                seed ^= seed << 17

                let grain = Double(seed % 1_000) / 1_000
                let base = 0.45 + 0.35 * sin(Double(x) / Double(width) * 6) * cos(Double(y) / Double(height) * 4)
                let offset = (y * width + x) * 4

                pixels[offset] = channel(base + 0.1 * grain)
                pixels[offset + 1] = channel(base * 0.85 + 0.1 * grain)
                pixels[offset + 2] = channel(base * 0.7 + 0.1 * grain)
                pixels[offset + 3] = .max
            }
        }

        return try write(pixels: &pixels, width: width, height: height)
    }

    /// Flat background with crisp dark blocks for text, like a screenshot of the app: PNG stores it in a
    /// fraction of the space JPEG needs for the same edges.
    private func makeScreenshot(width: Int, height: Int) throws -> URL {
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

        context.setFillColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        context.setFillColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        for row in stride(from: 20, to: height - 20, by: 26) {
            for glyph in stride(from: 16, to: width - 60, by: 17) {
                // A gap every so often, so the rows read as words rather than one long bar.
                if (glyph + row) % 5 != 0 {
                    context.fill(CGRect(x: glyph, y: row, width: 11, height: 16))
                }
            }
        }

        return try write(image: try #require(context.makeImage()))
    }

    private func channel(_ value: Double) -> UInt8 {
        UInt8(max(0, min(255, value * 255)))
    }

    private func write(pixels: inout [UInt8], width: Int, height: Int) throws -> URL {
        let context = try #require(
            CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
        )

        return try write(image: try #require(context.makeImage()))
    }

    private func write(image: CGImage) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).png")
        let writer = try #require(
            CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        )
        CGImageDestinationAddImage(writer, image, nil)
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
