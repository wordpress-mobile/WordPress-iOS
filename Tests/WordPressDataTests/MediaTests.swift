import Testing
import Foundation
@testable import WordPressData

@MainActor
struct MediaTests {

    private let context = ContextManager.forTesting().mainContext

    private func newTestMedia() -> Media {
        NSEntityDescription.insertNewObject(forEntityName: Media.entityName(), into: context) as! Media
    }

    // MARK: - Absolute URLs

    @Test("Absolute local URL round-trips through uploads directory")
    func absoluteLocalURL() throws {
        let media = newTestMedia()
        let filePath = "sample.jpeg"
        var expectedAbsoluteURL = try MediaFileManager.uploadsDirectoryURL()
        expectedAbsoluteURL.appendPathComponent(filePath)
        media.absoluteLocalURL = expectedAbsoluteURL

        let localPath = try #require(media.localURL)
        let localURL = try #require(URL(string: localPath))
        let absoluteURL = try #require(media.absoluteLocalURL)

        #expect(localURL.lastPathComponent == expectedAbsoluteURL.lastPathComponent)
        #expect(absoluteURL == expectedAbsoluteURL)
    }

    @Test("Absolute thumbnail URL round-trips through cache directory")
    func absoluteThumbnailLocalURL() throws {
        let media = newTestMedia()
        let filePath = "sample-thumbnail.jpeg"
        var expectedAbsoluteURL = try MediaFileManager.cache.directoryURL()
        expectedAbsoluteURL.appendPathComponent(filePath)
        media.absoluteThumbnailLocalURL = expectedAbsoluteURL

        let localPath = try #require(media.localThumbnailURL)
        let localURL = try #require(URL(string: localPath))
        let absoluteURL = try #require(media.absoluteThumbnailLocalURL)

        #expect(localURL.lastPathComponent == expectedAbsoluteURL.lastPathComponent)
        #expect(absoluteURL == expectedAbsoluteURL)
    }

    // MARK: - Associated Post

    @Test("Has associated post when posts set is non-empty")
    func hasAssociatedPost() {
        let post = PostBuilder(context).build()
        let media = newTestMedia()
        media.addPostsObject(post)

        #expect(media.hasAssociatedPost())
    }

    @Test("Has no associated post when posts set is empty")
    func hasNoAssociatedPost() {
        let media = newTestMedia()

        #expect(!media.hasAssociatedPost())
    }

    // MARK: - AutoUpload Failure Count

    @Test("Incrementing auto-upload failure count")
    func incrementAutoUploadFailureCount() {
        let media = newTestMedia()

        #expect(media.autoUploadFailureCount == 0)

        media.incrementAutoUploadFailureCount()
        #expect(media.autoUploadFailureCount == 1)

        media.incrementAutoUploadFailureCount()
        #expect(media.autoUploadFailureCount == 2)
    }

    @Test("Resetting auto-upload failure count")
    func resetAutoUploadFailureCount() {
        let media = newTestMedia()

        media.incrementAutoUploadFailureCount()
        media.incrementAutoUploadFailureCount()

        media.resetAutoUploadFailureCount()
        #expect(media.autoUploadFailureCount == 0)
    }

    // MARK: - File Extension

    @Test("File extension from filename")
    func fileExtensionFromFilename() {
        let media = newTestMedia()
        media.filename = "photo.jpeg"

        #expect(media.fileExtension() == "jpeg")
    }

    @Test("File extension falls back to localURL")
    func fileExtensionFallsBackToLocalURL() {
        let media = newTestMedia()
        media.filename = nil
        media.localURL = "photo.png"

        #expect(media.fileExtension() == "png")
    }

    @Test("File extension falls back to remoteURL")
    func fileExtensionFallsBackToRemoteURL() {
        let media = newTestMedia()
        media.filename = nil
        media.localURL = nil
        media.remoteURL = "https://example.com/photo.gif"

        #expect(media.fileExtension() == "gif")
    }

    @Test("File extension returns nil when nothing is set")
    func fileExtensionEmpty() {
        let media = newTestMedia()

        #expect(media.fileExtension() == nil)
    }

    // MARK: - Has Remote

    @Test("hasRemote is true when mediaID is set")
    func hasRemote() {
        let media = newTestMedia()
        media.mediaID = 123

        #expect(media.hasRemote)
    }

    // MARK: - Prepare for Deletion

    @Test("Deleting media removes local files from disk")
    func prepareForDeletionRemovesLocalFiles() throws {
        let media = newTestMedia()

        let uploadsDirectory = try MediaFileManager.uploadsDirectoryURL()
        let localFileURL = uploadsDirectory.appendingPathComponent("test-delete-\(UUID().uuidString).jpeg")
        try Data("test".utf8).write(to: localFileURL)
        media.absoluteLocalURL = localFileURL

        let cacheDirectory = try MediaFileManager.cache.directoryURL()
        let thumbnailFileURL = cacheDirectory.appendingPathComponent("test-thumb-\(UUID().uuidString).jpeg")
        try Data("test".utf8).write(to: thumbnailFileURL)
        media.absoluteThumbnailLocalURL = thumbnailFileURL

        #expect(FileManager.default.fileExists(atPath: localFileURL.path))
        #expect(FileManager.default.fileExists(atPath: thumbnailFileURL.path))

        context.delete(media)
        try context.save()

        #expect(!FileManager.default.fileExists(atPath: localFileURL.path))
        #expect(!FileManager.default.fileExists(atPath: thumbnailFileURL.path))
    }

    // MARK: - Set Error (Secure Coding)

    @Test("Setting error sanitizes userInfo to only NSLocalizedDescriptionKey")
    func setErrorSanitizesUserInfo() throws {
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

        let storedError = try #require(media.error as NSError?)
        #expect(storedError.domain == "TestDomain")
        #expect(storedError.code == 42)
        #expect(storedError.localizedDescription == "Something went wrong")
        #expect(storedError.userInfo.count == 1)
        #expect(storedError.userInfo[NSLocalizedDescriptionKey] != nil)
    }

    @Test("Setting error to nil clears it")
    func setErrorWithNil() {
        let media = newTestMedia()
        media.error = NSError(domain: "Test", code: 1)

        media.error = nil

        #expect(media.error == nil)
    }

    // MARK: - MIME Type

    @Test("MIME type is derived from file extension")
    func mimeType() {
        let media = newTestMedia()
        media.filename = "file.png"

        #expect(media.mimeType == "image/png")
    }

    @Test("MIME type falls back to application/octet-stream for unknown extension")
    func mimeTypeUnknown() {
        let media = newTestMedia()
        media.filename = "file.there-goes-nothing"

        #expect(media.mimeType == "application/octet-stream")
    }

    // MARK: - Set Media Type (MIME Type)

    @Test("Set media type from MIME type", arguments: [
        ("image/png", MediaType.image),
        ("video/mp4", MediaType.video),
        ("video/videopress", MediaType.video),
        ("unknown/unknown", MediaType.document),
    ])
    func setMediaTypeForMimeType(mimeType: String, expected: MediaType) {
        let media = newTestMedia()
        media.setMediaType(forMimeType: mimeType)
        #expect(media.mediaType == expected)
    }

    // MARK: - Set Media Type (File Extension)

    @Test("Set media type from file extension", arguments: [
        ("png", MediaType.image),
        ("mp4", MediaType.video),
        ("hello", MediaType.document),
    ])
    func setMediaTypeForFilenameExtension(ext: String, expected: MediaType) {
        let media = newTestMedia()
        media.setMediaType(forFilenameExtension: ext)
        #expect(media.mediaType == expected)
    }
}
