import XCTest
@testable import WordPress

class MediaServiceTests: XCTestCase {

    func testThatLocalMediaDirectoryIsAvailable() {
        do {
            let url = try MediaService.localMediaDirectory()
            XCTAssertTrue(url.lastPathComponent == "Media", "Error: local media directory is not named Media, as expected.")
        } catch {
            XCTFail("Error accessing or creating local media directory: \(error)")
        }
    }

    func testThatLocalMediaURLWorks() {
        do {
            let basename = "media-service-test-sample"
            let pathExtension = "jpg"
            let expected = "\(basename).\(pathExtension)"
            var url = try MediaService.localMediaURL(with: basename, fileExtension: pathExtension)
            XCTAssertTrue(url.lastPathComponent == expected, "Error: local media url have unexpected filename or extension: \(url)")
            url = try MediaService.localMediaURL(with: expected, fileExtension: pathExtension)
            XCTAssertTrue(url.lastPathComponent == expected, "Error: local media url have unexpected filename or extension: \(url)")
            url = try MediaService.localMediaURL(with: basename + ".png", fileExtension: pathExtension)
            XCTAssertTrue(url.lastPathComponent == expected, "Error: local media url have unexpected filename or extension: \(url)")
        } catch {
            XCTFail("Error creating local media URL: \(error)")
        }
    }

    func testThatMediaTumbnailFilenameWorks() {
        let basename = "media-service-test-sample"
        let pathExtension = "jpg"
        var thumbnail = MediaService.mediaFilenameAppendingThumbnail("\(basename).\(pathExtension)")
        XCTAssertTrue(thumbnail == "\(basename)-thumbnail.\(pathExtension)", "Error: appending media thumbnail to filename returned unexpected result.")
        thumbnail = MediaService.mediaFilenameAppendingThumbnail(basename)
        XCTAssertTrue(thumbnail == "\(basename)-thumbnail", "Error: appending media thumbnail to filename returned unexpected result.")
    }

    func testThatSizeForMediaImageAtPathWorks() {
        let mediaPath = OHPathForFile("test-image.jpg", type(of: self))
        let size = MediaService.imageSizeForMediaAt(path: mediaPath)
        XCTAssertTrue(size == CGSize(width: 1024, height: 680), "Unexpected size return when testing imageSizeForMediaAtPath.")
    }
}
