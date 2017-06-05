import XCTest
@testable import WordPress
import MobileCoreServices

class MediaURLExporterTests: XCTestCase {

    // MARK: - URL export testing

    func testThatURLExportingImageWorks() {
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

    func testThatURLExportingVideoWorks() {
        exportTestVideo(removingGPS: false)
    }

    func testThatURLExportingVideoWithoutGPSWorks() {
        exportTestVideo(removingGPS: true)
    }

    fileprivate func exportTestVideo(removingGPS: Bool) {
        guard let mediaPath = OHPathForFile("test-video-device-gps.m4v", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test video file")
            return
        }
        let expect = self.expectation(description: "video export by URL")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaURLExporter()
        exporter.mediaDirectoryType = .temporary
        var options = MediaVideoExporter.Options()
        options.stripsGeoLocationIfNeeded = removingGPS
        exporter.videoOptions = options
        weak var weakExporter = exporter
        exporter.exportURL(fileURL: url,
                           onCompletion: { (urlExport) in
                            switch urlExport {
                            case .exportedVideo(let videoExport):
                                self.validateVideoExport(videoExport, exporter: weakExporter!)
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

    func testThatURLExportingGIFWorks() {
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

    // MARK: - Media export validation

    fileprivate func validateVideoExport(_ export: MediaVideoExport, exporter: MediaURLExporter) {
        let asset = AVAsset(url: export.url)
        XCTAssertTrue(asset.isPlayable, "Error: exported video asset is unplayble.")

        if let duration = export.duration {
            XCTAssertTrue(asset.duration.seconds == duration, "The exported video's duration does not match the expected duration.")
        }
        var hasLocationData = false
        for metadata in asset.metadata {
            if metadata.commonKey == AVMetadataCommonKeyLocation {
                hasLocationData = true
                break
            }
        }
        if exporter.videoOptions?.stripsGeoLocationIfNeeded == true {
            XCTAssert(hasLocationData == false, "The exported video's location data was not removed as expected.")
        } else {
            XCTAssert(hasLocationData == true, "The exported video's location data was unexpectedly removed.")
        }
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
