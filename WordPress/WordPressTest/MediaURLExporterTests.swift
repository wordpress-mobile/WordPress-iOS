import XCTest
import MobileCoreServices
import OHHTTPStubs
@testable import WordPress

class MediaURLExporterTests: XCTestCase {

    let testDeviceImageName = "test-image-device-photo-gps.jpg"
    let testDeviceVideoName = "test-video-device-gps.m4v"
    let testGIFName = "test-gif.gif"

    // MARK: - URL export testing

    func testThatURLExportingImageWorks() {
        let mediaPath = MediaImageExporterTests.filePathForTestImageNamed(testDeviceImageName)
        let expect = self.expectation(description: "image export by URL")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaURLExporter(url: url)
        exporter.mediaDirectoryType = .temporary
        exporter.export(onCompletion: { (urlExport) in
                        expect.fulfill()
                        let exportFileName = urlExport.url.lastPathComponent.replacingMatches(of: "." + urlExport.url.pathExtension, with: "")
                        let originalFileName = url.lastPathComponent.replacingMatches(of: "." + url.pathExtension, with: "")
                        XCTAssertEqual(exportFileName, originalFileName)
                        MediaExporterTests.cleanUpExportedMedia(atURL: urlExport.url)
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
        guard let mediaPath = OHPathForFile(testDeviceVideoName, type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test video file")
            return
        }
        let expect = self.expectation(description: "video export by URL")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaURLExporter(url: url)
        exporter.mediaDirectoryType = .temporary
        var options = MediaVideoExporter.Options()
        options.stripsGeoLocationIfNeeded = removingGPS
        exporter.videoOptions = options
        weak var weakExporter = exporter
        exporter.export(onCompletion: { (urlExport) in
                        MediaURLExporterTests.validateVideoExport(urlExport, exporter: weakExporter!)
                        MediaExporterTests.cleanUpExportedMedia(atURL: urlExport.url)
                        expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing a URL export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatURLExportingGIFWorks() {
        guard let mediaPath = OHPathForFile(testGIFName, type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return
        }
        let expect = self.expectation(description: "image export by URL")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaURLExporter(url: url)
        exporter.mediaDirectoryType = .temporary
        exporter.export(onCompletion: { (urlExport) in
            MediaExporterTests.cleanUpExportedMedia(atURL: urlExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing a URL export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    // MARK: - Media export validation

    class func validateVideoExport(_ export: MediaExport, exporter: MediaURLExporter) {
        let asset = AVAsset(url: export.url)
        XCTAssertTrue(asset.isPlayable, "Error: exported video asset is unplayble.")

        if let duration = export.duration {
            XCTAssertTrue(asset.duration.seconds == duration, "The exported video's duration does not match the expected duration.")
        }
        var hasLocationData = false
        for metadata in asset.metadata {
            if metadata.commonKey == AVMetadataKey.commonKeyLocation {
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
}
