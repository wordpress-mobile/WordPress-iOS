import Foundation
import OHHTTPStubs
@testable import WordPress

class MediaThumbnailExporterTests: XCTestCase {

    let testDeviceImageName = "test-image-device-photo-gps.jpg"
    let testDeviceVideoName = "test-video-device-gps.m4v"

    func testThatExportingImageThumbnailWorks() {
        let mediaPath = MediaImageExporterTests.filePathForTestImageNamed(testDeviceImageName)
        let expect = self.expectation(description: "thumbnail image export by URL")
        let url = URL(fileURLWithPath: mediaPath)

        let exporter = MediaThumbnailExporter()
        exporter.options.preferredSize = CGSize(width: 200, height: 200)
        exporter.exportThumbnail(forFile: url,
                                 onCompletion: { (identifier, export) in
                                    self.validateThumbnailExport(withExporter: exporter,
                                                                 identifier: identifier,
                                                                 export: export)
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
                                 onCompletion: { (identifier, export) in
                                    self.validateThumbnailExport(withExporter: exporter,
                                                                 identifier: identifier,
                                                                 export: export)
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

    fileprivate func validateThumbnailExport(withExporter exporter: MediaThumbnailExporter, identifier: MediaThumbnailExporter.ThumbnailIdentifier, export: MediaExport) {
        guard let availableThumbnail = exporter.availableThumbnail(with: identifier) else {
            XCTFail("Thumbnail exported but was not detected as available.")
            return
        }
        XCTAssertTrue(export.url == availableThumbnail, "Unexpected thumbnail export URL when comparing with availableThumbnail URL.")
    }
}
