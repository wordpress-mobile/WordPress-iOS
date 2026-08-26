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

    /// Destination names come from a check-then-act `fileExists` loop with no
    /// locking, and GutenbergKit processes uploads concurrently, so concurrent
    /// exports sharing one directory must still resolve to distinct files.
    ///
    /// They do because GutenbergKit writes each upload to `<uuid>-<filename>`
    /// and the exporters name their output after that, so every export name is
    /// already unique before the loop is consulted. The sources here carry that
    /// prefix, as they do in production.
    @Test func concurrentExportsDoNotCollide() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        settings.maxImageSizeSetting = 200
        let processor = makeProcessor(settings: settings)

        let sources = try (0..<8)
            .map { _ in
                try copyFixture("test-image-device-photo-gps.jpg", as: "\(UUID().uuidString)-photo.jpg")
            }
        defer { sources.forEach(cleanUp) }

        let outputURLs = try await withThrowingTaskGroup(of: URL.self) { group in
            for source in sources {
                group.addTask {
                    let result = try await processor.processFile(
                        at: source,
                        mimeType: "image/jpeg",
                        filename: "photo.jpg"
                    )
                    guard case .processed(let outputURL, _, _) = result else {
                        throw ProcessingError.expectedProcessedFile
                    }
                    return outputURL
                }
            }
            return try await group.reduce(into: [URL]()) { $0.append($1) }
        }
        defer { outputURLs.forEach(cleanUp) }

        // Every export is its own file, and every one of them survived the
        // others finishing rather than being overwritten or swept away.
        #expect(Set(outputURLs).count == outputURLs.count)
        for outputURL in outputURLs {
            #expect(FileManager.default.fileExists(atPath: outputURL.path))
            #expect(max(try imageSize(at: outputURL).width, try imageSize(at: outputURL).height) == 200)
        }
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

    /// The editor validates uploads against the site's real `allowedMimeTypes`
    /// before they reach the delegate, so the processor does not second-guess it
    /// with `Blog.allowedFileTypes` — a cached option that can lag the server and
    /// could only reject a file the server would have accepted.
    @Test func documentPassesThroughWhateverTheSiteAllows() async throws {
        let processor = makeProcessor(settings: makeSettings())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
        try "plain text".write(to: url, atomically: true, encoding: .utf8)
        defer { cleanUp(url) }

        let result = try await processor.processFile(
            at: url,
            mimeType: "text/plain",
            filename: url.lastPathComponent
        )

        guard case .original = result else {
            Issue.record("Expected the original file to pass through")
            return
        }
    }

    // MARK: - Files without an extension

    /// GutenbergKit names the temp file after the multipart `filename`, which
    /// the editor does not guarantee carries an extension (its native inserter
    /// derives one from a URL path segment). Such a file resolves to
    /// `public.data`, so the reported MIME type has to stand in for the type.
    @Test func extensionlessImageIsProcessedUsingReportedMIMEType() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        settings.maxImageSizeSetting = 200
        let processor = makeProcessor(settings: settings)
        let url = try copyFixtureDroppingExtension("test-image-device-photo-gps.jpg")
        defer { cleanUp(url) }

        let result = try await processor.processFile(
            at: url,
            mimeType: "image/jpeg",
            filename: url.lastPathComponent
        )

        guard case .processed(let outputURL, let mimeType, _) = result else {
            Issue.record("Expected a processed file")
            return
        }
        defer { cleanUp(outputURL) }
        #expect(mimeType == "image/jpeg")
        #expect(max(try imageSize(at: outputURL).width, try imageSize(at: outputURL).height) == 200)
    }

    /// The fallback only applies when the URL yields no type of its own — a
    /// mismatched MIME type must not override what the file actually is.
    @Test func fileExtensionWinsOverReportedMIMEType() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = false
        settings.removeLocationSetting = false
        let processor = makeProcessor(settings: settings)
        let url = try fixtureURL("test-gif.gif")

        let result = try await processor.processFile(at: url, mimeType: "image/jpeg", filename: url.lastPathComponent)

        // Classified as a GIF from the extension, not as a JPEG from the
        // reported type, so it passes through instead of being re-encoded.
        guard case .original = result else {
            Issue.record("Expected the original file to pass through")
            return
        }
    }

    /// An extension no UTI declares resolves to a *dynamic* type rather than to
    /// `public.data`, so it clears a `!= .data` check while still conforming to
    /// nothing. `.jfif` is a plain JPEG WordPress accepts, and the reported
    /// `image/jpeg` says so, so it has to be processed like any other JPEG
    /// instead of failing the upload outright.
    @Test func undeclaredExtensionIsProcessedUsingReportedMIMEType() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        settings.maxImageSizeSetting = 200
        let processor = makeProcessor(settings: settings)
        let url = try copyFixture("test-image-device-photo-gps.jpg", as: "photo.jfif")
        defer { cleanUp(url) }
        // Guards the premise: if `jfif` ever gains a real declaration this test
        // stops exercising the dynamic-type path.
        #expect(try #require(url.typeIdentifier.flatMap(UTType.init)).isDynamic)

        let result = try await processor.processFile(
            at: url,
            mimeType: "image/jpeg",
            filename: "photo.jfif"
        )

        guard case .processed(let outputURL, let mimeType, _) = result else {
            throw ProcessingError.expectedProcessedFile
        }
        defer { cleanUp(outputURL) }
        #expect(mimeType == "image/jpeg")
        #expect(max(try imageSize(at: outputURL).width, try imageSize(at: outputURL).height) == 200)
    }

    /// `handlesFile` resolves the type from the extension, which is dynamic for
    /// `.jfif` too. It has to discard it the same way, or the file is claimed
    /// (or declined) on a classification `processFile` does not share.
    @Test func undeclaredExtensionIsClaimedFromItsReportedMIMEType() {
        let processor = makeProcessor(settings: makeSettings())
        #expect(processor.handlesFile(ofType: "image/jpeg", named: "photo.jfif"))
        // Nothing decidable from either signal still means claim, so
        // `processFile` gets to read the bytes.
        #expect(processor.handlesFile(ofType: "text/plain", named: "photo.jfif"))
    }

    @Test func extensionlessFileWithUnusableMIMETypeThrows() async throws {
        let processor = makeProcessor(settings: makeSettings())
        let url = try copyFixtureDroppingExtension("test-image-device-photo-gps.jpg")
        defer { cleanUp(url) }

        await #expect(throws: MediaURLExporter.URLExportError.self) {
            try await processor.processFile(at: url, mimeType: "not-a-mime-type", filename: url.lastPathComponent)
        }
    }

    // MARK: - Output naming

    /// GutenbergKit names the temp file it hands over `<uuid>-<filename>`, and
    /// the returned name becomes the attachment's slug and title. The name the
    /// editor sent must survive processing, or the UUID ends up in both.
    @Test func processedFileKeepsTheNameTheEditorSent() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        settings.maxImageSizeSetting = 200
        let processor = makeProcessor(settings: settings)
        let url = try copyFixture("test-image-device-photo-gps.jpg", as: "\(UUID().uuidString)-img_1234.jpg")
        defer { cleanUp(url) }

        let result = try await processor.processFile(at: url, mimeType: "image/jpeg", filename: "IMG_1234.jpg")

        guard case .processed(let outputURL, _, let filename) = result else {
            throw ProcessingError.expectedProcessedFile
        }
        defer { cleanUp(outputURL) }
        // The basename is the editor's, with no trace of the UUID the temp file
        // carried. The extension is the export's — `.jpg` normalizes to the
        // type's preferred `.jpeg` even though the format did not change.
        #expect(filename == "IMG_1234.jpeg")
    }

    /// A conversion changes the bytes, so the extension has to follow them even
    /// though the basename does not.
    @Test func convertedFileKeepsItsNameButTakesTheExportExtension() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        let processor = makeProcessor(settings: settings)
        let url = try fixtureURL("iphone-photo.heic")

        let result = try await processor.processFile(at: url, mimeType: "image/heic", filename: "IMG_1234.HEIC")

        guard case .processed(let outputURL, let mimeType, let filename) = result else {
            throw ProcessingError.expectedProcessedFile
        }
        defer { cleanUp(outputURL) }
        #expect(mimeType == "image/jpeg")
        #expect(filename == "IMG_1234.jpeg")
    }

    // MARK: - handlesFile

    /// The invariant the metadata gate rests on: declining a file must mean
    /// `processFile` would have returned it unchanged. If this fails, the gate
    /// is skipping work that `processFile` would actually have done.
    @Test(arguments: [true, false], [true, false])
    func decliningAFileImpliesProcessFileWouldNotTouchIt(
        optimizationEnabled: Bool,
        removeLocation: Bool
    ) async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = optimizationEnabled
        settings.removeLocationSetting = removeLocation
        settings.maxImageSizeSetting = 200
        let processor = makeProcessor(settings: settings)

        let fixtures: [(filename: String, mimeType: String)] = [
            ("test-image-device-photo-gps.jpg", "image/jpeg"),
            ("iphone-photo.heic", "image/heic"),
            ("test-gif.gif", "image/gif"),
            ("test-video-device-gps.m4v", "video/mp4")
        ]

        for fixture in fixtures {
            guard !processor.handlesFile(ofType: fixture.mimeType, named: fixture.filename) else {
                continue
            }
            let url = try fixtureURL(fixture.filename)
            let result = try await processor.processFile(
                at: url,
                mimeType: fixture.mimeType,
                filename: fixture.filename
            )
            guard case .original = result else {
                Issue.record("Declined \(fixture.filename) but processFile would have processed it")
                return
            }
        }
    }

    @Test func gifIsDeclinedBeforeBeingCopiedToDisk() {
        let processor = makeProcessor(settings: makeSettings())
        #expect(!processor.handlesFile(ofType: "image/gif", named: "animation.gif"))
    }

    /// SVG conforms to `UTType.image`, but ImageIO cannot decode it, so
    /// `processFile` returns it unchanged for any settings. Claiming it would
    /// buy a full temp-file copy that is handed straight back.
    @Test func svgIsDeclinedBeforeBeingCopiedToDisk() {
        let processor = makeProcessor(settings: makeSettings())
        #expect(!processor.handlesFile(ofType: "image/svg+xml", named: "logo.svg"))
        #expect(!processor.handlesFile(ofType: "text/plain", named: "logo.svg"))
    }

    @Test func imagesAndVideosAreAlwaysClaimed() {
        let processor = makeProcessor(settings: makeSettings())
        #expect(processor.handlesFile(ofType: "image/jpeg", named: "photo.jpg"))
        #expect(processor.handlesFile(ofType: "image/heic", named: "photo.heic"))
        #expect(processor.handlesFile(ofType: "video/mp4", named: "clip.mp4"))
    }

    /// `processFile` returns every document unchanged, so claiming one would
    /// only spend a full temp-file copy to hand it straight back.
    @Test func documentsAreDeclinedBeforeBeingCopiedToDisk() {
        let processor = makeProcessor(settings: makeSettings())
        #expect(!processor.handlesFile(ofType: "application/pdf", named: "doc.pdf"))
        #expect(!processor.handlesFile(ofType: "text/csv", named: "data.csv"))
    }

    /// A part with no `Content-Type` arrives as `text/plain`, and a real
    /// `Content-Type` may carry parameters or arbitrary casing. None of those
    /// may cause a photo to be mistaken for a document and declined.
    @Test(
        arguments: [
            "image/jpeg; charset=binary",
            "IMAGE/JPEG",
            "text/plain",
            "application/octet-stream",
            ""
        ]
    )
    func imagesAreClaimedWhateverTheReportedMIMEType(mimeType: String) {
        let processor = makeProcessor(settings: makeSettings())
        #expect(processor.handlesFile(ofType: mimeType, named: "photo.jpg"))
    }

    /// Nothing decidable from the metadata means the file is claimed, so
    /// `processFile` can read the type off the bytes instead.
    @Test func unrecognizableMetadataIsClaimed() {
        let processor = makeProcessor(settings: makeSettings())
        #expect(processor.handlesFile(ofType: "text/plain", named: "upload"))
    }

    /// `handlesFile` must resolve the type the way `processFile` does — the
    /// extension first — or a mislabeled `Content-Type` silently declines a
    /// photo that would have been downscaled and stripped. Declining is
    /// unrecoverable, so the two cannot disagree.
    @Test func mislabeledContentTypeDoesNotDeclineAnImage() async throws {
        let settings = makeSettings()
        settings.imageOptimizationEnabled = true
        settings.removeLocationSetting = true
        settings.maxImageSizeSetting = 200
        let processor = makeProcessor(settings: settings)

        #expect(processor.handlesFile(ofType: "application/pdf", named: "photo.jpg"))

        // And the claim is warranted: `processFile` really does process it.
        let url = try fixtureURL("test-image-device-photo-gps.jpg")
        let result = try await processor.processFile(at: url, mimeType: "application/pdf", filename: "photo.jpg")
        guard case .processed(let outputURL, _, _) = result else {
            throw ProcessingError.expectedProcessedFile
        }
        cleanUp(outputURL)
    }

    // MARK: - Videos

    @Test func videoExceedingDurationLimitThrows() async throws {
        let processor = GBKMediaUploadProcessor(
            videoDurationLimit: 1,
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

    /// Copies a fixture to a temporary file under a different name, mirroring
    /// the `<uuid>-<filename>` temp file GutenbergKit hands to `processFile`.
    private func copyFixture(_ filename: String, as destinationName: String) throws -> URL {
        let source = try fixtureURL(filename)
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent(destinationName, isDirectory: false)
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    /// Copies a fixture to a temporary file with no path extension, mirroring
    /// an upload whose multipart `filename` carried none.
    private func copyFixtureDroppingExtension(_ filename: String) throws -> URL {
        let source = try fixtureURL(filename)
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
        try FileManager.default.copyItem(at: source, to: destination)
        #expect(destination.pathExtension.isEmpty)
        return destination
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

    private enum ProcessingError: Error {
        case expectedProcessedFile
    }
}

/// Anchor for resolving the test bundle from Swift Testing suites.
private final class BundleAnchor {}
