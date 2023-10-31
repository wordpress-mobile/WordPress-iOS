import XCTest
@testable import WordPress

class MediaTests: CoreDataTestCase {

    fileprivate func newTestMedia() -> Media {
        return NSEntityDescription.insertNewObject(forEntityName: Media.classNameWithoutNamespaces(), into: mainContext) as! Media
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

    func testMediaCount() {
        let blog = BlogBuilder(mainContext).build()
        let addMedia: (MediaType, Int) -> Void = { type, count in
            for _ in 1...count {
                let media = self.newTestMedia()
                media.mediaType = type
                media.blog = blog
            }
        }
        addMedia(.image, 1)
        addMedia(.video, 2)
        addMedia(.document, 3)
        addMedia(.powerpoint, 4)
        addMedia(.audio, 5)
        contextManager.saveContextAndWait(mainContext)

        XCTAssertEqual(blog.mediaLibraryCount(types: [MediaType.image.rawValue]), 1)
        XCTAssertEqual(blog.mediaLibraryCount(types: [MediaType.video.rawValue]), 2)
        XCTAssertEqual(blog.mediaLibraryCount(types: [MediaType.document.rawValue]), 3)
        XCTAssertEqual(blog.mediaLibraryCount(types: [MediaType.powerpoint.rawValue]), 4)
        XCTAssertEqual(blog.mediaLibraryCount(types: [MediaType.audio.rawValue]), 5)

        XCTAssertEqual(blog.mediaLibraryCount(types: [MediaType.image.rawValue, MediaType.video.rawValue]), 3)
        XCTAssertEqual(blog.mediaLibraryCount(types: [MediaType.audio.rawValue, MediaType.powerpoint.rawValue]), 9)
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
