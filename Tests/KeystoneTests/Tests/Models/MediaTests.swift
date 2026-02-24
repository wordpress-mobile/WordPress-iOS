import XCTest
@testable import WordPress
@testable import WordPressData

class MediaTests: CoreDataTestCase {

    fileprivate func newTestMedia() -> Media {
        return NSEntityDescription.insertNewObject(forEntityName: Media.entityName(), into: mainContext) as! Media
    }

    func testThatAbsoluteURLsWork() {
        do {
            let media = newTestMedia()
            let filePath = "sample.jpeg"
            var expectedAbsoluteURL = try MediaFileManager.uploadsDirectoryURL()
            expectedAbsoluteURL.appendPathComponent(filePath)
            media.absoluteLocalURL = expectedAbsoluteURL
            guard
                let localPath = media.localURL,
                let localURL = URL(string: localPath),
                let absoluteURL = media.absoluteLocalURL
                else {
                    XCTFail("Error building expected absolute URL: \(expectedAbsoluteURL)")
                    return
            }
            XCTAssert(localURL.lastPathComponent == expectedAbsoluteURL.lastPathComponent, "Error: unexpected local Media URL")
            XCTAssert(absoluteURL == expectedAbsoluteURL, "Error: unexpected absolute Media URL")
        } catch {
            XCTFail("Error testing absolute URLs: \(error)")
        }
    }

    func testThatAbsoluteThumbnailURLsWork() {
        do {
            let media = newTestMedia()
            let filePath = "sample-thumbnail.jpeg"
            var expectedAbsoluteURL = try MediaFileManager.cache.directoryURL()
            expectedAbsoluteURL.appendPathComponent(filePath)
            media.absoluteThumbnailLocalURL = expectedAbsoluteURL
            guard
                let localPath = media.localThumbnailURL,
                let localURL = URL(string: localPath),
                let absoluteURL = media.absoluteThumbnailLocalURL
                else {
                    XCTFail("Error building expected absolute thumbnail URL: \(expectedAbsoluteURL)")
                    return
            }
            XCTAssert(localURL.lastPathComponent == expectedAbsoluteURL.lastPathComponent, "Error: unexpected local thumbnail Media URL")
            XCTAssert(absoluteURL == expectedAbsoluteURL, "Error: unexpected absolute thumbnail Media URL")
        } catch {
            XCTFail("Error testing absolute thumbnail URLs: \(error)")
        }
    }

    func testMediaHasAssociatedPost() {
        let post = PostBuilder(mainContext).build()
        let media = newTestMedia()
        media.addPostsObject(post)

        XCTAssertTrue(media.hasAssociatedPost())
    }

    func testMediaHasntAssociatedPost() {
        let media = newTestMedia()

        XCTAssertFalse(media.hasAssociatedPost())
    }

    // MARK: - AutoUpload Failure Count

    func testThatIncrementAutoUploadFailureCountWorks() {
        let media = newTestMedia()

        XCTAssertEqual(media.autoUploadFailureCount, 0)

        media.incrementAutoUploadFailureCount()
        XCTAssertEqual(media.autoUploadFailureCount, 1)

        media.incrementAutoUploadFailureCount()
        XCTAssertEqual(media.autoUploadFailureCount, 2)
    }

    func testThatResetAutoUploadFailureCountWorks() {
        let media = newTestMedia()

        media.incrementAutoUploadFailureCount()
        media.incrementAutoUploadFailureCount()

        media.resetAutoUploadFailureCount()
        XCTAssertEqual(media.autoUploadFailureCount, 0)
    }

    // MARK: - File Extension

    func testFileExtensionFromFilename() {
        let media = newTestMedia()
        media.filename = "photo.jpeg"

        XCTAssertEqual(media.fileExtension(), "jpeg")
    }

    func testFileExtensionFallsBackToLocalURL() {
        let media = newTestMedia()
        media.filename = nil
        media.localURL = "photo.png"

        XCTAssertEqual(media.fileExtension(), "png")
    }

    func testFileExtensionFallsBackToRemoteURL() {
        let media = newTestMedia()
        media.filename = nil
        media.localURL = nil
        media.remoteURL = "https://example.com/photo.gif"

        XCTAssertEqual(media.fileExtension(), "gif")
    }

    func testFileExtensionReturnsEmptyStringWhenNothingIsSet() {
        let media = newTestMedia()

        XCTAssertEqual(media.fileExtension(), "")
    }

    // MARK: - Has Remote

    func testHasRemoteWhenMediaIDIsSet() {
        let media = newTestMedia()
        media.mediaID = 123

        XCTAssertTrue(media.hasRemote)
    }

    // MARK: - Prepare for Deletion

    func testPrepareForDeletionRemovesLocalFiles() throws {
        let media = newTestMedia()

        // Create a temporary file in the uploads directory
        let uploadsDirectory = try MediaFileManager.uploadsDirectoryURL()
        let localFileURL = uploadsDirectory.appendingPathComponent("test-delete-\(UUID().uuidString).jpeg")
        try Data("test".utf8).write(to: localFileURL)
        media.absoluteLocalURL = localFileURL

        // Create a temporary file in the cache directory
        let cacheDirectory = try MediaFileManager.cache.directoryURL()
        let thumbnailFileURL = cacheDirectory.appendingPathComponent("test-thumb-\(UUID().uuidString).jpeg")
        try Data("test".utf8).write(to: thumbnailFileURL)
        media.absoluteThumbnailLocalURL = thumbnailFileURL

        XCTAssertTrue(FileManager.default.fileExists(atPath: localFileURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: thumbnailFileURL.path))

        // When
        mainContext.delete(media)
        try mainContext.save()

        // Then
        XCTAssertFalse(FileManager.default.fileExists(atPath: localFileURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: thumbnailFileURL.path))
    }

    // MARK: - Set Error (Secure Coding)

    func testSetErrorSanitizesUserInfo() {
        let media = newTestMedia()
        let originalError = NSError(
            domain: "TestDomain",
            code: 42,
            userInfo: [
                NSLocalizedDescriptionKey: "Something went wrong",
                "UnsafeKey": NSObject()
            ]
        )

        media.error = originalError

        let storedError = media.error! as NSError
        XCTAssertEqual(storedError.domain, "TestDomain")
        XCTAssertEqual(storedError.code, 42)
        XCTAssertEqual(storedError.localizedDescription, "Something went wrong")
        XCTAssertEqual(storedError.userInfo.count, 1)
        XCTAssertNotNil(storedError.userInfo[NSLocalizedDescriptionKey])
    }

    func testSetErrorWithNil() {
        let media = newTestMedia()
        media.error = NSError(domain: "Test", code: 1)

        media.error = nil

        XCTAssertNil(media.error)
    }

    // MARK: - Media Type

    func testMimeType() {
        // Given
        let media = newTestMedia()
        media.filename = "file.png"

        // Then MIME type is derived from the file extension
        XCTAssertEqual(media.mimeType, "image/png")
    }

    func testMimeTypeUnknown() {
        // Given
        let media = newTestMedia()
        media.filename = "file.there-goes-nothing"

        // Then
        XCTAssertEqual(media.mimeType, "application/octet-stream")
    }

    // MARK: - Set Media Type (MIME Type)

    func testSetMediaTypeForMimeTypeImage() {
        // Given
        let media = newTestMedia()

        // When
        media.setMediaType(forMimeType: "image/png")

        // Then
        XCTAssertEqual(media.mediaType, .image)
    }

    func testSetMediaTypeForMimeTypeVideo() {
        // Given
        let media = newTestMedia()

        // When
        media.setMediaType(forMimeType: "video/mp4")

        // Then
        XCTAssertEqual(media.mediaType, .video)
    }

    func testSetMediaTypeForMimeTypeVideopress() {
        // Given
        let media = newTestMedia()

        // When
        media.setMediaType(forMimeType: "video/videopress")

        // Then Media has special handling for this custom MIME type
        XCTAssertEqual(media.mediaType, .video)
    }

    func testSetMediaTypeForMimeTypeUnknown() {
        // Given
        let media = newTestMedia()

        // When
        media.setMediaType(forMimeType: "unknown/unknown")

        // Then falls bac
        XCTAssertEqual(media.mediaType, .document)
    }

    // MARK: - Set Media Type (File Extension)

    func testSetMediaTypeForPathExtensionPNG() {
        // Given
        let media = newTestMedia()

        // When
        media.setMediaType(forFilenameExtension: "png")

        // Then
        XCTAssertEqual(media.mediaType, .image)
    }

    func testSetMediaTypeForPathExtensionMP4() {
        // Given
        let media = newTestMedia()

        // When
        media.setMediaType(forFilenameExtension: "mp4")

        // Then
        XCTAssertEqual(media.mediaType, .video)
    }

    func testSetMediaTypeForPathExtensionUnknown() {
        // Given
        let media = newTestMedia()

        // When
        media.setMediaType(forFilenameExtension: "hello")

        // Then
        XCTAssertEqual(media.mediaType, .document)
    }
}
