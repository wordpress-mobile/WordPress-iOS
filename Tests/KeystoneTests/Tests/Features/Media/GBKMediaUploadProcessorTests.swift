import Foundation
import GutenbergKit
import ImageIO
import Testing
import UniformTypeIdentifiers
import WordPressData
import WordPressShared

@testable import WordPress

struct GBKMediaUploadProcessorTests {

    /// Where this test's processor clones sources, so tests can check it's
    /// left empty without seeing other tests' files.
    private let sourceDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("GBKMediaUploadProcessorTests-\(UUID().uuidString)", isDirectory: true)

    // MARK: - Images

    @Test func imageIsResizedWhenOptimizationEnabled() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        settings.maxImageSizeSetting = 200
        let processor = makeProcessor(settings: settings)
        let url = try stageFixture("test-image-device-photo-gps.jpg")

        let result = try await processor.processFile(at: url, mimeType: "image/jpeg", filename: url.lastPathComponent)

        let output = try processedFile(result)
        defer { cleanUp(output.url) }
        #expect(max(try imageSize(at: output.url).width, try imageSize(at: output.url).height) == 200)
        #expect(output.mimeType == "image/jpeg")
        #expect(output.filename == "test-image-device-photo-gps.jpg")
    }

    @Test func imageIsUntouchedWhenProcessingWouldBeNoOp() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = false
        settings.removeLocationSetting = false
        let processor = makeProcessor(settings: settings)
        let url = try stageFixture("test-image-device-photo-gps.jpg")

        let result = try await processor.processFile(at: url, mimeType: "image/jpeg", filename: url.lastPathComponent)

        try expectOriginal(result)
    }

    @Test func gpsDataIsStrippedWhenRemoveLocationEnabled() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = false
        settings.removeLocationSetting = true
        let processor = makeProcessor(settings: settings)
        let url = try stageFixture("test-image-device-photo-gps.jpg")

        let result = try await processor.processFile(at: url, mimeType: "image/jpeg", filename: url.lastPathComponent)

        let output = try processedFile(result)
        defer { cleanUp(output.url) }
        #expect(try imageProperties(at: url)[kCGImagePropertyGPSDictionary] != nil)
        #expect(try imageProperties(at: output.url)[kCGImagePropertyGPSDictionary] == nil)
    }

    /// A conversion changes the bytes, so the extension follows them while the
    /// editor's basename is kept.
    @Test func heicIsConvertedToJPEG() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = false
        settings.removeLocationSetting = false
        let processor = makeProcessor(settings: settings)
        let url = try stageFixture("iphone-photo.heic", as: "IMG_1234.HEIC")

        let result = try await processor.processFile(at: url, mimeType: "image/heic", filename: "IMG_1234.HEIC")

        let output = try processedFile(result)
        defer { cleanUp(output.url) }
        #expect(output.mimeType == "image/jpeg")
        #expect(output.filename == "IMG_1234.jpg")
    }

    /// GutenbergKit stages each upload under the editor's filename, in a
    /// directory per upload, and processes uploads concurrently. The exporters
    /// pick output names with an unlocked check-then-act loop, so same-named
    /// uploads must still produce distinct files.
    @Test func concurrentSameNamedUploadsDoNotCollide() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        settings.maxImageSizeSetting = 200
        let processor = makeProcessor(settings: settings)
        let sources = try (0..<8).map { _ in try stageFixture("test-image-device-photo-gps.jpg", as: "photo.jpg") }

        let outputURLs = try await withThrowingTaskGroup(of: URL.self) { group in
            for source in sources {
                group.addTask {
                    let result = try await processor.processFile(
                        at: source,
                        mimeType: "image/jpeg",
                        filename: "photo.jpg"
                    )
                    guard case .processed(let url, _, _) = result else {
                        throw ProcessingError.expectedProcessedFile
                    }
                    return url
                }
            }
            return try await group.reduce(into: [URL]()) { $0.append($1) }
        }
        defer { outputURLs.forEach(cleanUp) }

        #expect(Set(outputURLs).count == outputURLs.count)
        for url in outputURLs {
            #expect(max(try imageSize(at: url).width, try imageSize(at: url).height) == 200)
        }
    }

    /// `MediaImageExporter` writes the decoded type, not the claimed one, and
    /// some types ImageIO writes have no MIME type (e.g. PBM, KTX).
    @Test func exportIsRemovedWhenItsMIMETypeIsUnknown() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        let exportDirectoryID = UUID()
        let processor = GBKMediaUploadProcessor(
            makeMediaSettings: makeSettingsFactory(settings),
            exportDirectoryID: exportDirectoryID,
            sourceDirectory: sourceDirectory
        )
        let url = try stageImageWithoutMIMEType(as: "photo.png")

        await #expect(throws: MediaURLExporter.URLExportError.unknownFileUTI) {
            try await processor.processFile(at: url, mimeType: "image/png", filename: "photo.png")
        }
        let exportDirectory = MediaDirectory.temporary(id: exportDirectoryID).url
        let exports = (try? FileManager.default.contentsOfDirectory(atPath: exportDirectory.path)) ?? []
        #expect(exports.isEmpty)
    }

    @Test func clonedSourceIsRemovedAfterExport() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        let processor = makeProcessor(settings: settings)
        let url = try stageFixture("test-image-device-photo-gps.jpg")

        let result = try await processor.processFile(at: url, mimeType: "image/jpeg", filename: url.lastPathComponent)

        let output = try processedFile(result)
        defer { cleanUp(output.url) }
        let remaining = try FileManager.default.contentsOfDirectory(atPath: sourceDirectory.path)
        #expect(remaining.isEmpty)
        // The staged file belongs to GutenbergKit and is left alone.
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    // MARK: - GIFs, SVGs, and other files

    @Test func gifPassesThroughUntouched() async throws {
        let processor = makeProcessor(settings: makeSettings())
        let url = try stageFixture("test-gif.gif")

        let result = try await processor.processFile(at: url, mimeType: "image/gif", filename: url.lastPathComponent)

        try expectOriginal(result)
    }

    /// SVG conforms to `UTType.image`, but ImageIO can't decode or encode it.
    @Test func svgPassesThroughUntouched() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        settings.removeLocationSetting = true
        let processor = makeProcessor(settings: settings)
        let url = try stage(#"<svg xmlns="http://www.w3.org/2000/svg" width="100" height="50"/>"#, as: "logo.svg")

        let result = try await processor.processFile(at: url, mimeType: "image/svg+xml", filename: "logo.svg")

        try expectOriginal(result)
    }

    /// The editor validates uploads against the site's allowed types, so the
    /// processor doesn't second-guess it with `Blog.allowedFileTypes`.
    @Test func documentPassesThroughUntouched() async throws {
        let processor = makeProcessor(settings: makeSettings())
        let url = try stage("plain text", as: "notes.txt")

        let result = try await processor.processFile(at: url, mimeType: "text/plain", filename: "notes.txt")

        try expectOriginal(result)
    }

    // MARK: - Type resolution

    /// The editor doesn't guarantee a filename carries an extension, so the
    /// reported MIME type stands in, whatever its parameters or casing.
    @Test(arguments: ["image/jpeg", "IMAGE/JPEG", "image/jpeg; charset=binary"])
    func extensionlessImageIsProcessedUsingReportedMIMEType(mimeType: String) async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        settings.maxImageSizeSetting = 200
        let processor = makeProcessor(settings: settings)
        let url = try stageFixture("test-image-device-photo-gps.jpg", as: "photo")

        let result = try await processor.processFile(at: url, mimeType: mimeType, filename: "photo")

        let output = try processedFile(result)
        defer { cleanUp(output.url) }
        #expect(output.mimeType == "image/jpeg")
        #expect(output.filename == "photo.jpg")
        #expect(max(try imageSize(at: output.url).width, try imageSize(at: output.url).height) == 200)
    }

    /// A mismatched MIME type must not override what the extension says.
    @Test func fileExtensionWinsOverReportedMIMEType() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = false
        settings.removeLocationSetting = false
        let processor = makeProcessor(settings: settings)
        let url = try stageFixture("test-gif.gif")

        // Classified as a GIF, not a JPEG, so it passes through.
        let result = try await processor.processFile(at: url, mimeType: "image/jpeg", filename: url.lastPathComponent)

        try expectOriginal(result)
    }

    /// An extension no UTI declares resolves to a dynamic type that conforms
    /// to nothing. `.jfif` is a plain JPEG, and the reported type says so.
    @Test func undeclaredExtensionIsProcessedUsingReportedMIMEType() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        settings.maxImageSizeSetting = 200
        let processor = makeProcessor(settings: settings)
        let url = try stageFixture("test-image-device-photo-gps.jpg", as: "photo.jfif")
        // Guards the premise: if `jfif` gains a declaration, this test no
        // longer covers dynamic types.
        #expect(try #require(url.typeIdentifier.flatMap(UTType.init)).isDynamic)

        let result = try await processor.processFile(at: url, mimeType: "image/jpeg", filename: "photo.jfif")

        let output = try processedFile(result)
        defer { cleanUp(output.url) }
        #expect(output.mimeType == "image/jpeg")
        #expect(max(try imageSize(at: output.url).width, try imageSize(at: output.url).height) == 200)
    }

    /// `application/octet-stream` is what the editor sends when the browser
    /// doesn't know a file's type, so it can't stand in for a missing extension.
    @Test(arguments: ["application/octet-stream", "", "not-a-mime-type"])
    func extensionlessFileWithUnusableMIMETypePassesThroughUntouched(mimeType: String) async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        let processor = makeProcessor(settings: settings)
        let url = try stageFixture("test-image-device-photo-gps.jpg", as: "upload")

        let result = try await processor.processFile(at: url, mimeType: mimeType, filename: "upload")

        try expectOriginal(result)
    }

    /// WordPress accepts types that are neither media nor `UTType.content`
    /// (e.g. tar, 7z), or that no UTI declares (e.g. rar, woff2).
    @Test(arguments: [
        ("backup.tar", "application/x-tar"),
        ("backup.tar.gz", "application/gzip"),
        ("archive.7z", "application/x-7z-compressed"),
        ("archive.rar", "application/vnd.rar"),
        ("font.ttf", "font/ttf"),
        ("font.woff2", "font/woff2")
    ])
    func unclassifiedFilePassesThroughUntouched(filename: String, mimeType: String) async throws {
        let processor = makeProcessor(settings: makeSettings())
        let url = try stage("not processed", as: filename)

        let result = try await processor.processFile(at: url, mimeType: mimeType, filename: filename)

        try expectOriginal(result)
    }

    // MARK: - Videos

    @Test func videoIsExported() async throws {
        let processor = makeProcessor(settings: makeSettings())
        let url = try stageFixture("test-video-device-gps.m4v", as: "clip.m4v")

        let result = try await processor.processFile(at: url, mimeType: "video/mp4", filename: "clip.m4v")

        let output = try processedFile(result)
        defer { cleanUp(output.url) }
        #expect(output.mimeType == "video/mp4")
        #expect(output.filename == "clip.mp4")
    }

    /// WebM and WMV conform to `UTType.movie`, but AVFoundation can't open
    /// either, and `MediaVideoExporter` would fail uploads WordPress accepts.
    @Test(arguments: [("clip.webm", "video/webm"), ("clip.wmv", "video/x-ms-wmv")])
    func videoAVFoundationCannotReadPassesThroughUntouched(filename: String, mimeType: String) async throws {
        let processor = makeProcessor(settings: makeSettings())
        // Never read: the type alone decides.
        let url = try stageFixture("test-video-device-gps.m4v", as: filename)

        let result = try await processor.processFile(at: url, mimeType: mimeType, filename: filename)

        try expectOriginal(result)
    }

    // MARK: - Cancellation

    /// GutenbergKit cancels the task when the editor goes away or the page
    /// abandons the upload, and nothing reads the result after that.
    @Test func cancelledUploadIsNotExported() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        let processor = makeProcessor(settings: settings)
        let url = try stageFixture("test-image-device-photo-gps.jpg")

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await processor.processFile(at: url, mimeType: "image/jpeg", filename: url.lastPathComponent)
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        // Cancelled before the source was cloned for export.
        let clones = (try? FileManager.default.contentsOfDirectory(atPath: sourceDirectory.path)) ?? []
        #expect(clones.isEmpty)
    }

    // MARK: - Helpers

    /// Returns the processor as GutenbergKit sees it. A witness whose labels
    /// don't match resolves to the protocol's no-op default instead of
    /// failing to build, and calling through the protocol catches that.
    private func makeProcessor(settings: MediaSettings) -> any MediaProcessor {
        GBKMediaUploadProcessor(
            makeMediaSettings: makeSettingsFactory(settings),
            sourceDirectory: sourceDirectory
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
        return try #require(bundle.url(forResource: name, withExtension: ext))
    }

    /// Copies a fixture to `<uuid>/<name>`, the way GutenbergKit stages an
    /// upload under the editor's filename in a directory per upload.
    private func stageFixture(_ filename: String, as name: String? = nil) throws -> URL {
        let destination = try makeStagingURL(name ?? filename)
        try FileManager.default.copyItem(at: try fixtureURL(filename), to: destination)
        return destination
    }

    /// Re-encodes a fixture in a type ImageIO can write that has an extension
    /// but no MIME type.
    private func stageImageWithoutMIMEType(as name: String) throws -> URL {
        let writableTypes = Set((CGImageDestinationCopyTypeIdentifiers() as? [String]) ?? [])
        let type = try #require(
            ["public.pbm", "org.khronos.ktx", "com.ilm.openexr-image"]
                .filter(writableTypes.contains)
                .compactMap(UTType.init)
                .first { $0.preferredMIMEType == nil && $0.preferredFilenameExtension != nil }
        )
        let source = try #require(
            CGImageSourceCreateWithURL(try fixtureURL("test-image-device-photo-gps.jpg") as CFURL, nil)
        )
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let destinationURL = try makeStagingURL(name)
        let destination = try #require(
            CGImageDestinationCreateWithURL(destinationURL as CFURL, type.identifier as CFString, 1, nil)
        )
        CGImageDestinationAddImage(destination, image, nil)
        try #require(CGImageDestinationFinalize(destination))
        return destinationURL
    }

    private func stage(_ contents: String, as name: String) throws -> URL {
        let destination = try makeStagingURL(name)
        try contents.write(to: destination, atomically: true, encoding: .utf8)
        return destination
    }

    private func makeStagingURL(_ name: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GBKMediaUploadProcessorTests-staging", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(name, isDirectory: false)
    }

    private func processedFile(_ result: ProcessedProxyFile) throws -> (url: URL, mimeType: String, filename: String) {
        guard case .processed(let url, let mimeType, let filename) = result else {
            throw ProcessingError.expectedProcessedFile
        }
        return (url, mimeType, filename)
    }

    private func expectOriginal(_ result: ProcessedProxyFile) throws {
        guard case .original = result else {
            throw ProcessingError.expectedOriginal
        }
    }

    private func imageProperties(at url: URL) throws -> [CFString: Any] {
        let source = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
        return try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
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

    private enum ProcessingError: Error {
        case expectedProcessedFile
        case expectedOriginal
    }
}

/// Anchor for resolving the test bundle from Swift Testing suites.
private final class BundleAnchor {}
