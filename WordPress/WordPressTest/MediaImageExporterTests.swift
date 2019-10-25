import XCTest
@testable import WordPress
import MobileCoreServices

class MediaImageExporterTests: XCTestCase {

    // MARK: - Image export testing

    let testDeviceImageNameWithGPS = "test-image-device-photo-gps.jpg"
    let testDeviceImageNameWithGPSInPortrait = "test-image-device-photo-gps-portrait.jpg"
    let testImageNameInPortrait = "test-image-portrait.jpg"

    func testThatImageExportingByImageWorks() {
        let image = MediaImageExporterTests.imageForFileNamed(testDeviceImageNameWithGPS)
        let expect = self.expectation(description: "image export by UIImage")
        let exporter = MediaImageExporter(image: image, filename: nil)
        exporter.mediaDirectoryType = .temporary
        exporter.export(onCompletion: { (imageExport) in
            MediaImageExporterTests.validateImageExport(imageExport, withExpectedSize: max(image.size.width, image.size.height))
            MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingByURLWorks() {
        let mediaPath = MediaImageExporterTests.filePathForTestImageNamed(testDeviceImageNameWithGPS)
        let image = MediaImageExporterTests.imageForFilePath(mediaPath)
        let expect = self.expectation(description: "image export by URL")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter(url: url)
        exporter.mediaDirectoryType = .temporary
        exporter.export(onCompletion: { (imageExport) in
            MediaImageExporterTests.validateImageExport(imageExport, withExpectedSize: max(image.size.width, image.size.height))
            MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingWithResizingWorks() {
        let mediaPath = MediaImageExporterTests.filePathForTestImageNamed(testDeviceImageNameWithGPS)
        let expect = self.expectation(description: "image export with a maximum size")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter(url: url)
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        exporter.options.maximumImageSize = maximumImageSize
        exporter.export(onCompletion: { (imageExport) in
            MediaImageExporterTests.validateImageExport(imageExport, withExpectedSize: maximumImageSize)
            MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export by URL with a maximum size: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingWithMaximumSizeLargerThanTheImageWorks() {
        let image = MediaImageExporterTests.imageForFileNamed(testDeviceImageNameWithGPS)
        let expect = self.expectation(description: "image export with a maximum size larger than the image's size")
        let exporter = MediaImageExporter(image: image, filename: nil)
        let expectedSize = max(image.size.width, image.size.height)
        let maximumImageSize = expectedSize + 200
        exporter.mediaDirectoryType = .temporary
        exporter.options.maximumImageSize = maximumImageSize
        exporter.export(onCompletion: { (imageExport) in
            MediaImageExporterTests.validateImageExport(imageExport, withExpectedSize: expectedSize)
            MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export with a maximum size larger than the image's size: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    // MARK: - Image export GPS testing

    func testThatImageExportingAndStrippingGPSWorks() {
        let mediaPath = MediaImageExporterTests.filePathForTestImageNamed(testDeviceImageNameWithGPS)
        let expect = self.expectation(description: "image export with stripping GPS")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter(url: url)
        exporter.mediaDirectoryType = .temporary
        exporter.options.stripsGeoLocationIfNeeded = true
        exporter.export(onCompletion: { (imageExport) in
                MediaImageExporterTests.validateImageExportStrippedGPS(imageExport)
                MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
                expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export and stripping GPS: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingAndDidNotStripGPSWorks() {
        let mediaPath = MediaImageExporterTests.filePathForTestImageNamed(testDeviceImageNameWithGPS)
        let expect = self.expectation(description: "image export without stripping GPS")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter(url: url)
        exporter.mediaDirectoryType = .temporary
        exporter.options.stripsGeoLocationIfNeeded = false
        exporter.export(onCompletion: { (imageExport) in
            MediaImageExporterTests.validateImageExportDidNotStripGPS(imageExport)
            MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export and not stripping GPS: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingWithResizingAndStrippingGPSWorks() {
        let mediaPath = MediaImageExporterTests.filePathForTestImageNamed(testDeviceImageNameWithGPS)
        let expect = self.expectation(description: "image export with resizing and stripping GPS")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter(url: url)
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        exporter.options.stripsGeoLocationIfNeeded = true
        exporter.options.maximumImageSize = maximumImageSize
        exporter.export(onCompletion: { (imageExport) in
            MediaImageExporterTests.validateImageExportStrippedGPS(imageExport)
            MediaImageExporterTests.validateImageExport(imageExport, withExpectedSize: maximumImageSize)
            MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export with resizing and stripping GPS: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingWithResizingAndNotStrippingGPSWorks() {
        let mediaPath = MediaImageExporterTests.filePathForTestImageNamed(testDeviceImageNameWithGPS)
        let expect = self.expectation(description: "image export with resizing and stripping GPS")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter(url: url)
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        exporter.options.stripsGeoLocationIfNeeded = false
        exporter.options.maximumImageSize = maximumImageSize
        exporter.export(onCompletion: { (imageExport) in
            MediaImageExporterTests.validateImageExportDidNotStripGPS(imageExport)
            MediaImageExporterTests.validateImageExport(imageExport, withExpectedSize: maximumImageSize)
            MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export with resizing and not stripping GPS: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    // MARK: - Image export orientation testing

    func testExportingAPortraitImageWithoutResizeRotatesToUpOrientationWorks() {
        let image = MediaImageExporterTests.imageForFileNamed(testImageNameInPortrait)
        if image.imageOrientation != .leftMirrored {
            XCTFail("Error: the test portrait image was not in the expected orientation, expected: " +
                "\(UIImage.Orientation.leftMirrored.rawValue)" +
                " but read: \(image.imageOrientation.rawValue)")
            return
        }
        let expect = self.expectation(description: "image export by UIImage and keeping the orientation")
        let exporter = MediaImageExporter(image: image, filename: nil)
        exporter.mediaDirectoryType = .temporary
        exporter.export(onCompletion: { (imageExport) in
            // If not resising the image the orientation stays the same has the original
            MediaImageExporterTests.validateImageExportedWithExpectedOrientation(export: imageExport, expected: .up)
            MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testExportingAPortraitImageAndCorrectingTheOrientationWhileResizingWorks() {
        let image = MediaImageExporterTests.imageForFileNamed(testImageNameInPortrait)
        if image.imageOrientation != .leftMirrored {
            XCTFail("Error: the test portrait image was not in the expected orientation, expected: "
                + "\(UIImage.Orientation.leftMirrored.rawValue)" +
                " but read: \(image.imageOrientation.rawValue)")
            return
        }
        let expect = self.expectation(description: "image export by UIImage and correcting the orientation with resizing")
        let exporter = MediaImageExporter(image: image, filename: nil)
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        exporter.options.maximumImageSize = maximumImageSize
        exporter.export(onCompletion: { (imageExport) in
            MediaImageExporterTests.validateImageExportedWithExpectedOrientation(export: imageExport, expected: .up)
            MediaImageExporterTests.validateImageExport(imageExport, withExpectedSize: maximumImageSize)
            MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testExportingAPortraitImageAndCorrectingTheOrientationWhileResizingAndStrippingGPSWorks() {
        let image = MediaImageExporterTests.imageForFileNamed(testDeviceImageNameWithGPSInPortrait)
        let expect = self.expectation(description: "image export by UIImage and correcting the orientation with resizing and stripping GPS")
        let exporter = MediaImageExporter(image: image, filename: nil)
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        exporter.options.stripsGeoLocationIfNeeded = true
        exporter.options.maximumImageSize = maximumImageSize
        exporter.export(onCompletion: { (imageExport) in
            MediaImageExporterTests.validateImageExportedWithExpectedOrientation(export: imageExport, expected: .up)
            MediaImageExporterTests.validateImageExportStrippedGPS(imageExport)
            MediaImageExporterTests.validateImageExport(imageExport, withExpectedSize: maximumImageSize)
            MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingByImageAndChangingFormatsWorks() {
        let image = MediaImageExporterTests.imageForFileNamed(testDeviceImageNameWithGPS)
        let expect = self.expectation(description: "image export by UIImage")
        let exporter = MediaImageExporter(image: image, filename: nil)
        exporter.mediaDirectoryType = .temporary
        exporter.options.exportImageType = kUTTypePNG as String
        exporter.export(onCompletion: { (imageExport) in
            XCTAssert(UTTypeEqual(kUTTypePNG, imageExport.url.typeIdentifier! as CFString), "Unexpected image format when trying to target a PNG format from a JPEG.")
            MediaImageExporterTests.validateImageExport(imageExport, withExpectedSize: max(image.size.width, image.size.height))
            MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    // MARK: - Helper methods

    class func filePathForTestImageNamed(_ file: String) -> String {
        guard let mediaPath = OHPathForFile(file, self) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return ""
        }
        return mediaPath
    }

    class func imageForFilePath(_ path: String) -> UIImage {
        guard let image = UIImage(contentsOfFile: path) else {
            XCTFail("Error: an error occurred initializing the test image for export")
            return UIImage()
        }
        return image
    }

    class func imageForFileNamed(_ file: String) -> UIImage {
        return self.imageForFilePath(self.filePathForTestImageNamed(file))
    }

    // MARK: - Export validation

    class func validateImageExport(_ imageExport: MediaExport, withExpectedSize expectedSize: CGFloat) {
        guard let image = UIImage(contentsOfFile: imageExport.url.path) else {
            XCTFail("Error: an error occurred checking the image from an export")
            return
        }
        let maxDimension = max(image.size.width, image.size.height)
        if maxDimension > expectedSize {
            XCTFail("Error: the exported image was larger than the expected maximum size: (\(image.size))")
        }
        if let exportWidth = imageExport.width {
            XCTAssertTrue(exportWidth == image.size.width, "Error: the exported image's width did not match the imageExport's width value: (\(exportWidth))")
        } else {
            XCTFail("Error: the imageExport's width value was nil")
        }
        if let exportHeight = imageExport.height {
            XCTAssertTrue(exportHeight == image.size.height, "Error: the exported image's height did not match the imageExport's height value: (\(exportHeight))")
        } else {
            XCTFail("Error: the imageExport's height value was nil")
        }
    }

    class func validateImageExportStrippedGPS(_ imageExport: MediaExport) {
        guard let source = CGImageSourceCreateWithURL(imageExport.url as CFURL, nil) else {
            XCTFail("Error: an error occurred checking the image source from an export")
            return
        }
        guard let properties: [String: Any] = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? Dictionary else {
            XCTFail("Error: an error occurred checking an image source's properties from an export")
            return
        }
        if properties[kCGImagePropertyGPSDictionary as String] != nil {
            XCTFail("Error: found GPS properties when reading an exported image source's properties")
        }
    }

    class func validateImageExportDidNotStripGPS(_ imageExport: MediaExport) {
        guard let source = CGImageSourceCreateWithURL(imageExport.url as CFURL, nil) else {
            XCTFail("Error: an error occurred checking the image source from an export")
            return
        }
        guard let properties: [String: Any] = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? Dictionary else {
            XCTFail("Error: an error occurred checking an image source's properties from an export")
            return
        }
        if properties[kCGImagePropertyGPSDictionary as String] == nil {
            XCTFail("Error: did not find expected GPS properties when reading an exported image source's properties")
        }
    }

    class func validateImageExportedWithExpectedOrientation(export: MediaExport, expected: UIImage.Orientation) {
        guard let image = UIImage(contentsOfFile: export.url.path) else {
            XCTFail("Error: an error occurred initializing the exported image for validation")
            return
        }
        XCTAssert(image.imageOrientation == expected, "Error: the exported image's orientation (\(image.imageOrientation.rawValue)) did not match the expected orientation (\(expected.rawValue))")
    }
}
