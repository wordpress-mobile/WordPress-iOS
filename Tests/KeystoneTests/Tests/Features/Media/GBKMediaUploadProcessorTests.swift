import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
import WordPressShared

@testable import WordPress

struct GBKMediaUploadProcessorTests {

    // MARK: - Images

    @Test func imageIsResizedWhenOptimizationEnabled() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        settings.maxImageSizeSetting = 200
        let processor = makeProcessor(settings: settings)
        let url = try fixtureURL("test-image-device-photo-gps.jpg")

        let result = try await processor.processFile(at: url, mimeType: "image/jpeg", filename: url.lastPathComponent)

        guard case .processed(let outputURL, let mimeType, let filename) = result else {
            Issue.record("Expected a processed file")
            return
        }
        defer { cleanUp(outputURL) }
        let size = try imageSize(at: outputURL)
        #expect(max(size.width, size.height) == 200)
        #expect(mimeType == "image/jpeg")
        #expect(filename.hasPrefix("test-image-device-photo-gps"))
    }

    @Test func imageIsUntouchedWhenProcessingWouldBeNoOp() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = false
        settings.removeLocationSetting = false
        let processor = makeProcessor(settings: settings)
        let url = try fixtureURL("test-image-device-photo-gps.jpg")

        let result = try await processor.processFile(at: url, mimeType: "image/jpeg", filename: url.lastPathComponent)

        guard case .original = result else {
            Issue.record("Expected the original file to pass through")
            return
        }
    }

    @Test func gpsDataIsStrippedWhenRemoveLocationEnabled() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = false
        settings.removeLocationSetting = true
        let processor = makeProcessor(settings: settings)
        let url = try fixtureURL("test-image-device-photo-gps.jpg")

        let result = try await processor.processFile(at: url, mimeType: "image/jpeg", filename: url.lastPathComponent)

        guard case .processed(let outputURL, _, _) = result else {
            Issue.record("Expected a processed file")
            return
        }
        defer { cleanUp(outputURL) }
        #expect(try imageProperties(at: url)[kCGImagePropertyGPSDictionary] != nil)
        #expect(try imageProperties(at: outputURL)[kCGImagePropertyGPSDictionary] == nil)
    }

    @Test func heicIsConvertedToJPEG() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = false
        settings.removeLocationSetting = false
        let processor = makeProcessor(settings: settings)
        let url = try fixtureURL("iphone-photo.heic")

        let result = try await processor.processFile(at: url, mimeType: "image/heic", filename: url.lastPathComponent)

        guard case .processed(let outputURL, let mimeType, let filename) = result else {
            Issue.record("Expected a processed file")
            return
        }
        defer { cleanUp(outputURL) }
        #expect(mimeType == "image/jpeg")
        #expect(filename.hasSuffix(".jpg") || filename.hasSuffix(".jpeg"))
    }

    // MARK: - GIFs and other files

    @Test func gifPassesThroughUntouched() async throws {
        let processor = makeProcessor(settings: makeSettings())
        let url = try fixtureURL("test-gif.gif")

        let result = try await processor.processFile(at: url, mimeType: "image/gif", filename: url.lastPathComponent)

        guard case .original = result else {
            Issue.record("Expected the original file to pass through")
            return
        }
    }

    /// SVG conforms to `UTType.image`, so it reaches the image branch, but
    /// ImageIO cannot decode or encode it. It must pass through untouched
    /// rather than fail in the exporter.
    @Test func svgPassesThroughUntouched() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        settings.removeLocationSetting = true
        let processor = makeProcessor(settings: settings)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).svg")
        try #"<svg xmlns="http://www.w3.org/2000/svg" width="100" height="50"/>"#
            .write(to: url, atomically: true, encoding: .utf8)
        defer { cleanUp(url) }

        let result = try await processor.processFile(
            at: url,
            mimeType: "image/svg+xml",
            filename: url.lastPathComponent
        )

        guard case .original = result else {
            Issue.record("Expected the original file to pass through")
            return
        }
    }

    @Test func disallowedFileExtensionThrows() async throws {
        let processor = GBKMediaUploadProcessor(
            videoDurationLimit: nil,
            allowableFileExtensions: ["pdf"],
            makeMediaSettings: makeSettingsFactory(makeSettings())
        )
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
        try "plain text".write(to: url, atomically: true, encoding: .utf8)
        defer { cleanUp(url) }

        await #expect(throws: MediaURLExporter.URLExportError.self) {
            try await processor.processFile(at: url, mimeType: "text/plain", filename: url.lastPathComponent)
        }
    }

    // MARK: - Videos

    @Test func videoExceedingDurationLimitThrows() async throws {
        let processor = GBKMediaUploadProcessor(
            videoDurationLimit: 1,
            allowableFileExtensions: [],
            makeMediaSettings: makeSettingsFactory(makeSettings())
        )
        let url = try fixtureURL("test-video-device-gps.m4v")

        await #expect(throws: (any Error).self) {
            try await processor.processFile(at: url, mimeType: "video/mp4", filename: url.lastPathComponent)
        }
    }

    // MARK: - Helpers

    private func makeProcessor(settings: MediaSettings) -> GBKMediaUploadProcessor {
        GBKMediaUploadProcessor(
            videoDurationLimit: nil,
            allowableFileExtensions: [],
            makeMediaSettings: makeSettingsFactory(settings)
        )
    }

    private func makeSettings() -> MediaSettings {
        MediaSettings(database: EphemeralKeyValueDatabase())
    }

    private func makeSettingsFactory(_ settings: MediaSettings) -> @Sendable () -> MediaSettings {
        nonisolated(unsafe) let settings = settings
        return { settings }
    }

    private func fixtureURL(_ filename: String) throws -> URL {
        let bundle = Bundle(for: BundleAnchor.self)
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        let url = try #require(bundle.url(forResource: name, withExtension: ext))
        return url
    }

    private func imageProperties(at url: URL) throws -> [CFString: Any] {
        let source = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        return properties
    }

    private func imageSize(at url: URL) throws -> CGSize {
        let properties = try imageProperties(at: url)
        let width = try #require(properties[kCGImagePropertyPixelWidth] as? CGFloat)
        let height = try #require(properties[kCGImagePropertyPixelHeight] as? CGFloat)
        return CGSize(width: width, height: height)
    }

    private func cleanUp(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

/// Anchor for resolving the test bundle from Swift Testing suites.
private final class BundleAnchor {}
