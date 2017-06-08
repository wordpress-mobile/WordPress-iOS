import Foundation
@testable import WordPress

class MediaThumbnailExporterTests: XCTestCase {

    let testDeviceImageName = "test-image-device-photo-gps.jpg"
    let testDeviceVideoName = "test-video-device-gps.m4v"

    func testThatExportingImageThumbnailWorks() {
        let mediaPath = MediaImageExporterTests.filePathForTestImageNamed(testDeviceImageName)
        let expect = self.expectation(description: "thumbnail image export by URL")
        let url = URL(fileURLWithPath: mediaPath)

        let exporter = MediaThumbnailExporter()
        var options = MediaImageExporter.Options()
        options.maximumImageSize = 200
        exporter.options = options
        exporter.exportThumbnail(forFile: url,
                                 onCompletion: { (export) in
                                    MediaImageExporterTests.validateImageExport(export, withExpectedSize: options.maximumImageSize!)
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
        var options = MediaImageExporter.Options()
        options.maximumImageSize = 200
        exporter.options = options
        exporter.exportThumbnail(forFile: url,
                                 onCompletion: { (export) in
                                    MediaImageExporterTests.validateImageExport(export, withExpectedSize: options.maximumImageSize!)
                                    MediaExporterTests.cleanUpExportedMedia(atURL: export.url)
                                    expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing a video thumbnail export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
}
