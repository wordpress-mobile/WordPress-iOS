import Foundation
@testable import WordPress

class MediaThumbnailExporterTests: XCTestCase {

    let testDeviceImageName = "test-image-device-photo-gps.jpg"
    let testDeviceVideoName = "test-video-device-gps.m4v"

    func testThatThumbnailURLsWork() {
        let mediaPath = MediaImageExporterTests.filePathForTestImageNamed(testDeviceImageName)
        let url = URL(fileURLWithPath: mediaPath)

        let exporter = MediaThumbnailExporter()
        exporter.options.preferredSize = CGSize(width: 200, height: 200)
        let preferredSizeAtScale = exporter.options.preferredSizeAtScale!

        // Test that the generated thumbnail URLs match the expected format.
        let expectedFilename = url.deletingPathExtension().lastPathComponent
        let expectedExtension = url.resourceTypeIdentifierFileExtension!
        let expectedThumbnailDesc = "thumbnail(\(Int(preferredSizeAtScale.width))x\(Int(preferredSizeAtScale.height))).\(expectedExtension)"

        do {
            let thumbnailURL = try exporter.expectedThumbnailURL(forFile: url)
            let expectedLastPathComponent = "\(expectedFilename)-\(expectedThumbnailDesc)"
            XCTAssert(thumbnailURL.lastPathComponent == expectedLastPathComponent, "Unexpected thumbnail URL generated from thumbnail exporter.")

            // Test that the actual exported thumbnail URL matches the expected URL.
            let expect = self.expectation(description: "thumbnail export by URL")
            exporter.exportThumbnail(forFile: url,
                                     onCompletion: { (export) in
                                        XCTAssertTrue(export.url == thumbnailURL, "Unexpected thumbnail URL result from thumbnail export")
                                        MediaExporterTests.cleanUpExportedMedia(atURL: export.url)
                                        expect.fulfill()
            }) { (error) in
                XCTFail("Error: an error occurred testing a thumbnail export: \(error.toNSError())")
                expect.fulfill()
            }
            waitForExpectations(timeout: 2.0, handler: nil)
        } catch {
            XCTFail("Error: an error occurred testing a thumbnail URL: \(error)")
        }
    }

    func testThatExportingImageThumbnailWorks() {
        let mediaPath = MediaImageExporterTests.filePathForTestImageNamed(testDeviceImageName)
        let expect = self.expectation(description: "thumbnail image export by URL")
        let url = URL(fileURLWithPath: mediaPath)

        let exporter = MediaThumbnailExporter()
        exporter.options.preferredSize = CGSize(width: 200, height: 200)
        exporter.exportThumbnail(forFile: url,
                                 onCompletion: { (export) in
                                    MediaImageExporterTests.validateImageExport(export,
                                                                                withExpectedSize: exporter.options.preferredMaximumSizeAtScale!)
                                    MediaExporterTests.cleanUpExportedMedia(atURL: export.url)
                                    expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing a thumbnail export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatExportingVideoThumbnailWorks() {
        guard let mediaPath = OHPathForFile(testDeviceVideoName, type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test video file")
            return
        }
        let expect = self.expectation(description: "video thumbnail export by URL")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaThumbnailExporter()
        exporter.options.preferredSize = CGSize(width: 200, height: 200)
        exporter.exportThumbnail(forFile: url,
                                 onCompletion: { (export) in
                                    MediaImageExporterTests.validateImageExport(export,
                                                                                withExpectedSize: exporter.options.preferredMaximumSizeAtScale!)
                                    MediaExporterTests.cleanUpExportedMedia(atURL: export.url)
                                    expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing a video thumbnail export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
}
