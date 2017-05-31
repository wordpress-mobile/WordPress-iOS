import XCTest
@testable import WordPress
import MobileCoreServices

class MediaURLExporterTests: XCTestCase {

    // MARK: - URL export testing

    func testThatURLExportingAnImageWorks() {
        guard let mediaPath = OHPathForFile("test-image-device-photo-gps.jpg", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return
        }
        let expect = self.expectation(description: "image export by URL")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaURLExporter()
        exporter.mediaDirectoryType = .temporary
        exporter.exportURL(fileURL: url,
                           onCompletion: { (urlExport) in
                            switch urlExport {
                            case .exportedImage(let imageExport):
                                self.cleanUpExportedMedia(atURL: imageExport.url)
                            default:
                                XCTFail("Error: expected the URL export to result in an image export")
                            }
                            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing a URL export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatURLExportingAVideoWorks() {
        guard let mediaPath = OHPathForFile("test-video-device-gps.m4v", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test video file")
            return
        }
        let expect = self.expectation(description: "video export by URL")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaURLExporter()
        exporter.mediaDirectoryType = .temporary
        exporter.exportURL(fileURL: url,
                           onCompletion: { (urlExport) in
                            switch urlExport {
                            case .exportedVideo(let videoExport):
                                self.cleanUpExportedMedia(atURL: videoExport.url)
                            default:
                                XCTFail("Error: expected the URL export to result in a video export")
                            }
                            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing a URL export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatURLExportingAGIFWorks() {
        guard let mediaPath = OHPathForFile("test-gif.gif", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return
        }
        let expect = self.expectation(description: "image export by URL")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaURLExporter()
        exporter.mediaDirectoryType = .temporary
        exporter.exportURL(fileURL: url,
                           onCompletion: { (urlExport) in
                            switch urlExport {
                            case .exportedGIF(let gifExport):
                                self.cleanUpExportedMedia(atURL: gifExport.url)
                            default:
                                XCTFail("Error: expected the URL export to result in a GIF export")
                            }
                            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing a URL export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    // MARK: - Media export testing cleanup

    fileprivate func cleanUpExportedMedia(atURL url: URL) {
        do {
            let fileManager = FileManager.default
            try fileManager.removeItem(at: url)
        } catch {
            XCTFail("Error: failed to clean up exported media: \(error)")
        }
    }
}
