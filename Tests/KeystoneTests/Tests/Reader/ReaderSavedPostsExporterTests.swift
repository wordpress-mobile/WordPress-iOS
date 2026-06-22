import XCTest
import WordPressData

@testable import WordPress

class ReaderSavedPostsExporterTests: CoreDataTestCase {

    private let exporter = ReaderSavedPostsExporter()

    // MARK: - Export

    func testExportReturnsNilWhenNoSavedPosts() async throws {
        let result = try await exporter.export(coreDataStack: contextManager)
        XCTAssertNil(result)
    }

    func testExportReturnsNilWhenPostsExistButNoneAreSaved() async throws {
        let post = makeReaderPost()
        post.isSavedForLater = false
        try mainContext.save()

        let result = try await exporter.export(coreDataStack: contextManager)
        XCTAssertNil(result)
    }

    func testExportCreatesJSONFileWithSavedPosts() async throws {
        let post = makeReaderPost()
        post.postTitle = "Test Post"
        post.permaLink = "https://example.com/test-post"
        post.authorDisplayName = "Jane Doe"
        post.blogName = "Example Blog"
        post.blogURL = "https://example.com"
        post.summary = "A short summary"
        post.featuredImage = "https://example.com/image.jpg"
        post.tags = "swift, ios"
        post.siteID = 12345
        post.postID = 67890
        post.isExternal = false
        post.isSavedForLater = true
        post.sortDate = Date(timeIntervalSince1970: 1000000)
        post.date_created_gmt = Date(timeIntervalSince1970: 1000000)
        try mainContext.save()

        let url = try await exporter.export(coreDataStack: contextManager)
        let fileURL = try XCTUnwrap(url)

        let data = try Data(contentsOf: fileURL)
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(envelope["postCount"] as? Int, 1)
        XCTAssertNotNil(envelope["exportDate"])

        let posts = try XCTUnwrap(envelope["posts"] as? [[String: Any]])
        XCTAssertEqual(posts.count, 1)

        let exported = posts[0]
        XCTAssertEqual(exported["title"] as? String, "Test Post")
        XCTAssertEqual(exported["url"] as? String, "https://example.com/test-post")
        XCTAssertEqual(exported["author"] as? String, "Jane Doe")
        XCTAssertEqual(exported["siteName"] as? String, "Example Blog")
        XCTAssertEqual(exported["siteURL"] as? String, "https://example.com")
        XCTAssertEqual(exported["summary"] as? String, "A short summary")
        XCTAssertEqual(exported["featuredImageURL"] as? String, "https://example.com/image.jpg")
        XCTAssertEqual(exported["tags"] as? [String], ["swift", "ios"])
        XCTAssertEqual((exported["siteID"] as? NSNumber)?.intValue, 12345)
        XCTAssertEqual((exported["postID"] as? NSNumber)?.intValue, 67890)
        XCTAssertEqual(exported["isFeed"] as? Bool, false)
    }

    func testExportOnlyIncludesSavedPosts() async throws {
        let saved = makeReaderPost()
        saved.postTitle = "Saved"
        saved.permaLink = "https://example.com/saved"
        saved.isSavedForLater = true
        saved.sortDate = Date()

        let unsaved = makeReaderPost()
        unsaved.postTitle = "Unsaved"
        unsaved.permaLink = "https://example.com/unsaved"
        unsaved.isSavedForLater = false
        unsaved.sortDate = Date()

        try mainContext.save()

        let url = try await exporter.export(coreDataStack: contextManager)
        let fileURL = try XCTUnwrap(url)
        let data = try Data(contentsOf: fileURL)
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let posts = try XCTUnwrap(envelope["posts"] as? [[String: Any]])

        XCTAssertEqual(posts.count, 1)
        XCTAssertEqual(posts[0]["title"] as? String, "Saved")
    }

    func testExportOmitsEmptyOptionalFields() async throws {
        let post = makeReaderPost()
        post.permaLink = "https://example.com/minimal"
        post.isSavedForLater = true
        post.sortDate = Date()
        try mainContext.save()

        let url = try await exporter.export(coreDataStack: contextManager)
        let fileURL = try XCTUnwrap(url)
        let data = try Data(contentsOf: fileURL)
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let posts = try XCTUnwrap(envelope["posts"] as? [[String: Any]])
        let exported = posts[0]

        XCTAssertNil(exported["featuredImageURL"])
        XCTAssertNil(exported["tags"])
    }

    func testExportFileNameContainsDate() async throws {
        let post = makeReaderPost()
        post.permaLink = "https://example.com/test"
        post.isSavedForLater = true
        post.sortDate = Date()
        try mainContext.save()

        let url = try await exporter.export(coreDataStack: contextManager)
        let fileURL = try XCTUnwrap(url)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())

        XCTAssertTrue(fileURL.lastPathComponent.contains(todayString))
        XCTAssertEqual(fileURL.pathExtension, "json")
    }

    // MARK: - parseExportFile

    func testParseExportFileReturnsPosts() throws {
        let envelope = ReaderSavedPostsExporter.Envelope(
            exportDate: "2026-04-23",
            postCount: 2,
            posts: [
                makeExportedPost(url: "https://example.com/1", siteID: 100, postID: 1),
                makeExportedPost(url: "https://example.com/2", siteID: 200, postID: 2)
            ],
            appVersion: "Test 1.0"
        )
        let fileURL = try writeEnvelopeToTempFile(envelope)
        let posts = try ReaderSavedPostsExporter.parseExportFile(at: fileURL)

        XCTAssertEqual(posts.count, 2)
        XCTAssertEqual(posts[0].url, "https://example.com/1")
    }

    func testParseExportFileThrowsForInvalidFormat() throws {
        let json: [String: Any] = ["notPosts": true]
        let fileURL = try writeJSONToTempFile(json)

        XCTAssertThrowsError(try ReaderSavedPostsExporter.parseExportFile(at: fileURL))
    }

    func testParseExportFileThrowsForNonJSON() throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("bad-\(UUID().uuidString).json")
        try "not json".write(to: fileURL, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try ReaderSavedPostsExporter.parseExportFile(at: fileURL))
    }

    // MARK: - Import filtering

    func testImportSkipsPostsAlreadySaved() async throws {
        let existing = makeReaderPost()
        existing.permaLink = "https://example.com/already-saved"
        existing.isSavedForLater = true
        existing.sortDate = Date()
        try mainContext.save()

        let posts = [makeExportedPost(url: "https://example.com/already-saved", siteID: 100, postID: 1)]

        let result = await ReaderSavedPostsExporter.importPosts(
            posts,
            coreDataStack: contextManager,
            progress: Progress()
        )

        XCTAssertEqual(result.imported, 0)
        XCTAssertEqual(result.skipped, 1)
        XCTAssertEqual(result.failed, 0)
    }

    func testImportSkipsPostsWithMissingSiteID() async {
        let posts = [makeExportedPost(url: "https://example.com/no-site", siteID: nil, postID: 1)]

        let result = await ReaderSavedPostsExporter.importPosts(
            posts,
            coreDataStack: contextManager,
            progress: Progress()
        )

        XCTAssertEqual(result.imported, 0)
        XCTAssertEqual(result.skipped, 1)
        XCTAssertEqual(result.failed, 0)
    }

    func testImportSkipsPostsWithMissingPostID() async {
        let posts = [makeExportedPost(url: "https://example.com/no-post-id", siteID: 100, postID: nil)]

        let result = await ReaderSavedPostsExporter.importPosts(
            posts,
            coreDataStack: contextManager,
            progress: Progress()
        )

        XCTAssertEqual(result.imported, 0)
        XCTAssertEqual(result.skipped, 1)
        XCTAssertEqual(result.failed, 0)
    }

    func testImportSkipsPostsWithEmptyURL() async {
        let posts = [makeExportedPost(url: "", siteID: 100, postID: 1)]

        let result = await ReaderSavedPostsExporter.importPosts(
            posts,
            coreDataStack: contextManager,
            progress: Progress()
        )

        XCTAssertEqual(result.imported, 0)
        XCTAssertEqual(result.skipped, 1)
        XCTAssertEqual(result.failed, 0)
    }

    func testImportReturnsEmptyResultForEmptyPostsList() async {
        let result = await ReaderSavedPostsExporter.importPosts(
            [],
            coreDataStack: contextManager,
            progress: Progress()
        )

        XCTAssertEqual(result.imported, 0)
        XCTAssertEqual(result.skipped, 0)
        XCTAssertEqual(result.failed, 0)
    }

    // MARK: - Round-trip (export -> parse)

    func testExportThenParsePreservesAllFields() async throws {
        let post = makeReaderPost()
        post.postTitle = "Round Trip"
        post.permaLink = "https://example.com/round-trip"
        post.authorDisplayName = "Author"
        post.blogName = "Blog"
        post.blogURL = "https://blog.example.com"
        post.summary = "Summary text"
        post.featuredImage = "https://example.com/img.jpg"
        post.tags = "tag1, tag2"
        post.siteID = 999
        post.postID = 888
        post.isExternal = false
        post.isSavedForLater = true
        post.sortDate = Date()
        post.date_created_gmt = Date(timeIntervalSince1970: 1700000000)
        try mainContext.save()

        let url = try await exporter.export(coreDataStack: contextManager)
        let fileURL = try XCTUnwrap(url)
        let posts = try ReaderSavedPostsExporter.parseExportFile(at: fileURL)

        XCTAssertEqual(posts.count, 1)
        let exported = posts[0]
        XCTAssertEqual(exported.title, "Round Trip")
        XCTAssertEqual(exported.url, "https://example.com/round-trip")
        XCTAssertEqual(exported.author, "Author")
        XCTAssertEqual(exported.siteName, "Blog")
        XCTAssertEqual(exported.siteURL, "https://blog.example.com")
        XCTAssertEqual(exported.summary, "Summary text")
        XCTAssertEqual(exported.featuredImageURL, "https://example.com/img.jpg")
        XCTAssertEqual(exported.tags, ["tag1", "tag2"])
        XCTAssertEqual(exported.siteID, 999)
        XCTAssertEqual(exported.postID, 888)
        XCTAssertNil(exported.feedID)
        XCTAssertNil(exported.feedItemID)
        XCTAssertEqual(exported.isFeed, false)
        XCTAssertNotNil(exported.date)
    }

    func testExportFeedPostUsesFeedIdentifiers() async throws {
        let post = makeReaderPost()
        post.postTitle = "Feed Item"
        post.permaLink = "https://feeds.example.com/item"
        post.feedID = 42
        post.feedItemID = 7
        post.isExternal = true
        post.isSavedForLater = true
        post.sortDate = Date()
        try mainContext.save()

        let url = try await exporter.export(coreDataStack: contextManager)
        let fileURL = try XCTUnwrap(url)
        let posts = try ReaderSavedPostsExporter.parseExportFile(at: fileURL)

        XCTAssertEqual(posts.count, 1)
        let exported = posts[0]
        XCTAssertEqual(exported.isFeed, true)
        XCTAssertEqual(exported.feedID, 42)
        XCTAssertEqual(exported.feedItemID, 7)
        XCTAssertNil(exported.siteID)
        XCTAssertNil(exported.postID)
    }

    func testImportSkipsFeedPostWithMissingFeedIdentifiers() async {
        let posts = [
            makeExportedPost(
                url: "https://feeds.example.com/missing",
                siteID: nil,
                postID: nil,
                isFeed: true
            )
        ]

        let result = await ReaderSavedPostsExporter.importPosts(
            posts,
            coreDataStack: contextManager,
            progress: Progress()
        )

        XCTAssertEqual(result.imported, 0)
        XCTAssertEqual(result.skipped, 1)
        XCTAssertEqual(result.failed, 0)
    }
}

// MARK: - Helpers

private extension ReaderSavedPostsExporterTests {
    func makeReaderPost() -> ReaderPost {
        NSEntityDescription.insertNewObject(
            forEntityName: "ReaderPost",
            into: mainContext
        ) as! ReaderPost
    }

    func makeExportedPost(
        url: String,
        siteID: UInt?,
        postID: UInt?,
        feedID: UInt? = nil,
        feedItemID: UInt? = nil,
        isFeed: Bool = false
    ) -> ReaderSavedPostsExporter.ExportedPost {
        ReaderSavedPostsExporter.ExportedPost(
            title: "",
            url: url,
            author: "",
            siteName: "",
            siteURL: "",
            date: nil,
            summary: "",
            tags: nil,
            featuredImageURL: nil,
            siteID: siteID,
            postID: postID,
            feedID: feedID,
            feedItemID: feedItemID,
            isFeed: isFeed
        )
    }

    func writeJSONToTempFile(_ json: [String: Any]) throws -> URL {
        let data = try JSONSerialization.data(withJSONObject: json)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        try data.write(to: fileURL)
        return fileURL
    }

    func writeEnvelopeToTempFile(_ envelope: ReaderSavedPostsExporter.Envelope) throws -> URL {
        let data = try JSONEncoder().encode(envelope)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        try data.write(to: fileURL)
        return fileURL
    }
}
