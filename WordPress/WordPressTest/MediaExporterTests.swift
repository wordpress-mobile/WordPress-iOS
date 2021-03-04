import XCTest
import MobileCoreServices
import OHHTTPStubs
@testable import WordPress

class MockMediaExporter: MediaExporter {
    var maximumImageSize: CGFloat?
    var stripsGeoLocationIfNeeded = false
    var mediaDirectoryType: MediaDirectory = .temporary

    func export(onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        return Progress.discreteCompletedProgress()
    }
}

class MediaExporterTests: XCTestCase {

    // MARK: - Error testing

    func testExporterErrorsWork() {

        let sampleLocalizedString = "This was an error test"
        let mockSystemError = NSError(domain: "MediaExporterTests", code: 999, userInfo: [NSLocalizedDescriptionKey: sampleLocalizedString])

        // Test that the types are being carried over correctly when using exporterErrorWith(error:) with an NSError.
        let exporter = MockMediaExporter()
        let systemErrorWrappedAsAnExporterError = exporter.exporterErrorWith(error: mockSystemError)

        XCTAssert(systemErrorWrappedAsAnExporterError.toNSError().isEqual(mockSystemError), "Error: unexpected NSError generated while wrapping within a MediaExportError")

        let exportSystemError = MediaExportSystemError.failedWith(systemError: mockSystemError)

        // Test that the descriptions are being interpreted correctly.
        XCTAssert(exportSystemError.description == String(describing: mockSystemError), "Error: unexpected description text for MediaExportSystemError")
        XCTAssert(exportSystemError.toNSError().localizedDescription == sampleLocalizedString, "Error: unexpected localizedDescription from NSError method via MediaExportSystemError")
    }

    // MARK: - Helper testing

    func testThatFileExtensionForTypeIsWorking() {
        // Testing JPEG as a simple test of the implementation.
        // Maybe expanding the test to all of our supported types would be helpful.
        let expected = "jpeg"
        XCTAssert(URL.fileExtensionForUTType(kUTTypeJPEG as String) == expected, "Error: unexpected extension found when converting from UTType")
    }

    func testThatURLFileSizeWorks() {
        guard let mediaPath = OHPathForFile("test-image.jpg", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return
        }
        let url = URL(fileURLWithPath: mediaPath)
        guard let size = url.fileSize else {
            XCTAssert(false, "Error: failed getting a size of the test image file")
            return
        }
        XCTAssert(size == 233139, "Error: unexpected file size found for the test image: \(size)")
    }

    // MARK: - Testing cleanup

    class func cleanUpExportedMedia(atURL url: URL) {
        do {
            let fileManager = FileManager.default
            try fileManager.removeItem(at: url)
        } catch {
            XCTFail("Error: failed to clean up exported media: \(error)")
        }
    }
}
