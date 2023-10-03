import Foundation
import OHHTTPStubs
import XCTest
@testable import WordPress

final class ItemProviderMediaExporterTests: XCTestCase {

    // MARK: - Images

    func testHEICIsConvertedToJPEG() throws {
        // GIVEN a provider with a HEIC photo
        let provider = try makeProvider(forResource: "iphone-photo", withExtension: "heic", type: .heic)

        // WHEN
        let exporter = ItemProviderMediaExporter(provider: provider)
        exporter.mediaDirectoryType = .temporary

        let media = try exportedMedia(from: exporter)

        // THEN it switched to JPEG from HEIC
        XCTAssertEqual(media.url.pathExtension, "jpeg")
        XCTAssertEqual(media.width, 640)
        XCTAssertEqual(media.height, 480)
        XCTAssertNotNil(UIImage(data: try Data(contentsOf: media.url)))

        MediaExporterTests.cleanUpExportedMedia(atURL: media.url)
    }

    func testThatWebPIsConvertedToSupportedFormat() throws {
        // GIVEN a provider with a WebP image
        let provider = try makeProvider(forResource: "test-webp", withExtension: "webp", type: .webP)

        // WHEN
        let exporter = ItemProviderMediaExporter(provider: provider)
        exporter.mediaDirectoryType = .temporary

        let media = try exportedMedia(from: exporter)

        // THEN it switched to JPEG from WEBP
        XCTAssertEqual(media.url.pathExtension, "jpeg")
        XCTAssertEqual(media.width, 1024.0)
        XCTAssertEqual(media.height, 772.0)
        XCTAssertNotNil(UIImage(data: try Data(contentsOf: media.url)))

        MediaExporterTests.cleanUpExportedMedia(atURL: media.url)
    }

    func testThatGPSDataIsRemoved() throws {
        // GIVEN an image with GPS data
        let imageName = "test-image-device-photo-gps"
        let provider = try makeProvider(forResource: imageName, withExtension: "jpg", type: .jpeg)

        do {
            // Sanity check: verify that the original image has EXIF data
            let imageURL = try XCTUnwrap(Bundle.test.url(forResource: imageName, withExtension: "jpg"))
            let properties = try getImageProperties(for: imageURL)
            XCTAssertNotNil(properties[kCGImagePropertyGPSDictionary])
        }

        // WHEN
        let exporter = ItemProviderMediaExporter(provider: provider)
        exporter.mediaDirectoryType = .temporary
        exporter.imageOptions = .init(stripsGeoLocationIfNeeded: true)

        let media = try exportedMedia(from: exporter)

        // THEN it exported the image as jpeg (still has EXIF)
        XCTAssertEqual(media.url.pathExtension, "jpeg")
        XCTAssertNotNil(UIImage(data: try Data(contentsOf: media.url)))

        // THEN but GPS data was removed
        let properties = try getImageProperties(for: media.url)
        XCTAssertNil(properties[kCGImagePropertyGPSDictionary])

        MediaExporterTests.cleanUpExportedMedia(atURL: media.url)
    }

    func testThatGIFIsExported() throws {
        // GIVEN a GIF file
        let provider = try makeProvider(forResource: "test-gif", withExtension: "gif", type: .gif)

        // WHEN
        let exporter = ItemProviderMediaExporter(provider: provider)
        exporter.mediaDirectoryType = .temporary

        let media = try exportedMedia(from: exporter)

        // THEN
        XCTAssertEqual(media.url.pathExtension, "gif")
        XCTAssertEqual(media.height, 360)
        XCTAssertEqual(media.width, 360)

        MediaExporterTests.cleanUpExportedMedia(atURL: media.url)
    }

    // MARK: - Video

    func testThatVideoIsExported() throws {
        try XCTSkipIf(true, "This test takes too long. Replace the video with something that gets transcoded quicker.")

        // GIVEN a video
        let provider = try makeProvider(forResource: "test-video-device-gps", withExtension: "m4v", type: .mpeg4Movie)

        // WHEN
        let exporter = ItemProviderMediaExporter(provider: provider)
        exporter.mediaDirectoryType = .temporary

        let media = try exportedMedia(from: exporter)

        // THEN the video is transcoded to one of the supported containers (.mp4)
        XCTAssertEqual(media.url.pathExtension, "mp4")

        // THEN video metadata is saved
        XCTAssertEqual(media.height, 360)
        XCTAssertEqual(media.width, 640)
        XCTAssertEqual(media.duration ?? 0.0, 3.47, accuracy: 0.01)

        MediaExporterTests.cleanUpExportedMedia(atURL: media.url)
    }

    // MARK: - Error Handling

    func testThatExportFailsWithUnsupportedData() throws {
        // GIVEN
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: UTType.exe.identifier, visibility: .all) { completion in
            completion(Data(), nil)
            return nil
        }

        // WHEN
        let exporter = ItemProviderMediaExporter(provider: provider)
        exporter.mediaDirectoryType = .temporary

        do {
            let _ = try exportedMedia(from: exporter)
            XCTFail("Expected the export to fail")
        } catch {
            // THEN
            let error = try XCTUnwrap(error as? ItemProviderMediaExporter.ExportError)
            if case .unsupportedContentType = error {
                // Expected
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}

// MARK: - ItemProviderMediaExporterTests (Helpers)

private extension ItemProviderMediaExporterTests {
    func makeProvider(forResource name: String, withExtension ext: String, type: UTType) throws -> NSItemProvider {
        let imageURL = try XCTUnwrap(Bundle.test.url(forResource: name, withExtension: ext))
        let provider = NSItemProvider()
        provider.registerFileRepresentation(forTypeIdentifier: type.identifier, visibility: .all) { completion in
            completion(imageURL, false, nil)
            return nil
        }
        return provider
    }

    func exportedMedia(from exporter: ItemProviderMediaExporter) throws -> MediaExport {
        let expectation = self.expectation(description: "mediaExported")
        var result: Result<MediaExport, Error>?
        _ = exporter.export(onCompletion: { media in
            result = .success(media)
            expectation.fulfill()
        }, onError: { error in
            result = .failure(error)
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 2)
        return try XCTUnwrap(result).get()
    }

    func getImageProperties(for imageURL: URL) throws -> [CFString: Any] {
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(imageURL as CFURL, nil))
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        return properties ?? [:]
    }
}
