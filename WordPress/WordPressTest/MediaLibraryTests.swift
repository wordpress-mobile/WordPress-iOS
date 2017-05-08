import XCTest
@testable import WordPress

class MediaLibraryTests: XCTestCase {

    func testThatLocalMediaDirectoryIsAvailable() {
        do {
            let url = try MediaLibrary.localUploadsDirectory()
            assertThatMediaDirectoryIsNamedMedia(url: url)
        } catch {
            XCTFail("Error accessing or creating local media directory: \(error)")
        }
    }

    func testThatLocalMediaDirectoryAsUploadsIsAvailable() {
        do {
            let url = try MediaLibrary.localDirectory(.uploads)
            assertThatMediaDirectoryIsNamedMedia(url: url)
            let fileManager = FileManager.default
            // The .uploads directory should be within the system Documents directory.
            let parentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            XCTAssert(url.absoluteString.hasPrefix(parentDirectory.absoluteString), "Error: media uploads directory URL has unexpected path.")
        } catch {
            XCTFail("Error accessing or creating local media uploads directory: \(error)")
        }
    }

    func testThatLocalMediaDirectoryAsCacheIsAvailable() {
        do {
            let url = try MediaLibrary.localDirectory(.cache)
            assertThatMediaDirectoryIsNamedMedia(url: url)
            let fileManager = FileManager.default
            // The .cache directory should be within the system Caches directory.
            let parentDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            XCTAssert(url.absoluteString.hasPrefix(parentDirectory.absoluteString), "Error: media cache directory URL has unexpected path.")
        } catch {
            XCTFail("Error accessing or creating local media cache directory: \(error)")
        }
    }

    func testThatLocalMediaDirectoryAsTemporaryIsAvailable() {
        do {
            let url = try MediaLibrary.localDirectory(.temporary)
            assertThatMediaDirectoryIsNamedMedia(url: url)
            let fileManager = FileManager.default
            // The .cache directory should be within the system Caches directory.
            let parentDirectory = fileManager.temporaryDirectory
            XCTAssert(url.absoluteString.hasPrefix(parentDirectory.absoluteString), "Error: media temporary directory URL has unexpected path.")
        } catch {
            XCTFail("Error accessing or creating local media temporary directory: \(error)")
        }
    }

    fileprivate func assertThatMediaDirectoryIsNamedMedia(url: URL) {
        XCTAssertTrue(url.lastPathComponent == "Media", "Error: local media directory is not named Media, as expected.")
    }

    func testThatLocalMediaURLWorks() {
        do {
            let basename = "media-service-test-sample"
            let pathExtension = "jpg"
            let expected = "\(basename).\(pathExtension)"

            var url = try MediaLibrary.makeLocalMediaURL(withFilename: basename, fileExtension: pathExtension)
            XCTAssertTrue(url.lastPathComponent == expected, "Error: local media url has unexpected basename or extension: \(url)")

            url = try MediaLibrary.makeLocalMediaURL(withFilename: expected, fileExtension: pathExtension)
            XCTAssertTrue(url.lastPathComponent == expected, "Error: local media url has unexpected extension: \(url)")

            url = try MediaLibrary.makeLocalMediaURL(withFilename: basename + ".png", fileExtension: pathExtension)
            XCTAssertTrue(url.lastPathComponent == expected, "Error: local media url has unexpected extension: \(url)")

            url = try MediaLibrary.makeLocalMediaURL(withFilename: basename, fileExtension: nil)
            XCTAssertTrue(url.lastPathComponent == basename, "Error: local media url has unexpected basename: \(url)")

            url = try MediaLibrary.makeLocalMediaURL(withFilename: expected, fileExtension: nil)
            XCTAssertTrue(url.lastPathComponent == expected, "Error: local media url has unexpected filename: \(url)")

        } catch {
            XCTFail("Error creating local media URL: \(error)")
        }
    }

    func testThatMediaThumbnailFilenameWorks() {
        let basename = "media-service-test-sample"
        let pathExtension = "jpg"
        var thumbnail = MediaLibrary.mediaFilenameAppendingThumbnail("\(basename).\(pathExtension)")
        XCTAssertTrue(thumbnail == "\(basename)-thumbnail.\(pathExtension)", "Error: appending media thumbnail to filename returned unexpected result.")
        thumbnail = MediaLibrary.mediaFilenameAppendingThumbnail(basename)
        XCTAssertTrue(thumbnail == "\(basename)-thumbnail", "Error: appending media thumbnail to filename returned unexpected result.")
    }

    func testThatSizeForMediaImageAtFileURLWorks() {
        var mediaPath = OHPathForFile("test-image.jpg", type(of: self))
        var size = MediaLibrary.imageSizeForMediaAt(fileURL: URL(fileURLWithPath: mediaPath!))
        XCTAssertTrue(size == CGSize(width: 1024, height: 680), "Unexpected size returned when testing imageSizeForMediaAtPath.")

        // Test an image in portrait orientation, example is in EXIF Orientation: 5
        mediaPath = OHPathForFile("test-image-portrait.jpg", type(of: self))
        // Check that size matches for the expected default orientation
        size = MediaLibrary.imageSizeForMediaAt(fileURL: URL(fileURLWithPath: mediaPath!))
        XCTAssertTrue(size == CGSize(width: 1024, height: 680), "Unexpected size returned when testing an image with an exif orientation of 5 via imageSizeForMediaAtPath.")
    }

    func testThatClearingUnusedFilesFromLocalMediaDirectoryWorks() {
        let expect = self.expectation(description: "cleaned unnused files from media directory")
        MediaLibrary.clearUnusedFilesFromLocalDirectory(onCompletion: {
            // Ideally we would verify that the local media directory was indeed cleaned.
            // However, for now we're just looking to make sure there aren't any errors being thrown with the implementation.
            expect.fulfill()
        }) { (error) in
            expect.fulfill()
            XCTFail("Failed cleaning unused local media directory files with error: \(error.localizedDescription)")
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatClearingCachedFilesFromLocalMediaDirectoryWorks() {
        let expect = self.expectation(description: "cleaned media directory")
        MediaLibrary.clearCachedFilesFromLocalDirectory(onCompletion: {
            // Ideally we would verify that the local media directory was indeed cleaned.
            // However, for now we're just looking to make sure there aren't any errors being thrown with the implementation.
            expect.fulfill()
        }) { (error) in
            expect.fulfill()
            XCTFail("Failed cleaning local media directory with error: \(error.localizedDescription)")
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
}
