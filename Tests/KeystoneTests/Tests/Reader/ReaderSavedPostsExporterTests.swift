import XCTest
import WordPressData

@testable import WordPress

class ReaderSavedPostsExporterTests: CoreDataTestCase {

    private let exporter = ReaderSavedPostsExporter()

    // MARK: - Export

    func testExportReturnsNilWhenNoSavedPosts() throws {
        let result = try exporter.export(context: mainContext)
        XCTAssertNil(result)
    }

    func testExportReturnsNilWhenPostsExistButNoneAreSaved() throws {
        let post = makeReaderPost()
        post.isSavedForLater = false
        try mainContext.save()

        let result = try exporter.export(context: mainContext)
        XCTAssertNil(result)
    }

    func testExportCreatesJSONFileWithSavedPosts() throws {
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

        let fileURL = try XCTUnwrap(exporter.export(context: mainContext))

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

    func testExportOnlyIncludesSavedPosts() throws {
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

        let fileURL = try XCTUnwrap(exporter.export(context: mainContext))
        let data = try Data(contentsOf: fileURL)
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let posts = try XCTUnwrap(envelope["posts"] as? [[String: Any]])

        XCTAssertEqual(posts.count, 1)
        XCTAssertEqual(posts[0]["title"] as? String, "Saved")
    }

    func testExportOmitsEmptyOptionalFields() throws {
        let post = makeReaderPost()
        post.permaLink = "https://example.com/minimal"
        post.isSavedForLater = true
        post.sortDate = Date()
        try mainContext.save()

        let fileURL = try XCTUnwrap(exporter.export(context: mainContext))
        let data = try Data(contentsOf: fileURL)
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let posts = try XCTUnwrap(envelope["posts"] as? [[String: Any]])
        let exported = posts[0]

        XCTAssertNil(exported["featuredImageURL"])
        XCTAssertNil(exported["tags"])
    }

    func testExportFileNameContainsDate() throws {
        let post = makeReaderPost()
        post.permaLink = "https://example.com/test"
        post.isSavedForLater = true
        post.sortDate = Date()
        try mainContext.save()

        let fileURL = try XCTUnwrap(exporter.export(context: mainContext))

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())

        XCTAssertTrue(fileURL.lastPathComponent.contains(todayString))
        XCTAssertEqual(fileURL.pathExtension, "json")
    }

    // MARK: - parseExportFile

    func testParseExportFileReturnsPostDicts() throws {
        let json: [String: Any] = [
            "exportDate": "2026-04-23",
            "postCount": 2,
            "posts": [
                ["url": "https://example.com/1", "siteID": 100, "postID": 1],
                ["url": "https://example.com/2", "siteID": 200, "postID": 2]
            ]
        ]
        let fileURL = try writeJSONToTempFile(json)
        let postDicts = try ReaderSavedPostsExporter.parseExportFile(at: fileURL)

        XCTAssertEqual(postDicts.count, 2)
        XCTAssertEqual(postDicts[0]["url"] as? String, "https://example.com/1")
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

    func testImportSkipsPostsAlreadySaved() throws {
        let existing = makeReaderPost()
        existing.permaLink = "https://example.com/already-saved"
        existing.isSavedForLater = true
        existing.sortDate = Date()
        try mainContext.save()

        let postDicts: [[String: Any]] = [
            ["url": "https://example.com/already-saved", "siteID": 100, "postID": 1]
        ]

        let expectation = expectation(description: "import completes")
        ReaderSavedPostsExporter.importPosts(
            postDicts,
            coreDataStack: contextManager,
            progress: { _, _ in },
            completion: { result in
                XCTAssertEqual(result.imported, 0)
                XCTAssertEqual(result.skipped, 1)
                XCTAssertEqual(result.failed, 0)
                expectation.fulfill()
            }
        )

        wait(for: [expectation], timeout: 1.0)
    }

    func testImportSkipsPostsWithMissingSiteID() {
        let postDicts: [[String: Any]] = [
            ["url": "https://example.com/no-site", "postID": 1]
        ]

        let expectation = expectation(description: "import completes")
        ReaderSavedPostsExporter.importPosts(
            postDicts,
            coreDataStack: contextManager,
            progress: { _, _ in },
            completion: { result in
                XCTAssertEqual(result.imported, 0)
                XCTAssertEqual(result.skipped, 1)
                XCTAssertEqual(result.failed, 0)
                expectation.fulfill()
            }
        )

        wait(for: [expectation], timeout: 1.0)
    }

    func testImportSkipsPostsWithMissingPostID() {
        let postDicts: [[String: Any]] = [
            ["url": "https://example.com/no-post-id", "siteID": 100]
        ]

        let expectation = expectation(description: "import completes")
        ReaderSavedPostsExporter.importPosts(
            postDicts,
            coreDataStack: contextManager,
            progress: { _, _ in },
            completion: { result in
                XCTAssertEqual(result.imported, 0)
                XCTAssertEqual(result.skipped, 1)
                XCTAssertEqual(result.failed, 0)
                expectation.fulfill()
            }
        )

        wait(for: [expectation], timeout: 1.0)
    }

    func testImportSkipsPostsWithEmptyURL() {
        let postDicts: [[String: Any]] = [
            ["url": "", "siteID": 100, "postID": 1]
        ]

        let expectation = expectation(description: "import completes")
        ReaderSavedPostsExporter.importPosts(
            postDicts,
            coreDataStack: contextManager,
            progress: { _, _ in },
            completion: { result in
                XCTAssertEqual(result.imported, 0)
                XCTAssertEqual(result.skipped, 1)
                XCTAssertEqual(result.failed, 0)
                expectation.fulfill()
            }
        )

        wait(for: [expectation], timeout: 1.0)
    }

    func testImportReturnsEmptyResultForEmptyPostsList() {
        let expectation = expectation(description: "import completes")
        ReaderSavedPostsExporter.importPosts(
            [],
            coreDataStack: contextManager,
            progress: { _, _ in },
            completion: { result in
                XCTAssertEqual(result.imported, 0)
                XCTAssertEqual(result.skipped, 0)
                XCTAssertEqual(result.failed, 0)
                expectation.fulfill()
            }
        )

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Round-trip (export -> parse)

    func testExportThenParsePreservesAllFields() throws {
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
        post.isExternal = true
        post.isSavedForLater = true
        post.sortDate = Date()
        post.date_created_gmt = Date(timeIntervalSince1970: 1700000000)
        try mainContext.save()

        let fileURL = try XCTUnwrap(exporter.export(context: mainContext))
        let postDicts = try ReaderSavedPostsExporter.parseExportFile(at: fileURL)

        XCTAssertEqual(postDicts.count, 1)
        let dict = postDicts[0]
        XCTAssertEqual(dict["title"] as? String, "Round Trip")
        XCTAssertEqual(dict["url"] as? String, "https://example.com/round-trip")
        XCTAssertEqual(dict["author"] as? String, "Author")
        XCTAssertEqual(dict["siteName"] as? String, "Blog")
        XCTAssertEqual(dict["siteURL"] as? String, "https://blog.example.com")
        XCTAssertEqual(dict["summary"] as? String, "Summary text")
        XCTAssertEqual(dict["featuredImageURL"] as? String, "https://example.com/img.jpg")
        XCTAssertEqual(dict["tags"] as? [String], ["tag1", "tag2"])
        XCTAssertEqual((dict["siteID"] as? NSNumber)?.intValue, 999)
        XCTAssertEqual((dict["postID"] as? NSNumber)?.intValue, 888)
        XCTAssertEqual(dict["isFeed"] as? Bool, true)
        XCTAssertNotNil(dict["date"])
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

    func writeJSONToTempFile(_ json: [String: Any]) throws -> URL {
        let data = try JSONSerialization.data(withJSONObject: json)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        try data.write(to: fileURL)
        return fileURL
    }
}
