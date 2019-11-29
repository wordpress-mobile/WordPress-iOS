import XCTest
@testable import WordPress
import MobileCoreServices
import Photos

class MediaAssetExporterTests: XCTestCase {

    // MARK: - Image export testing

    let testDeviceImageNameWithGPS = "test-image-device-photo-gps.jpg"
    let testDeviceImageNameWithGPSInPortrait = "test-image-device-photo-gps-portrait.jpg"
    let testImageNameInPortrait = "test-image-portrait.jpg"

    func testThatAssetExportingWorks() {
        let image = MediaImageExporterTests.imageForFileNamed(testDeviceImageNameWithGPS)
        guard let asset = assetForFile(named: testDeviceImageNameWithGPS) else {
            return
        }
        let expect = self.expectation(description: "Image PHAsset export.")
        let exporter = MediaAssetExporter(asset: asset)
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

    func testThatAssetExportingWithResizingWorks() {
        guard let asset = assetForFile(named: testDeviceImageNameWithGPS) else {
            return
        }
        let expect = self.expectation(description: "image export with a maximum size")
        let exporter = MediaAssetExporter(asset: asset)
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        var options = MediaImageExporter.Options()
        options.maximumImageSize = maximumImageSize
        exporter.imageOptions = options
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


    // MARK: - Image export GPS testing

    func testThatImageExportingAndStrippingGPSWorks() {
        guard let asset = assetForFile(named: testDeviceImageNameWithGPS) else {
            return
        }
        let expect = self.expectation(description: "image export with stripping GPS")
        let exporter = MediaAssetExporter(asset: asset)
        exporter.mediaDirectoryType = .temporary
        var options = MediaImageExporter.Options()
        options.stripsGeoLocationIfNeeded = true
        exporter.imageOptions = options
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
        guard let asset = assetForFile(named: testDeviceImageNameWithGPS) else {
            return
        }
        let expect = self.expectation(description: "image export with stripping GPS")
        let exporter = MediaAssetExporter(asset: asset)
        exporter.mediaDirectoryType = .temporary
        var options = MediaImageExporter.Options()
        options.stripsGeoLocationIfNeeded = false
        exporter.imageOptions = options
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
        guard let asset = assetForFile(named: testDeviceImageNameWithGPS) else {
            return
        }
        let expect = self.expectation(description: "image export with resizing and stripping GPS")
        let exporter = MediaAssetExporter(asset: asset)
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        var options = MediaImageExporter.Options()
        options.stripsGeoLocationIfNeeded = true
        options.maximumImageSize = maximumImageSize
        exporter.imageOptions = options
        exporter.export(onCompletion: { (imageExport) in
            MediaImageExporterTests.validateImageExportStrippedGPS(imageExport)
            MediaImageExporterTests.validateImageExport(imageExport, withExpectedSize: maximumImageSize)
            MediaExporterTests.cleanUpExportedMedia(atURL: imageExport.url)
            expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export with resizing and stripping GPS: " +
                "\(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingWithResizingAndNotStrippingGPSWorks() {
        guard let asset = assetForFile(named: testDeviceImageNameWithGPS) else {
            return
        }
        let expect = self.expectation(description: "image export with resizing and stripping GPS")
        let exporter = MediaAssetExporter(asset: asset)
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        var options = MediaImageExporter.Options()
        options.stripsGeoLocationIfNeeded = false
        options.maximumImageSize = maximumImageSize
        exporter.imageOptions = options
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

    func testExportingAPortraitImageWithoutResizeKeepsTheOrientationWorks() {
        let image = MediaImageExporterTests.imageForFileNamed(testImageNameInPortrait)
        if image.imageOrientation != .leftMirrored {
            XCTFail("Error: the test portrait image was not in the expected orientation, expected: "
                + " \(UIImage.Orientation.leftMirrored.rawValue) " +
                " but read: \(image.imageOrientation.rawValue)")
            return
        }
        guard let asset = assetForFile(named: testImageNameInPortrait) else {
            return
        }
        let exporter = MediaAssetExporter(asset: asset)
        let expect = self.expectation(description: "image export by UIImage and keeping the orientation")
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
            XCTFail("Error: the test portrait image was not in the expected orientation, expected: \(UIImage.Orientation.leftMirrored.rawValue) but read: \(image.imageOrientation.rawValue)")
            return
        }
        guard let asset = assetForFile(named: testImageNameInPortrait) else {
            return
        }
        let exporter = MediaAssetExporter(asset: asset)
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        var options = MediaImageExporter.Options()
        options.maximumImageSize = maximumImageSize
        exporter.imageOptions = options
        let expect = self.expectation(description: "image export by UIImage and correcting the orientation with resizing")
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
        guard let asset = assetForFile(named: testDeviceImageNameWithGPSInPortrait) else {
            return
        }

        let exporter = MediaAssetExporter(asset: asset)
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        var options = MediaImageExporter.Options()
        options.maximumImageSize = maximumImageSize
        options.stripsGeoLocationIfNeeded = true
        exporter.imageOptions = options
        let expect = self.expectation(description: "image export by UIImage and correcting the orientation with resizing and stripping GPS")
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
        guard let asset = assetForFile(named: testDeviceImageNameWithGPS) else {
            return
        }
        let exporter = MediaAssetExporter(asset: asset)
        exporter.mediaDirectoryType = .temporary
        var options = MediaImageExporter.Options()
        options.exportImageType = kUTTypePNG as String
        exporter.imageOptions = options
        let expect = self.expectation(description: "image export by UIImage")
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

    private func assetForFile(named: String) -> PHAsset? {
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            return nil
        }
        let path = MediaImageExporterTests.filePathForTestImageNamed(named)
        let url = URL(fileURLWithPath: path)
        let expect = self.expectation(description: "Create asset from image")
        var assetIdentifier: String? = nil
        PHPhotoLibrary.shared().performChanges({
            // Request creating an asset from the image.
            let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            if let placeholder = creationRequest?.placeholderForCreatedAsset {
                assetIdentifier = placeholder.localIdentifier
            }

        }, completionHandler: { success, error in
            expect.fulfill()
            if !success || assetIdentifier == nil {
                XCTFail("Error: an error occurred loading an asset to test export: \(String(describing: error))")
            }
        })
        waitForExpectations(timeout: 2.0, handler: nil)
        guard let identifier = assetIdentifier else {
            XCTFail("Error: an error occurred loading an asset to test export.")
            preconditionFailure()
        }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = result.firstObject else {
            XCTFail("Error: an error occurred loading an asset to test export.")
            preconditionFailure()
        }
        return asset
    }

    private func deleteAsset(_ asset: PHAsset) {
        let expect = self.expectation(description: "Create asset from image")
        PHPhotoLibrary.shared().performChanges({
            // Request creating an asset from the image.
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }, completionHandler: { success, error in
            expect.fulfill()
        })
        waitForExpectations(timeout: 2.0, handler: nil)
    }
}
