import AVFoundation
import Foundation
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import WordPressMediaLibrary

/// Fresh stage progress for materializer tests that don't care about
/// the value — matches what the actor would allocate in production.
private func stage() -> Progress { Progress(totalUnitCount: 100) }

/// Expects `body` to throw the given `MaterializerError` case. Compares by
/// case name, so only use it with payload-free cases.
private func expectThrowsCase<R>(
    _ expected: MaterializerError,
    sourceLocation: SourceLocation = #_sourceLocation,
    performing body: () async throws -> R
) async {
    let error = await #expect(throws: MaterializerError.self, sourceLocation: sourceLocation) {
        _ = try await body()
    }
    guard let error else { return } // the #expect above already recorded the failure
    #expect(
        String(describing: error) == String(describing: expected),
        sourceLocation: sourceLocation
    )
}

@Suite("UploadSourceMaterializer")
final class UploadSourceMaterializerTests {
    /// Per-test root for fixtures and staging output, so tests never write
    /// into the production staging directory and need no per-result cleanup.
    private let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    private func policy(
        allow: @escaping @Sendable (UTType, String) -> Bool = { _, _ in true },
        imageMaxDimension: Int? = nil,
        videoMaxDurationSeconds: TimeInterval? = nil,
        stripGPSLocation: Bool = false
    ) -> MediaUploadPolicy {
        MediaUploadPolicy(
            filePickerContentTypes: [.content],
            isAllowedForUpload: allow,
            imageMaxDimension: imageMaxDimension,
            imageJpegQuality: 0.9,
            convertHEICToJPEG: true,
            videoMaxDurationSeconds: videoMaxDurationSeconds,
            videoExportPreset: AVAssetExportPresetMediumQuality,
            videoOutputContentType: .mpeg4Movie,
            stripGPSLocation: stripGPSLocation
        )
    }

    @Test("file source: validator rejection surfaces disallowedContentType")
    func validatorRejectsDocument() async throws {
        let tempURL = try createTempPDF()
        let m = makeMaterializer(policy(allow: { _, _ in false }))
        await expectThrowsCase(.disallowedContentType) {
            try await m.materialize(source: .file(tempURL), into: stage())
        }
    }

    @Test("file source preserves original basename verbatim")
    func fileSourcePreservesBasename() async throws {
        let tempURL = try createTempPDF(name: "Quarterly Report.pdf")
        let m = makeMaterializer(policy())
        let result = try await m.materialize(source: .file(tempURL), into: stage())
        #expect(result.displayName == "Quarterly Report.pdf")
    }

    @Test("materialization failures remove their parent temp directory")
    func failureRemovesTempDir() async throws {
        let tempURL = try createTempPDF()
        let inspectableRoot = try makeTempDir()

        let m = makeMaterializer(policy(allow: { _, _ in false }), temporaryRoot: inspectableRoot)
        await expectThrowsCase(.disallowedContentType) {
            try await m.materialize(source: .file(tempURL), into: stage())
        }

        let contents = try FileManager.default.contentsOfDirectory(
            at: inspectableRoot,
            includingPropertiesForKeys: nil
        )
        #expect(contents.isEmpty)
    }

    @Test("camera image yields a timestamped IMG JPEG")
    func cameraImageBasename() async throws {
        let image = makeSolidColorImage(size: CGSize(width: 10, height: 10), color: .red)

        let m = makeMaterializer(policy())
        let result = try await m.materialize(source: .cameraImage(image, capturedAt: Date()), into: stage())

        #expect(result.displayName.hasPrefix("IMG"))
        #expect(result.displayName.hasSuffix(".jpeg"))
        #expect(result.kind == .image)
        #expect(FileManager.default.fileExists(atPath: result.tempFileURL.path))
    }

    @Test(".file JPEG with GPS: stripGPSLocation removes GPS")
    func fileJPEGStripsGPS() async throws {
        // Build a JPEG with a synthetic GPS dict embedded and run it through
        // the file-source path, which exercises stripGPS on raw JPEG bytes.
        let sourceURL = try writeTempFixture(makeJPEGWithGPSAndDate(), ext: "jpg")

        let m = makeMaterializer(policy(stripGPSLocation: true))
        let result = try await m.materialize(source: .file(sourceURL), into: stage())

        #expect(!imageHasGPS(result.tempFileURL))
    }

    @Test("camera video over duration is rejected")
    func cameraVideoOverDuration() async throws {
        let videoURL = try await sharedBlankVideoTask.value
        let m = makeMaterializer(policy(videoMaxDurationSeconds: 0.5))
        await expectThrowsCase(.durationCapExceeded) {
            try await m.materialize(source: .cameraVideo(videoURL, capturedAt: Date()), into: stage())
        }
    }

    @Test("camera video exports to .mp4 by default")
    func cameraVideoExportsToMP4() async throws {
        let videoURL = try await sharedBlankVideoTask.value
        let m = makeMaterializer(policy())
        let result = try await m.materialize(source: .cameraVideo(videoURL, capturedAt: Date()), into: stage())

        #expect(result.displayName.hasSuffix(".mp4"))
        #expect(result.kind == .video)
        #expect(FileManager.default.fileExists(atPath: result.tempFileURL.path))
    }

    @Test(".file HEIC under policy that rejects HEIC but allows JPEG succeeds")
    func fileHEICConvertedToJPEG() async throws {
        let sourceURL = try writeTempFixture(makeSyntheticHEIC(), ext: "heic")

        let m = makeMaterializer(
            policy(allow: { type, ext in
                // Reject HEIC, allow JPEG
                !(type == .heic || ext == "heic")
            })
        )
        let result = try await m.materialize(source: .file(sourceURL), into: stage())

        #expect(result.displayName.hasSuffix(".jpeg"))
        #expect(imageType(of: result.tempFileURL) == .jpeg)
        #expect(result.kind == .image)
    }

    /// Regression: HEIC→JPEG conversion decodes the raw stored pixels without
    /// applying the EXIF transform, so the orientation tag must survive the
    /// conversion. Dropping it left a 180°-oriented HEIC rendering upside down.
    @Test("HEIC→JPEG conversion preserves EXIF orientation")
    func heicToJPEGPreservesOrientation() async throws {
        let heicData = try makeSyntheticHEIC(orientation: .down) // 3 == 180°
        let sourceURL = try writeTempFixture(heicData, ext: "heic")

        let m = makeMaterializer(policy())
        let result = try await m.materialize(source: .file(sourceURL), into: stage())

        let props = try imageProperties(of: result.tempFileURL)
        let orientation = props[kCGImagePropertyOrientation] as? UInt32
        #expect(orientation == CGImagePropertyOrientation.down.rawValue)
    }

    @Test(".file video with duration cap exceeded is rejected")
    func fileVideoOverDuration() async throws {
        let videoURL = try await sharedBlankVideoTask.value
        let m = makeMaterializer(policy(videoMaxDurationSeconds: 0.01))
        await expectThrowsCase(.durationCapExceeded) {
            try await m.materialize(source: .file(videoURL), into: stage())
        }
    }

    @Test(".file video re-exports to .mp4")
    func fileVideoReexportsToMP4() async throws {
        let videoURL = try await sharedBlankVideoTask.value
        let m = makeMaterializer(policy())
        let result = try await m.materialize(source: .file(videoURL), into: stage())

        #expect(result.displayName.hasSuffix(".mp4"))
        #expect(result.kind == .video)
    }

    @Test(".file GIF passes through raw-copied")
    func fileGIFRawCopy() async throws {
        let gifURL = try createTempGIF()

        let m = makeMaterializer(policy())
        let result = try await m.materialize(source: .file(gifURL), into: stage())

        #expect(result.displayName.hasSuffix(".gif"))
        #expect(result.kind == .image)
        // Byte-for-byte copy: any ImageIO round-trip would alter the bytes.
        #expect(try Data(contentsOf: result.tempFileURL) == gifFixture)
    }

    @Test(".file PDF passes through raw-copied")
    func filePDFRawCopy() async throws {
        let pdfURL = try createTempPDF()

        let m = makeMaterializer(policy())
        let result = try await m.materialize(source: .file(pdfURL), into: stage())

        #expect(result.displayName.hasSuffix(".pdf"))
        #expect(result.kind == .document)
    }

    @Test(".photoLibrary GIF passes through raw-copied")
    func photoLibraryGIFRawCopy() async throws {
        let gifURL = try createTempGIF()

        // Resize + GPS-strip both enabled — the bug class this guards
        // against is ImageIO flattening animated GIFs when either is on.
        let m = makeMaterializer(policy(imageMaxDimension: 1024, stripGPSLocation: true))
        let result = try await m.materialize(
            source: .photoLibrary(
                itemProvider: makeGIFItemProvider(vendingFile: gifURL),
                suggestedName: "Animation",
                hint: .gif
            ),
            into: stage()
        )

        #expect(result.displayName.hasSuffix(".gif"))
        #expect(result.kind == .image)
        // Byte-for-byte copy: any ImageIO round-trip would alter the
        // bytes even if the file size happened to match.
        #expect(try Data(contentsOf: result.tempFileURL) == gifFixture)
    }

    @Test(".photoLibrary GIF: validator rejection surfaces disallowedContentType")
    func photoLibraryGIFRejected() async throws {
        let gifURL = try createTempGIF()

        let m = makeMaterializer(policy(allow: { _, ext in ext != "gif" }))
        await expectThrowsCase(.disallowedContentType) {
            try await m.materialize(
                source: .photoLibrary(
                    itemProvider: makeGIFItemProvider(vendingFile: gifURL),
                    suggestedName: "Animation",
                    hint: .gif
                ),
                into: stage()
            )
        }
    }

    @Test("camera image: imageMaxDimension resizes before GPS strip")
    func cameraImageResized() async throws {
        // 2000×2000 image, cap at 1024 — output pixel long edge must be <= 1024.
        let image = makeSolidColorImage(size: CGSize(width: 2000, height: 2000), color: .blue)

        let m = makeMaterializer(policy(imageMaxDimension: 1024, stripGPSLocation: true))
        let result = try await m.materialize(source: .cameraImage(image, capturedAt: Date()), into: stage())

        let props = try imageProperties(of: result.tempFileURL)
        let width = try #require(props[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(props[kCGImagePropertyPixelHeight] as? Int)
        #expect(max(width, height) <= 1024)
    }

    @Test("image already within imageMaxDimension is not re-encoded")
    func imageWithinMaxDimensionPassesThrough() async throws {
        // 50×50 JPEG under a 1024 cap: resizing would only re-encode it lossily
        // at the same size, so the materialized bytes must equal the input.
        let smallJPEG = try encodeImage(
            makeSolidColorImage(size: CGSize(width: 50, height: 50), color: .red),
            as: .jpeg
        )
        let sourceURL = try writeTempFixture(smallJPEG, ext: "jpg")

        let m = makeMaterializer(policy(imageMaxDimension: 1024))
        let result = try await m.materialize(source: .file(sourceURL), into: stage())

        // Byte-for-byte equality: any ImageIO re-encode would alter the bytes.
        #expect(try Data(contentsOf: result.tempFileURL) == smallJPEG)
    }

    @Test(".imagePlayground applies the image policy without security scoping")
    func imagePlaygroundAppliesImagePolicy() async throws {
        // Plant a HEIC where Image Playground would have written its output;
        // the image policy must convert it like any other picked image.
        let imageURL = try makeTempDir().appendingPathComponent("Generated.heic")
        try makeSyntheticHEIC().write(to: imageURL)

        let result = try await makeMaterializer(policy())
            .materialize(
                source: .imagePlayground(imageURL, suggestedName: "Generated"),
                into: stage()
            )

        #expect(result.kind == .image)
        #expect(result.displayName == "Generated.jpeg")
        #expect(imageType(of: result.tempFileURL) == .jpeg)
    }

    // MARK: - .remoteURL post-download dispatch

    @Test("remote dispatch: GIF passthrough preserves bytes")
    func remoteDispatchGIFPassthroughPreservesBytes() async throws {
        let parentDir = try makeTempDir()
        let sourceGIF = parentDir.appendingPathComponent("download.tmp")
        try gifFixture.write(to: sourceGIF)

        let result = try await makeMaterializer(policy())
            .dispatchRemoteDownload(
                localFile: sourceGIF,
                contentType: .gif,
                suggestedName: "happy-cat",
                caption: nil,
                parentDir: parentDir
            )

        #expect(try Data(contentsOf: result.tempFileURL) == gifFixture) // byte-equal: animation preserved
        // Display name includes the .gif extension, matching the contract
        // applied uniformly across materializer branches.
        #expect(result.displayName == "happy-cat.gif")
        #expect(result.params.filePath == result.tempFileURL.path)
    }

    @Test("remote dispatch passes the caption through", arguments: [UTType.gif, .jpeg])
    func remoteDispatchPassesCaptionThrough(contentType: UTType) async throws {
        let parentDir = try makeTempDir()
        let sourceFile = parentDir.appendingPathComponent("download.tmp")
        let bytes =
            contentType == .gif
            ? gifFixture
            : try encodeImage(makeSolidColorImage(size: CGSize(width: 10, height: 10), color: .red), as: .jpeg)
        try bytes.write(to: sourceFile)

        let result = try await makeMaterializer(policy())
            .dispatchRemoteDownload(
                localFile: sourceFile,
                contentType: contentType,
                suggestedName: "g",
                caption: "Photo by Foo",
                parentDir: parentDir
            )
        #expect(result.params.caption == "Photo by Foo")
    }

    @Test("remote dispatch rejects non-image, non-GIF content types")
    func remoteDispatchRejectsNonImageNonGifContentType() async throws {
        let parentDir = try makeTempDir()
        let sourceFile = parentDir.appendingPathComponent("vid.tmp")
        try Data([0x00]).write(to: sourceFile)

        let m = makeMaterializer(policy())
        await expectThrowsCase(.disallowedContentType) {
            try await m.dispatchRemoteDownload(
                localFile: sourceFile,
                contentType: .movie,
                suggestedName: "x",
                caption: nil,
                parentDir: parentDir
            )
        }
    }

    @Test(
        "remote dispatch keeps output inside parentDir for a traversing suggestedName",
        arguments: [UTType.jpeg, .gif]
    )
    func remoteDispatchContainsTraversingName(contentType: UTType) async throws {
        let parentDir = try makeTempDir()
        let sourceFile = parentDir.appendingPathComponent("download.tmp")
        let bytes =
            contentType == .gif
            ? gifFixture
            : try encodeImage(makeSolidColorImage(size: CGSize(width: 10, height: 10), color: .red), as: .jpeg)
        try bytes.write(to: sourceFile)

        // `.gif` exercises the passthrough `moveItem` branch; `.jpeg` the
        // `finalizeImage` write branch. Both build the destination from the
        // untrusted suggested name via `appendingPathComponent`.
        let result = try await makeMaterializer(policy())
            .dispatchRemoteDownload(
                localFile: sourceFile,
                contentType: contentType,
                suggestedName: "../escaped",
                caption: nil,
                parentDir: parentDir
            )

        let parent = parentDir.standardizedFileURL.path
        // The finalized file must stay INSIDE parentDir: sanitizing the name
        // neutralizes the `..` before it reaches `appendingPathComponent`.
        #expect(
            result.tempFileURL.standardizedFileURL.path.hasPrefix(parent + "/"),
            "materialized file escaped parentDir: \(result.tempFileURL.standardizedFileURL.path)"
        )
        // The documented cleanup target must be parentDir itself, never its
        // parent, so deleting it can't wipe sibling uploads in the staging root.
        #expect(result.stagingDirectory.standardizedFileURL.path == parent)
    }

    @Test("remote dispatch image branch rejects non-image bytes")
    func remoteDispatchImageBranchRejectsNonImageBytes() async throws {
        let parentDir = try makeTempDir()
        let sourceFile = parentDir.appendingPathComponent("a.tmp")
        try Data("<html><body>404 Not Found</body></html>".utf8).write(to: sourceFile)

        let m = makeMaterializer(policy())
        await expectThrowsCase(.invalidImageData) {
            try await m.dispatchRemoteDownload(
                localFile: sourceFile,
                contentType: .jpeg,
                suggestedName: "x",
                caption: nil,
                parentDir: parentDir
            )
        }
    }

    // MARK: - Raw passthrough (GIF/SVG)

    @Test(".file SVG passes through raw-copied")
    func fileSVGRawCopy() async throws {
        let url = try writeTempFixture(svgFixture, name: "art.svg")

        let m = makeMaterializer(policy())
        let result = try await m.materialize(source: .file(url), into: stage())

        #expect(result.displayName == "art.svg")
        #expect(result.kind == .image)
        #expect(try Data(contentsOf: result.tempFileURL) == svgFixture)
    }

    @Test("remote dispatch: SVG passthrough preserves bytes")
    func remoteDispatchSVGPassthroughPreservesBytes() async throws {
        let parentDir = try makeTempDir()
        let sourceSVG = parentDir.appendingPathComponent("download.tmp")
        try svgFixture.write(to: sourceSVG)

        let result = try await makeMaterializer(policy())
            .dispatchRemoteDownload(
                localFile: sourceSVG,
                contentType: .svg,
                suggestedName: "vector-art",
                caption: nil,
                parentDir: parentDir
            )

        #expect(result.displayName == "vector-art.svg")
        #expect(result.kind == .image)
        #expect(try Data(contentsOf: result.tempFileURL) == svgFixture)
    }

    @Test("remote dispatch: SVG policy rejection surfaces disallowedContentType")
    func remoteDispatchSVGPolicyRejectionSurfacesDisallowed() async throws {
        let parentDir = try makeTempDir()
        let sourceSVG = parentDir.appendingPathComponent("download.tmp")
        try svgFixture.write(to: sourceSVG)

        let m = makeMaterializer(policy(allow: { _, ext in ext != "svg" }))
        await expectThrowsCase(.disallowedContentType) {
            try await m.dispatchRemoteDownload(
                localFile: sourceSVG,
                contentType: .svg,
                suggestedName: "vector-art",
                caption: nil,
                parentDir: parentDir
            )
        }
    }

    // MARK: - Single-pass transform

    @Test(".file with non-image bytes in a .jpg is rejected")
    func fileCorruptImageRejected() async throws {
        let url = try writeTempFixture(Data("definitely not an image".utf8), ext: "jpg")

        let m = makeMaterializer(policy())
        await expectThrowsCase(.invalidImageData) {
            try await m.materialize(source: .file(url), into: stage())
        }
    }

    @Test("resize strips GPS but retains other EXIF metadata")
    func resizeRetainsEXIFStripsGPS() async throws {
        let url = try writeTempFixture(makeJPEGWithGPSAndDate(), ext: "jpg")

        let m = makeMaterializer(policy(imageMaxDimension: 32, stripGPSLocation: true))
        let result = try await m.materialize(source: .file(url), into: stage())

        let props = try imageProperties(of: result.tempFileURL)
        #expect(props[kCGImagePropertyGPSDictionary] == nil)
        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
        #expect(exif?[kCGImagePropertyExifDateTimeOriginal] as? String == fixtureDateTimeOriginal)
        let width = try #require(props[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(props[kCGImagePropertyPixelHeight] as? Int)
        #expect(max(width, height) <= 32)
    }

    @Test("resize with stripGPSLocation off keeps GPS")
    func resizeWithoutStripKeepsGPS() async throws {
        let url = try writeTempFixture(makeJPEGWithGPSAndDate(), ext: "jpg")

        let m = makeMaterializer(policy(imageMaxDimension: 32))
        let result = try await m.materialize(source: .file(url), into: stage())

        #expect(imageHasGPS(result.tempFileURL))
    }

    @Test("resize bakes EXIF orientation into the pixels")
    func resizeBakesOrientation() async throws {
        // Landscape pixels with a 90° tag: a baked resize must produce
        // portrait output (height > width) with an upright tag.
        let heic = try encodeImage(
            makeSolidColorImage(size: CGSize(width: 80, height: 60), color: .blue),
            as: .heic,
            properties: [kCGImagePropertyOrientation: CGImagePropertyOrientation.right.rawValue]
        )
        let url = try writeTempFixture(heic, ext: "heic")

        let m = makeMaterializer(policy(imageMaxDimension: 40))
        let result = try await m.materialize(source: .file(url), into: stage())

        let props = try imageProperties(of: result.tempFileURL)
        let width = try #require(props[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(props[kCGImagePropertyPixelHeight] as? Int)
        #expect(height > width)
        let orientation = props[kCGImagePropertyOrientation] as? UInt32
        #expect(orientation == nil || orientation == CGImagePropertyOrientation.up.rawValue)
    }

    @Test("sniffed container type wins over a lying declared type")
    func sniffedTypeWinsOverDeclared() async throws {
        // HEIC bytes in a file named .jpg: the extension-derived declared
        // type says JPEG, but the bytes must still be converted.
        let url = try writeTempFixture(makeSyntheticHEIC(), ext: "jpg")

        let m = makeMaterializer(policy())
        let result = try await m.materialize(source: .file(url), into: stage())

        #expect(imageType(of: result.tempFileURL) == .jpeg)
    }

    @Test("PNG stays PNG through resize")
    func pngResizeKeepsType() async throws {
        let png = try encodeImage(
            makeSolidColorImage(size: CGSize(width: 128, height: 128), color: .red),
            as: .png
        )
        let url = try writeTempFixture(png, ext: "png")

        let m = makeMaterializer(policy(imageMaxDimension: 32))
        let result = try await m.materialize(source: .file(url), into: stage())

        #expect(imageType(of: result.tempFileURL) == .png)
        let props = try imageProperties(of: result.tempFileURL)
        let width = try #require(props[kCGImagePropertyPixelWidth] as? Int)
        #expect(width <= 32)
    }

    // MARK: - Format normalization + location stripping

    @Test(".file non-web-safe image (TIFF) is normalized to JPEG")
    func fileTIFFConvertedToJPEG() async throws {
        let tiff = try encodeImage(
            makeSolidColorImage(size: CGSize(width: 64, height: 64), color: .red),
            as: .tiff
        )
        let url = try writeTempFixture(tiff, ext: "tiff")

        let result = try await makeMaterializer(policy())
            .materialize(source: .file(url), into: stage())

        #expect(result.displayName.hasSuffix(".jpeg"))
        #expect(imageType(of: result.tempFileURL) == .jpeg)
    }

    @Test("image with no GPS strips cleanly (no-op, no throw)")
    func fileImageWithoutGPSStripSucceeds() async throws {
        let jpeg = try encodeImage(
            makeSolidColorImage(size: CGSize(width: 48, height: 48), color: .green),
            as: .jpeg
        )
        let url = try writeTempFixture(jpeg, ext: "jpg")

        let result = try await makeMaterializer(policy(stripGPSLocation: true))
            .materialize(source: .file(url), into: stage())
        #expect(!imageHasGPS(result.tempFileURL))
    }

    @Test("video with stripGPSLocation removes location metadata")
    func videoStripsLocation() async throws {
        let src = try await makeVideoWithLocation()
        let sourceHasLocation = try await videoHasLocation(src)
        #expect(sourceHasLocation) // sanity: source is tagged

        let result = try await makeMaterializer(policy(stripGPSLocation: true))
            .materialize(source: .file(src), into: stage())
        let outputHasLocation = try await videoHasLocation(result.tempFileURL)
        #expect(!outputHasLocation)
    }

    @Test("orphan sweep deletes only entries created before the cutoff")
    func sweepSkipsEntriesCreatedAfterCutoff() throws {
        let sweepRoot = try makeTempDir()
        let orphaned = sweepRoot.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fresh = sweepRoot.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: orphaned, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: fresh, withIntermediateDirectories: true)
        try FileManager.default.setAttributes(
            [.creationDate: Date(timeIntervalSinceNow: -3600)],
            ofItemAtPath: orphaned.path
        )

        UploadSourceMaterializer.sweepOrphanedStagingFiles(
            in: sweepRoot,
            createdBefore: Date(timeIntervalSinceNow: -60)
        )

        #expect(!FileManager.default.fileExists(atPath: orphaned.path))
        #expect(FileManager.default.fileExists(atPath: fresh.path))
    }
}

// MARK: - Suite fixtures

extension UploadSourceMaterializerTests {
    /// Materializer staging into the per-test root (or an explicit override
    /// when the test needs to inspect the root itself).
    private func makeMaterializer(
        _ policy: MediaUploadPolicy,
        temporaryRoot: URL? = nil
    ) -> UploadSourceMaterializer {
        UploadSourceMaterializer(policy: policy, temporaryRoot: temporaryRoot ?? root)
    }

    /// Fresh directory under the per-test root; removed with it in deinit.
    private func makeTempDir() throws -> URL {
        let dir = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Writes fixture bytes into a fresh directory under the per-test root.
    private func writeTempFixture(_ data: Data, name: String) throws -> URL {
        let url = try makeTempDir().appendingPathComponent(name)
        try data.write(to: url)
        return url
    }

    private func writeTempFixture(_ data: Data, ext: String) throws -> URL {
        try writeTempFixture(data, name: "fixture.\(ext)")
    }

    private func createTempPDF(name: String = "test.pdf") throws -> URL {
        try writeTempFixture(Data("%PDF-1.4\n%EOF\n".utf8), name: name)
    }

    private func createTempGIF() throws -> URL {
        try writeTempFixture(gifFixture, name: "test.gif")
    }

    /// A short video carrying a QuickTime ISO-6709 location, used to prove the
    /// materializer strips it.
    private func makeVideoWithLocation() async throws -> URL {
        let location = AVMutableMetadataItem()
        location.identifier = .quickTimeMetadataLocationISO6709
        location.value = "+37.3349-122.0090+030.000/" as NSString
        location.dataType = "com.apple.metadata.datatype.quicktime-metadata-location-ISO6709"
        return try await createBlankVideo(
            durationSeconds: 1,
            metadata: [location],
            in: makeTempDir()
        )
    }
}

// MARK: - Test fixtures

private func makeGIFItemProvider(vendingFile gifURL: URL) -> NSItemProvider {
    let provider = NSItemProvider()
    provider.registerFileRepresentation(
        forTypeIdentifier: UTType.gif.identifier,
        fileOptions: [],
        visibility: .all
    ) { completion in
        completion(gifURL, false, nil)
        return nil
    }
    return provider
}

/// Minimal valid GIF89a: header + logical screen descriptor + trailer.
private let gifFixture = Data([
    0x47, 0x49, 0x46, 0x38, 0x39, 0x61, // "GIF89a"
    0x01, 0x00, 0x01, 0x00, // width=1, height=1
    0x00, // GCT flag off
    0x00, // background color
    0x00, // aspect ratio
    0x3B // trailer
])

private enum FixtureError: Error { case encodingFailed, imageUnavailable }

/// Minimal valid SVG document for passthrough tests.
private let svgFixture = Data(
    #"<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10" fill="red"/></svg>"#
        .utf8
)

private func makeSolidColorImage(size: CGSize, color: UIColor) -> UIImage {
    // Opaque format: a stray alpha channel only triggers ImageIO's "opaque
    // image with AlphaLast" warnings when the image is later re-encoded.
    // Scale 1 keeps the pixel dimensions equal to `size` on any simulator
    // (and avoids rendering fixture bitmaps at 3x screen scale).
    let format = UIGraphicsImageRendererFormat.preferred()
    format.opaque = true
    format.scale = 1
    return UIGraphicsImageRenderer(size: size, format: format)
        .image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
}

/// Encodes an image as `type`, attaching any extra image properties such as
/// orientation or GPS. Centralizes the `CGImageDestination` boilerplate the
/// image fixtures would otherwise each repeat.
private func encodeImage(
    _ image: UIImage,
    as type: UTType,
    properties: [CFString: Any] = [:]
) throws -> Data {
    guard let cgImage = image.cgImage else {
        throw FixtureError.imageUnavailable
    }
    let out = NSMutableData()
    guard
        let dst = CGImageDestinationCreateWithData(out, type.identifier as CFString, 1, nil)
    else {
        throw FixtureError.encodingFailed
    }
    CGImageDestinationAddImage(dst, cgImage, properties as CFDictionary)
    guard CGImageDestinationFinalize(dst) else {
        throw FixtureError.encodingFailed
    }
    return out as Data
}

private let fixtureDateTimeOriginal = "2026:01:01 12:00:00"

/// Synthetic JPEG carrying both a GPS dictionary and an EXIF capture date,
/// for GPS-stripping tests and tests that pin the resize path's metadata
/// handling.
private func makeJPEGWithGPSAndDate() throws -> Data {
    let image = makeSolidColorImage(size: CGSize(width: 128, height: 128), color: .green)
    let gps: [CFString: Any] = [
        kCGImagePropertyGPSLatitude: 37.33,
        kCGImagePropertyGPSLongitude: -122.03
    ]
    let exif: [CFString: Any] = [
        kCGImagePropertyExifDateTimeOriginal: fixtureDateTimeOriginal
    ]
    return try encodeImage(
        image,
        as: .jpeg,
        properties: [
            kCGImagePropertyGPSDictionary: gps,
            kCGImagePropertyExifDictionary: exif
        ]
    )
}

private func imageProperties(of url: URL) throws -> [CFString: Any] {
    let src = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
    return try #require(CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any])
}

/// Synthetic HEIC, optionally carrying a specific EXIF orientation tag.
/// Works on iOS 17+ simulator.
private func makeSyntheticHEIC(orientation: CGImagePropertyOrientation? = nil) throws -> Data {
    let image = makeSolidColorImage(size: CGSize(width: 64, height: 64), color: .blue)
    var properties: [CFString: Any] = [:]
    if let orientation {
        properties[kCGImagePropertyOrientation] = orientation.rawValue
    }
    return try encodeImage(image, as: .heic, properties: properties)
}

/// Encoding a video is the most expensive fixture in this suite, and every
/// consumer only reads the source file, so all tests share a single clip.
private let sharedBlankVideoTask = Task { try await createBlankVideo(durationSeconds: 1.0) }

/// Creates a 1-second blank H.264 video using AVAssetWriter, optionally
/// tagged with container-level metadata.
private func createBlankVideo(
    durationSeconds: Double,
    metadata: [AVMetadataItem] = [],
    in directory: URL = FileManager.default.temporaryDirectory
) async throws -> URL {
    let url = directory.appendingPathComponent("blank_\(UUID().uuidString).mp4")

    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
    writer.metadata = metadata
    let settings: [String: Any] = [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: 320,
        AVVideoHeightKey: 240
    ]
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    input.expectsMediaDataInRealTime = false
    writer.add(input)

    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
        assetWriterInput: input,
        sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: 320,
            kCVPixelBufferHeightKey as String: 240
        ]
    )

    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    // Write a single black frame at t=0.
    var pixelBuffer: CVPixelBuffer?
    CVPixelBufferCreate(
        kCFAllocatorDefault,
        320,
        240,
        kCVPixelFormatType_32BGRA,
        [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary,
        &pixelBuffer
    )
    if let pb = pixelBuffer {
        CVPixelBufferLockBaseAddress(pb, [])
        let ptr = CVPixelBufferGetBaseAddress(pb)
        memset(ptr, 0, CVPixelBufferGetDataSize(pb))
        CVPixelBufferUnlockBaseAddress(pb, [])
        adaptor.append(pb, withPresentationTime: .zero)
    }

    input.markAsFinished()

    return try await withCheckedThrowingContinuation { cont in
        writer.endSession(atSourceTime: CMTime(seconds: durationSeconds, preferredTimescale: 600))
        writer.finishWriting {
            if writer.status == .completed {
                cont.resume(returning: url)
            } else {
                cont.resume(throwing: writer.error ?? NSError(domain: "Test", code: 20))
            }
        }
    }
}

private func imageType(of url: URL) -> UTType? {
    guard
        let src = CGImageSourceCreateWithURL(url as CFURL, nil),
        let type = CGImageSourceGetType(src)
    else { return nil }
    return UTType(type as String)
}

private func imageHasGPS(_ url: URL) -> Bool {
    guard
        let src = CGImageSourceCreateWithURL(url as CFURL, nil),
        let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]
    else { return false }
    return props[kCGImagePropertyGPSDictionary] != nil
}

private func videoHasLocation(_ url: URL) async throws -> Bool {
    let asset = AVURLAsset(url: url)
    for format in try await asset.load(.availableMetadataFormats) {
        for item in try await asset.loadMetadata(for: format) {
            let identifier = (item.identifier?.rawValue ?? "").lowercased()
            if identifier.contains("loci") || identifier.contains("location") { return true }
        }
    }
    return false
}
