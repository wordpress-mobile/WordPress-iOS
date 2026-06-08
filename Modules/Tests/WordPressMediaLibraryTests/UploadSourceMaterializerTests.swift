import AVFoundation
import Foundation
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import WordPressMediaLibrary

/// Fresh stage progress for materializer tests that don't care about
/// the value — matches what the actor would allocate in production.
private func stage() -> Progress { Progress(totalUnitCount: 100) }

@Suite("UploadSourceMaterializer")
struct UploadSourceMaterializerTests {
    private func policy(
        allow: @escaping @Sendable (UTType, String) -> Bool = { _, _ in true }
    ) -> MediaUploadPolicy {
        MediaUploadPolicy(
            filePickerContentTypes: [.content],
            isAllowedForUpload: allow,
            imageMaxDimension: nil,
            imageJpegQuality: 0.9,
            convertHEICToJPEG: true,
            videoMaxDurationSeconds: nil,
            videoExportPreset: AVAssetExportPresetMediumQuality,
            videoOutputContentType: .mpeg4Movie,
            stripImageLocation: false
        )
    }

    @Test("file source: validator rejection surfaces disallowedContentType")
    func validatorRejectsDocument() async throws {
        let tempURL = try createTempPDF()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let materializer = UploadSourceMaterializer(policy: policy(allow: { _, _ in false }))
        await #expect {
            _ = try await materializer.materialize(source: .file(tempURL), into: stage())
        } throws: { error in
            guard case MaterializerError.disallowedContentType = error else { return false }
            return true
        }
    }

    @Test("file source preserves original basename verbatim")
    func fileSourcePreservesBasename() async throws {
        let tempURL = try createTempPDF(name: "Quarterly Report.pdf")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let m = UploadSourceMaterializer(policy: policy())
        let result = try await m.materialize(source: .file(tempURL), into: stage())
        defer { try? FileManager.default.removeItem(at: result.tempFileURL.deletingLastPathComponent()) }
        #expect(result.displayName == "Quarterly Report.pdf")
    }

    @Test("materialization failures remove their parent temp directory")
    func failureRemovesTempDir() async throws {
        let tempURL = try createTempPDF()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let inspectableRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestMaterializerRoot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: inspectableRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: inspectableRoot) }

        let m = UploadSourceMaterializer(
            policy: policy(allow: { _, _ in false }),
            temporaryRoot: inspectableRoot
        )
        await #expect {
            _ = try await m.materialize(source: .file(tempURL), into: stage())
        } throws: { error in
            guard case MaterializerError.disallowedContentType = error else { return false }
            return true
        }

        let contents = try FileManager.default.contentsOfDirectory(
            at: inspectableRoot,
            includingPropertiesForKeys: nil
        )
        #expect(contents.isEmpty)
    }

    @Test("camera image yields IMG_<timestamp>.jpg")
    func cameraImageBasename() throws {
        let image = makeSolidColorImage(size: CGSize(width: 10, height: 10), color: .red)
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01 00-00-00 UTC

        let inspectableRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestMaterializerRoot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: inspectableRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: inspectableRoot) }

        let m = UploadSourceMaterializer(policy: policy(), temporaryRoot: inspectableRoot)
        let result = try m.materializeCameraImagePublic(
            image: image,
            capturedAt: date,
            temporaryRoot: inspectableRoot
        )
        defer { try? FileManager.default.removeItem(at: result.tempFileURL.deletingLastPathComponent()) }

        #expect(result.displayName.hasPrefix("IMG"))
        #expect(result.displayName.hasSuffix(".jpg"))
        #expect(result.kind == .image)
        #expect(FileManager.default.fileExists(atPath: result.tempFileURL.path))
    }

    @Test("camera image with stripImageLocation removes GPS")
    func cameraImageStripsGPS() throws {
        // Build a JPEG with a synthetic GPS dict embedded.
        let jpegWithGPS = try makeJPEGWithGPS()

        let inspectableRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestMaterializerRoot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: inspectableRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: inspectableRoot) }

        // Write it as a UIImage-equivalent: decode → UIImage → test the strip path
        // directly by materializing a camera image from a JPEG-backed UIImage.
        let stripPolicy = MediaUploadPolicy(
            filePickerContentTypes: [.content],
            isAllowedForUpload: { _, _ in true },
            imageMaxDimension: nil,
            imageJpegQuality: 0.9,
            convertHEICToJPEG: true,
            videoMaxDurationSeconds: nil,
            videoExportPreset: AVAssetExportPresetMediumQuality,
            videoOutputContentType: .mpeg4Movie,
            stripImageLocation: true
        )

        // Use file-source path which exercises stripGPS on raw JPEG bytes.
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gps_test_\(UUID().uuidString).jpg")
        try jpegWithGPS.write(to: sourceURL)
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let m = UploadSourceMaterializer(policy: stripPolicy, temporaryRoot: inspectableRoot)
        let result = try m.materializeFileImagePublic(
            sourceURL: sourceURL,
            contentType: .jpeg,
            stem: "gps_test",
            temporaryRoot: inspectableRoot
        )
        defer { try? FileManager.default.removeItem(at: result.tempFileURL.deletingLastPathComponent()) }

        let outputData = try Data(contentsOf: result.tempFileURL)
        guard let src = CGImageSourceCreateWithData(outputData as CFData, nil),
            let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]
        else {
            return // no properties at all means no GPS — test passes
        }
        #expect(props[kCGImagePropertyGPSDictionary] == nil)
    }

    @Test("camera video over duration is rejected")
    func cameraVideoOverDuration() async throws {
        let videoURL = try await createBlankVideo(durationSeconds: 1.0)
        defer { try? FileManager.default.removeItem(at: videoURL) }

        let shortCapPolicy = MediaUploadPolicy(
            filePickerContentTypes: [.content],
            isAllowedForUpload: { _, _ in true },
            imageMaxDimension: nil,
            imageJpegQuality: 0.9,
            convertHEICToJPEG: true,
            videoMaxDurationSeconds: 0.5,
            videoExportPreset: AVAssetExportPresetMediumQuality,
            videoOutputContentType: .mpeg4Movie,
            stripImageLocation: false
        )
        let m = UploadSourceMaterializer(policy: shortCapPolicy)
        await #expect {
            _ = try await m.materialize(source: .cameraVideo(videoURL, capturedAt: Date()), into: stage())
        } throws: { error in
            guard case MaterializerError.durationCapExceeded = error else { return false }
            return true
        }
    }

    @Test("camera video exports to .mp4 by default")
    func cameraVideoExportsToMP4() async throws {
        let videoURL = try await createBlankVideo(durationSeconds: 1.0)
        defer { try? FileManager.default.removeItem(at: videoURL) }

        let inspectableRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestMaterializerRoot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: inspectableRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: inspectableRoot) }

        let m = UploadSourceMaterializer(policy: policy(), temporaryRoot: inspectableRoot)
        let result = try await m.materialize(source: .cameraVideo(videoURL, capturedAt: Date()), into: stage())
        defer { try? FileManager.default.removeItem(at: result.tempFileURL.deletingLastPathComponent()) }

        #expect(result.displayName.hasSuffix(".mp4"))
        #expect(result.kind == .video)
        #expect(FileManager.default.fileExists(atPath: result.tempFileURL.path))
    }

    @Test(".file HEIC under policy that rejects HEIC but allows JPEG succeeds")
    func fileHEICConvertedToJPEG() async throws {
        let heicData = try makeSyntheticHEIC()
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_\(UUID().uuidString).heic")
        try heicData.write(to: sourceURL)
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let heicRejectPolicy = MediaUploadPolicy(
            filePickerContentTypes: [.content],
            isAllowedForUpload: { type, ext in
                // Reject HEIC, allow JPEG
                !(type == .heic || ext == "heic")
            },
            imageMaxDimension: nil,
            imageJpegQuality: 0.9,
            convertHEICToJPEG: true,
            videoMaxDurationSeconds: nil,
            videoExportPreset: AVAssetExportPresetMediumQuality,
            videoOutputContentType: .mpeg4Movie,
            stripImageLocation: false
        )

        let inspectableRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestMaterializerRoot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: inspectableRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: inspectableRoot) }

        let m = UploadSourceMaterializer(policy: heicRejectPolicy, temporaryRoot: inspectableRoot)
        let result = try await m.materialize(source: .file(sourceURL), into: stage())
        defer { try? FileManager.default.removeItem(at: result.tempFileURL.deletingLastPathComponent()) }

        #expect(result.displayName.hasSuffix(".jpg") || result.displayName.hasSuffix(".jpeg"))
        #expect(result.kind == .image)
    }

    @Test(".file video with duration cap exceeded is rejected")
    func fileVideoOverDuration() async throws {
        let videoURL = try await createBlankVideo(durationSeconds: 1.0)
        defer { try? FileManager.default.removeItem(at: videoURL) }

        let capPolicy = MediaUploadPolicy(
            filePickerContentTypes: [.content],
            isAllowedForUpload: { _, _ in true },
            imageMaxDimension: nil,
            imageJpegQuality: 0.9,
            convertHEICToJPEG: true,
            videoMaxDurationSeconds: 0.01,
            videoExportPreset: AVAssetExportPresetMediumQuality,
            videoOutputContentType: .mpeg4Movie,
            stripImageLocation: false
        )
        let m = UploadSourceMaterializer(policy: capPolicy)
        await #expect {
            _ = try await m.materialize(source: .file(videoURL), into: stage())
        } throws: { error in
            guard case MaterializerError.durationCapExceeded = error else { return false }
            return true
        }
    }

    @Test(".file video re-exports to .mp4")
    func fileVideoReexportsToMP4() async throws {
        let videoURL = try await createBlankVideo(durationSeconds: 1.0)
        defer { try? FileManager.default.removeItem(at: videoURL) }

        let inspectableRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestMaterializerRoot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: inspectableRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: inspectableRoot) }

        let m = UploadSourceMaterializer(policy: policy(), temporaryRoot: inspectableRoot)
        let result = try await m.materialize(source: .file(videoURL), into: stage())
        defer { try? FileManager.default.removeItem(at: result.tempFileURL.deletingLastPathComponent()) }

        #expect(result.displayName.hasSuffix(".mp4"))
        #expect(result.kind == .video)
    }

    @Test(".file GIF passes through raw-copied")
    func fileGIFRawCopy() async throws {
        let gifURL = try createTempGIF()
        defer { try? FileManager.default.removeItem(at: gifURL) }

        let inspectableRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestMaterializerRoot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: inspectableRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: inspectableRoot) }

        let m = UploadSourceMaterializer(policy: policy(), temporaryRoot: inspectableRoot)
        let result = try await m.materialize(source: .file(gifURL), into: stage())
        defer { try? FileManager.default.removeItem(at: result.tempFileURL.deletingLastPathComponent()) }

        #expect(result.displayName.hasSuffix(".gif"))
        #expect(result.kind == .image)

        // Verify byte-for-byte copy: the output should be the same file size.
        let srcSize = (try? gifURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? -1
        let dstSize =
            (try? result.tempFileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? -2
        #expect(srcSize == dstSize)
    }

    @Test(".file PDF passes through raw-copied")
    func filePDFRawCopy() async throws {
        let pdfURL = try createTempPDF()
        defer { try? FileManager.default.removeItem(at: pdfURL) }

        let inspectableRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestMaterializerRoot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: inspectableRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: inspectableRoot) }

        let m = UploadSourceMaterializer(policy: policy(), temporaryRoot: inspectableRoot)
        let result = try await m.materialize(source: .file(pdfURL), into: stage())
        defer { try? FileManager.default.removeItem(at: result.tempFileURL.deletingLastPathComponent()) }

        #expect(result.displayName.hasSuffix(".pdf"))
        #expect(result.kind == .document)
    }

    @Test(".photoLibrary GIF passes through raw-copied")
    func photoLibraryGIFRawCopy() async throws {
        let gifURL = try createTempGIF()
        defer { try? FileManager.default.removeItem(at: gifURL) }

        let inspectableRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestMaterializerRoot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: inspectableRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: inspectableRoot) }

        // Resize + GPS-strip both enabled — the bug class this guards
        // against is ImageIO flattening animated GIFs when either is on.
        let transformingImagePolicy = MediaUploadPolicy(
            filePickerContentTypes: [.content],
            isAllowedForUpload: { _, _ in true },
            imageMaxDimension: 1024,
            imageJpegQuality: 0.9,
            convertHEICToJPEG: true,
            videoMaxDurationSeconds: nil,
            videoExportPreset: AVAssetExportPresetMediumQuality,
            videoOutputContentType: .mpeg4Movie,
            stripImageLocation: true
        )

        let m = UploadSourceMaterializer(policy: transformingImagePolicy, temporaryRoot: inspectableRoot)
        let result = try await m.materialize(
            source: .photoLibrary(
                itemProvider: makeGIFItemProvider(vendingFile: gifURL),
                suggestedName: "Animation",
                hint: .gif
            ),
            into: stage()
        )
        defer { try? FileManager.default.removeItem(at: result.tempFileURL.deletingLastPathComponent()) }

        #expect(result.displayName.hasSuffix(".gif"))
        #expect(result.kind == .image)

        // Byte-for-byte copy: any ImageIO round-trip would alter the
        // bytes even if the file size happened to match.
        let srcBytes = try Data(contentsOf: gifURL)
        let dstBytes = try Data(contentsOf: result.tempFileURL)
        #expect(srcBytes == dstBytes)
    }

    @Test(".photoLibrary GIF: validator rejection surfaces disallowedContentType")
    func photoLibraryGIFRejected() async throws {
        let gifURL = try createTempGIF()
        defer { try? FileManager.default.removeItem(at: gifURL) }

        let m = UploadSourceMaterializer(policy: policy(allow: { _, ext in ext != "gif" }))
        await #expect {
            _ = try await m.materialize(
                source: .photoLibrary(
                    itemProvider: makeGIFItemProvider(vendingFile: gifURL),
                    suggestedName: "Animation",
                    hint: .gif
                ),
                into: stage()
            )
        } throws: { error in
            guard case MaterializerError.disallowedContentType = error else { return false }
            return true
        }
    }

    @Test("camera image: imageMaxDimension resizes before GPS strip")
    func cameraImageResized() throws {
        // 2000×2000 image, cap at 1024 — output pixel long edge must be <= 1024.
        let image = makeSolidColorImage(size: CGSize(width: 2000, height: 2000), color: .blue)

        let resizePolicy = MediaUploadPolicy(
            filePickerContentTypes: [.content],
            isAllowedForUpload: { _, _ in true },
            imageMaxDimension: 1024,
            imageJpegQuality: 0.9,
            convertHEICToJPEG: true,
            videoMaxDurationSeconds: nil,
            videoExportPreset: AVAssetExportPresetMediumQuality,
            videoOutputContentType: .mpeg4Movie,
            stripImageLocation: true
        )

        let inspectableRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestMaterializerRoot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: inspectableRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: inspectableRoot) }

        let m = UploadSourceMaterializer(policy: resizePolicy, temporaryRoot: inspectableRoot)
        let result = try m.materializeCameraImagePublic(
            image: image,
            capturedAt: Date(),
            temporaryRoot: inspectableRoot
        )
        defer { try? FileManager.default.removeItem(at: result.tempFileURL.deletingLastPathComponent()) }

        // Verify dimensions are within the cap.
        let data = try Data(contentsOf: result.tempFileURL)
        guard
            let src = CGImageSourceCreateWithData(data as CFData, nil),
            let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
            let w = props[kCGImagePropertyPixelWidth] as? Int,
            let h = props[kCGImagePropertyPixelHeight] as? Int
        else {
            Issue.record("Could not read output image dimensions")
            return
        }
        #expect(max(w, h) <= 1024)
    }

    @Test func materialize_imagePlayground_appliesImagePolicy_withoutSecurityScope() async throws {
        let tempRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        // Plant a small JPEG that Image Playground might have produced.
        let imageURL = tempRoot.appendingPathComponent("Generated.jpg")
        let image = UIImage(systemName: "photo")!
        try image.jpegData(compressionQuality: 0.9)!.write(to: imageURL)

        let materializer = UploadSourceMaterializer(
            policy: policy(),
            temporaryRoot: tempRoot
        )
        let result = try await materializer.materialize(
            source: .imagePlayground(imageURL, suggestedName: "Generated"),
            into: Progress(totalUnitCount: 100)
        )

        #expect(result.kind == .image)
        #expect(result.displayName == "Generated.jpeg")
        // Image policy ran (file exists at the destination).
        #expect(FileManager.default.fileExists(atPath: result.tempFileURL.path))
    }

    @Test func materialize_imagePlayground_removesParentDirOnFailure() async throws {
        let tempRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let nonExistent = tempRoot.appendingPathComponent("does-not-exist.heic")
        let materializer = UploadSourceMaterializer(
            policy: policy(),
            temporaryRoot: tempRoot
        )

        await #expect(throws: (any Error).self) {
            _ = try await materializer.materialize(
                source: .imagePlayground(nonExistent, suggestedName: "x"),
                into: Progress(totalUnitCount: 100)
            )
        }
        let remaining = try FileManager.default.contentsOfDirectory(atPath: tempRoot.path)
        #expect(remaining.isEmpty)
    }

    // MARK: - .remoteURL post-download dispatch

    @Test func remoteDispatch_gif_passthroughPreservesBytes() async throws {
        let parentDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: parentDir) }

        let sourceGIF = parentDir.appendingPathComponent("download.tmp")
        let gifBytes = Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00]) // GIF89a header sentinel
        try gifBytes.write(to: sourceGIF)

        let materializer = UploadSourceMaterializer(
            policy: policy(),
            temporaryRoot: parentDir
        )
        let result = try await materializer.dispatchRemoteDownload(
            localFile: sourceGIF,
            contentType: .gif,
            suggestedName: "happy-cat",
            caption: nil,
            parentDir: parentDir
        )

        let copied = try Data(contentsOf: URL(fileURLWithPath: result.params.filePath))
        #expect(copied == gifBytes) // byte-equal: animation preserved
        #expect(URL(fileURLWithPath: result.params.filePath).pathExtension == "gif")
        #expect(URL(fileURLWithPath: result.params.filePath).deletingPathExtension().lastPathComponent == "happy-cat")
        // Display name includes the .gif extension, matching the contract
        // applied uniformly across materializer branches.
        #expect(result.displayName == "happy-cat.gif")
    }

    @Test func remoteDispatch_passesCaptionThrough() async throws {
        let parentDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: parentDir) }

        let sourceGIF = parentDir.appendingPathComponent("a.tmp")
        try Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]).write(to: sourceGIF)

        let materializer = UploadSourceMaterializer(
            policy: policy(),
            temporaryRoot: parentDir
        )
        let result = try await materializer.dispatchRemoteDownload(
            localFile: sourceGIF,
            contentType: .gif,
            suggestedName: "g",
            caption: "Photo by Foo",
            parentDir: parentDir
        )
        #expect(result.params.caption == "Photo by Foo")
    }

    @Test func remoteDispatch_rejectsNonImageNonGifContentType() async throws {
        let parentDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: parentDir) }

        let sourceFile = parentDir.appendingPathComponent("vid.tmp")
        try Data([0x00]).write(to: sourceFile)

        let materializer = UploadSourceMaterializer(
            policy: policy(),
            temporaryRoot: parentDir
        )
        await #expect(throws: MaterializerError.self) {
            _ = try await materializer.dispatchRemoteDownload(
                localFile: sourceFile,
                contentType: .movie,
                suggestedName: "x",
                caption: nil,
                parentDir: parentDir
            )
        }
    }

    @Test func remoteDispatch_image_passesCaptionThrough() async throws {
        let parentDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: parentDir) }

        let sourceJPEG = parentDir.appendingPathComponent("download.tmp")
        try UIImage(systemName: "photo")!.jpegData(compressionQuality: 0.9)!.write(to: sourceJPEG)

        let materializer = UploadSourceMaterializer(
            policy: policy(),
            temporaryRoot: parentDir.appendingPathComponent("root")
        )
        let result = try await materializer.dispatchRemoteDownload(
            localFile: sourceJPEG,
            contentType: .jpeg,
            suggestedName: "photo",
            caption: "Photo by Foo",
            parentDir: parentDir
        )
        #expect(result.params.caption == "Photo by Foo")
    }

    @Test func remoteDispatch_imageBranchRejectsNonImageBytes() async throws {
        let parentDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: parentDir) }

        let sourceFile = parentDir.appendingPathComponent("a.tmp")
        try "<html><body>404 Not Found</body></html>".data(using: .utf8)!.write(to: sourceFile)

        let materializer = UploadSourceMaterializer(
            policy: policy(),
            temporaryRoot: parentDir
        )
        await #expect(throws: MaterializerError.self) {
            _ = try await materializer.dispatchRemoteDownload(
                localFile: sourceFile,
                contentType: .jpeg,
                suggestedName: "x",
                caption: nil,
                parentDir: parentDir
            )
        }
    }
}

// MARK: - Test-only public surface

// These extensions expose internal methods for testing without duplicating logic.
extension UploadSourceMaterializer {
    func materializeCameraImagePublic(
        image: UIImage,
        capturedAt: Date,
        temporaryRoot: URL
    ) throws -> MaterializedUpload {
        let id = UUID()
        let parentDir = temporaryRoot.appendingPathComponent(id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        return try materializeCameraImage(parentDir: parentDir, image: image, capturedAt: capturedAt)
    }

    func materializeFileImagePublic(
        sourceURL: URL,
        contentType: UTType,
        stem: String,
        temporaryRoot: URL
    ) throws -> MaterializedUpload {
        let id = UUID()
        let parentDir = temporaryRoot.appendingPathComponent(id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        return try materializeFileImage(
            parentDir: parentDir,
            sourceURL: sourceURL,
            contentType: contentType,
            stem: stem
        )
    }
}

// MARK: - Test fixtures

private func createTempPDF(name: String = "test_\(UUID().uuidString).pdf") throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
    let pdf = "%PDF-1.4\n%EOF\n".data(using: .ascii)!
    try pdf.write(to: url)
    return url
}

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

private func createTempGIF() throws -> URL {
    // Minimal valid GIF89a: header + logical screen descriptor + trailer.
    let gifBytes: [UInt8] = [
        0x47, 0x49, 0x46, 0x38, 0x39, 0x61, // "GIF89a"
        0x01, 0x00, 0x01, 0x00, // width=1, height=1
        0x00, // GCT flag off
        0x00, // background color
        0x00, // aspect ratio
        0x3B // trailer
    ]
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("test_\(UUID().uuidString).gif")
    try Data(gifBytes).write(to: url)
    return url
}

private func makeSolidColorImage(size: CGSize, color: UIColor) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
        color.setFill()
        ctx.fill(CGRect(origin: .zero, size: size))
    }
}

private func makeJPEGWithGPS() throws -> Data {
    let image = makeSolidColorImage(size: CGSize(width: 10, height: 10), color: .green)
    guard let baseJPEG = image.jpegData(compressionQuality: 0.9) else {
        throw NSError(domain: "Test", code: 1)
    }
    // Re-encode with a synthetic GPS dictionary injected via CGImageDestination.
    guard let src = CGImageSourceCreateWithData(baseJPEG as CFData, nil) else {
        throw NSError(domain: "Test", code: 2)
    }
    let out = NSMutableData()
    guard
        let dst = CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil)
    else {
        throw NSError(domain: "Test", code: 3)
    }
    let gpsDict: [CFString: Any] = [
        kCGImagePropertyGPSLatitude: 37.33,
        kCGImagePropertyGPSLongitude: -122.03
    ]
    let props: [CFString: Any] = [kCGImagePropertyGPSDictionary: gpsDict]
    CGImageDestinationAddImageFromSource(dst, src, 0, props as CFDictionary)
    guard CGImageDestinationFinalize(dst) else {
        throw NSError(domain: "Test", code: 4)
    }
    return out as Data
}

/// Synthesize a minimal HEIC using CGImageDestination. Works on iOS 17+ simulator.
private func makeSyntheticHEIC() throws -> Data {
    let image = makeSolidColorImage(size: CGSize(width: 10, height: 10), color: .blue)
    guard let cgImage = image.cgImage else {
        throw NSError(domain: "Test", code: 10)
    }
    let out = NSMutableData()
    guard
        let dst = CGImageDestinationCreateWithData(out, UTType.heic.identifier as CFString, 1, nil)
    else {
        throw NSError(domain: "Test", code: 11)
    }
    CGImageDestinationAddImage(dst, cgImage, nil)
    guard CGImageDestinationFinalize(dst) else {
        throw NSError(domain: "Test", code: 12)
    }
    return out as Data
}

/// Creates a 1-second blank H.264 video using AVAssetWriter.
private func createBlankVideo(durationSeconds: Double) async throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("blank_\(UUID().uuidString).mp4")

    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
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
