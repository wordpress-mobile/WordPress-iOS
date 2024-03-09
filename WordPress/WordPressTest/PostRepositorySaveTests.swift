import XCTest
import OHHTTPStubs

@testable import WordPress

@MainActor
class PostRepositorySaveTests: CoreDataTestCase {
    private var blog: Blog!
    private var repository: PostRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()

        blog = BlogBuilder(mainContext)
            .with(dotComID: 80511)
            .withAnAccount()
            .build()
        try mainContext.save()

        repository = PostRepository(coreDataStack: contextManager)
    }

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()
    }

    // Scenario: user creates a new post and saves it as a draft.
    func testSaveNewDraft() async throws {
        // GIVEN a draft post (never synced)
        let creationDate = Date(timeIntervalSince1970: 1709852440)
        let post = PostBuilder(mainContext, blog: blog).build {
            $0.status = .draft
            $0.authorID = 29043
            $0.dateCreated = creationDate
            $0.postTitle = "Hello"
            $0.content = "content-1"
        }
        try mainContext.save()

        // GIVEN a server accepting the new post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            // THEN the app sends the post content (not ideal)
            try assertRequestBody(request, expected: """
            {
              "author" : 29043,
              "categories_by_id" : [

              ],
              "content" : "content-1",
              "date" : "2024-03-07T23:00:40+0000",
              "featured_image" : "",
              "parent" : "false",
              "password" : "",
              "status" : "draft",
              "sticky" : "false",
              "title" : "Hello",
              "type" : "post"
            }
            """)
            return try HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 201)
        }

        // WHEN
        try await repository._save(post)

        // THEN the post was created
        XCTAssertEqual(post.postID, 974)
        XCTAssertEqual(post.status, .draft)
    }

    // Scenario: user creates a new post and publishes it immediatelly.
    func testSaveNewDraftAndPublish() async throws {
        // GIVEN a draft post (never synced)
        let creationDate = Date(timeIntervalSince1970: 1709852440)
        let post = PostBuilder(mainContext, blog: blog).build {
            $0.status = .draft
            $0.authorID = 29043
            $0.dateCreated = creationDate
            $0.postTitle = "Hello"
            $0.content = "content-1"
        }
        try mainContext.save()

        // GIVEN a server accepting the new post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            // THEN the app sends the post content and amends the status
            try assertRequestBody(request, expected: """
            {
              "author" : 29043,
              "categories_by_id" : [

              ],
              "content" : "content-1",
              "date" : "2024-03-07T23:00:40+0000",
              "featured_image" : "",
              "parent" : "false",
              "password" : "",
              "status" : "publish",
              "sticky" : "false",
              "title" : "Hello",
              "type" : "post"
            }
            """)
            var post = WordPressComPost.mock
            post.status = PostStatusPublish
            return try HTTPStubsResponse(value: post, statusCode: 201)
        }

        // WHEN publishing a post
        let parameters = RemotePostUpdateParameters()
        parameters.status = PostStatusPublish
        try await repository._save(post, with: parameters)

        // THEN the post was created
        XCTAssertEqual(post.postID, 974)
        XCTAssertEqual(post.status, .publish)
    }

    func testPublishUnsyncedPost() async throws {
        XCTFail()
    }

    func testScheduleUnsyncedPost() async throws {
        // TODO: tset manually to make sure API accepts it
        XCTFail()
    }

    func testPublishSyncedDraft() async throws {
        // GIVEN a draft post (synced)
        let post = PostBuilder(mainContext, blog: blog).build {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = Date()
            $0.dateModified = Date()
            $0.postTitle = "Hello"
            $0.content = #"<!-- wp:paragraph -->\n<p>World</p>\n<!-- /wp:paragraph -->"#
        }
        try mainContext.save()

        // GIVEN a server configured to accept a patch
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update
            try assertRequestBody(request, expected: """
            {
              "status" : "publish"
            }
            """)
            let responseData = try Bundle.test.json(named: "remote-post")
            return HTTPStubsResponse(data: responseData, statusCode: 200, headers: nil)
        }

        // WHEN publishing the post
        let parameters = RemotePostUpdateParameters()
        parameters.status = PostStatusPublish
        try await repository._save(post, with: parameters)

        // THEN the post got published
        XCTAssertEqual(post.status, .publish)
    }

    // Scenario: user opens an editor to edit an existing draft, updates it,
    // and taps "Save".
    func testSaveLocalRevision() async throws {
        // GIVEN a draft post (synced)
        let dateModified = Date(timeIntervalSince1970: 1709852440)
        let post = PostBuilder(mainContext, blog: blog).build {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = dateModified
            $0.dateModified = dateModified
            $0.postTitle = "Hello"
            $0.content = "<!-- wp:paragraph -->\n<p>World</p>\n<!-- /wp:paragraph -->"
        }

        // GIVEN a local revision with an updated title
        let revision = post.createRevision()
        revision.postTitle = "new-title"

        try mainContext.save()
        XCTAssertNotNil(post.revision, "Revision is missing")

        // GIVEN a server where the post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update
            try assertRequestBody(request, expected: """
            {
              "if_not_modified_since" : "2024-03-07T23:00:40+0000",
              "title" : "new-title"
            }
            """)

            var post = WordPressComPost.mock
            post.title = "new-title"
            return try HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN saving the post
        try await repository._save(post)

        // THEN the title got updated
        XCTAssertEqual(post.postTitle, "new-title")
        // THEN the local revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertNil(revision.managedObjectContext)
    }

    func testSaveLocalRevisionOverwriteParameter() async throws {
        XCTFail("set revision.status to scheduled and move to draft instead")
    }

    // MARK: - Diff

    /// Scenario: user changes all possible fields using a local revision.
    func testSaveContentChangeEveryField() async throws {
        // GIVEN a draft post (synced)
        let dateModified = Date(timeIntervalSince1970: 1709852440)
        let post = PostBuilder(mainContext, blog: blog).build {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = dateModified
            $0.dateModified = dateModified
            $0.postTitle = "Hello"
            $0.content = "<!-- wp:paragraph -->\n<p>World</p>\n<!-- /wp:paragraph -->"
        }

        // GIVEN a local revision that updates all possible fields
        let revision = {
            let revision = post.createRevision()
            revision.status = .publish
            revision.dateCreated = dateModified.addingTimeInterval(10)
            revision.authorID = 948
            revision.postTitle = "title-b"
            revision.content = "content-b"
            revision.password = "123"
            revision.mt_excerpt = "excerpt-b"
            revision.wp_slug = "slug-b"
            revision.featuredImage = MediaBuilder(mainContext).build {
                $0.mediaID = 92
            }

            let post = try XCTUnwrap(revision as Post)
            post.addCategories([{
                let category = PostCategory(context: mainContext)
                category.categoryID = 53
                category.categoryName = "test-category"
                return category
            }()])
            post.isStickyPost = true

            return revision
        }()

        try mainContext.save()
        XCTAssertNotNil(post.revision, "Revision is missing")

        // GIVEN a server where the post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update
            try assertRequestBody(request, expected: """
            {
              "if_not_modified_since" : "2024-03-07T23:00:40+0000",
              "title" : "new-title"
            }
            """)

            var post = WordPressComPost.mock
            post.title = "new-title"
            return try HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN saving the post
        try await repository._save(post)

        // THEN the title got updated
        XCTAssertEqual(post.postTitle, "new-title")
        // THEN the local revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertNil(revision.managedObjectContext)
    }

    // MARK: - 409 (Conflict)

    /// Scenario: user edits post's content, but the client is behind and the
    /// server has a new content, resulting in a data conflict. The user is
    /// presented with a conflict resolution dialog and picks the remote revision.
    func testSaveContentChangeClientBehindPickRemote() async throws {
        // GIVEN a draft post (client behind, server has "content-c")
        let clientDateModified = Date(timeIntervalSince1970: 1709852440).addingTimeInterval(-30)
        let serverDateModified = Date(timeIntervalSince1970: 1709852440)

        let post = PostBuilder(mainContext, blog: blog).build {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = clientDateModified
            $0.dateModified = clientDateModified
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a modified content
        let revision = post.createRevision()
        revision.content = "content-b"

        try mainContext.save()

        // GIVEN a server where the post is ahead and has a new content
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            let ifNotModifiedSince = try request.getIfNotModifiedSince()
            XCTAssert(ifNotModifiedSince < serverDateModified)
            return HTTPStubsResponse(jsonObject: [
                "error": "old-revision",
                "message": "There is a revision of this post that is more recent."
            ], statusCode: 409, headers: nil)
        }

        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974")) { request in
            var post = WordPressComPost.mock
            post.modified = serverDateModified
            post.content = "content-c"
            return try HTTPStubsResponse(value: post, statusCode: 200)
        }

        var latest: RemotePost!
        do {
            // WHEN
            try await repository._save(post, overwrite: false)
            XCTFail("Expected the request to fail")
        } catch {
            let error = try XCTUnwrap(error as? PostRepository.PostSaveError)
            // THEN expect a `.conlict` error
            switch error {
            case .conflict(let value):
                latest = value
            }
        }

        // WHEN the user resolves a conflict by picking the server revision
        try repository.resolveConflict(for: post, pickingRemoteRevision: latest)

        // THEN the content got updated to the server's version
        XCTAssertEqual(post.content, "content-c")
        // THEN the local revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertNil(revision.managedObjectContext)
    }

    /// Scenario: user edits post's content, but the client is behind and the
    /// server has a new content, resulting in a data conflict. The user is
    /// presented with a conflict resolution dialog and picks the local revision
    /// and retries the save.
    func testSaveContentChangeClientBehindPickLocal() async throws {
        // GIVEN a draft post (client behind, server has "content-c")
        let clientDateModified = Date(timeIntervalSince1970: 1709852440)
        let serverDateModified = Date(timeIntervalSince1970: 1709852440)
            .addingTimeInterval(30)

        let post = PostBuilder(mainContext, blog: blog).build {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = clientDateModified
            $0.dateModified = clientDateModified
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a modified content
        let revision = post.createRevision()
        revision.content = "content-b"

        try mainContext.save()

        // GIVEN server revision that's ahead and has new `title` and `content`
        let serverPost = {
            var post = WordPressComPost.mock
            post.modified = serverDateModified
            // WHEN server also has new tilte
            post.title = "title-c"
            post.content = "content-c"
            return post
        }()

        var requestCount = 0
        // GIVEN a server where the post is ahead and has a new content
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            requestCount += 1

            if requestCount == 1 {
                // THEN the first request contains an `if_not_modified_since` parameter
                try assertRequestBody(request, expected: """
                {
                  "content" : "content-b",
                  "if_not_modified_since" : "2024-03-07T23:00:40+0000"
                }
                """)
                // GIVEN the first request fails with 409 (Conflict)
                let ifNotModifiedSince = try request.getIfNotModifiedSince()
                XCTAssertTrue(ifNotModifiedSince < serverDateModified)
                return HTTPStubsResponse(jsonObject: [
                    "error": "old-revision",
                    "message": "There is a revision of this post that is more recent."
                ], statusCode: 409, headers: nil)
            }
            if requestCount == 2 {
                // THEN the second request contains only the delta
                try assertRequestBody(request, expected: """
                {
                  "content" : "content-b"
                }
                """)
                var serverPost = serverPost
                serverPost.content = "content-b"
                return try HTTPStubsResponse(value: serverPost, statusCode: 200)
            }

            throw URLError(.unknown)
        }

        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974")) { request in
            try HTTPStubsResponse(value: serverPost, statusCode: 200)
        }

        do {
            // WHEN
            try await repository._save(post, overwrite: false)
            XCTFail("Expected the request to fail")
        } catch {
            let error = try XCTUnwrap(error as? PostRepository.PostSaveError)
            // THEN expect a `.conlict` error
            switch error {
            case .conflict:
                break
            }
        }

        // WHEN the user picks the remote version and overwrites what's on the remote
        try await repository._save(post, overwrite: true)

        // THEN the content got updated to the version from the local revision
        XCTAssertEqual(post.content, "content-b")
        // THEN the rest of the changes are consolidated on the server and the
        // new changes made elsewhere are not overwritten thanks to the detla update
        XCTAssertEqual(post.postTitle, "title-c")
        // THEN the local revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertNil(revision.managedObjectContext)
    }

    /// Scenario: user edits post's content, but the client is behind and the
    /// server has a new revision but it has the same content as the original
    /// local post, so the repository resolves the conflict automatically.
    func testSaveContentChangeClientBehindNoConflict() async throws {
        // GIVEN a draft post (client behind, server has "content-c")
        let clientDateModified = Date(timeIntervalSince1970: 1709852440)
        let serverDateModified = Date(timeIntervalSince1970: 1709852440)
            .addingTimeInterval(30)

        let post = PostBuilder(mainContext, blog: blog).build {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = clientDateModified
            $0.dateModified = clientDateModified
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a modified content
        let revision = post.createRevision()
        revision.content = "content-b"

        try mainContext.save()

        // GIVEN server revision that's ahead and has a new `title` but
        // the `content` is the same as the local original post
        let serverPost = {
            var post = WordPressComPost.mock
            post.modified = serverDateModified
            post.title = "title-c"
            post.content = "content-a"
            return post
        }()

        var requestCount = 0
        // GIVEN a server where the post is ahead and has a new content
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            requestCount += 1

            if requestCount == 1 {
                // THEN the first request contains an `if_not_modified_since` parameter
                try assertRequestBody(request, expected: """
                {
                  "content" : "content-b",
                  "if_not_modified_since" : "2024-03-07T23:00:40+0000"
                }
                """)
                // GIVEN the first request fails with 409 (Conflict)
                let ifNotModifiedSince = try request.getIfNotModifiedSince()
                XCTAssertTrue(ifNotModifiedSince < serverDateModified)
                return HTTPStubsResponse(jsonObject: [
                    "error": "old-revision",
                    "message": "There is a revision of this post that is more recent."
                ], statusCode: 409, headers: nil)
            }
            if requestCount == 2 {
                // THEN the second request contains only the delta
                try assertRequestBody(request, expected: """
                {
                  "content" : "content-b"
                }
                """)
                var serverPost = serverPost
                serverPost.content = "content-b"
                return try HTTPStubsResponse(value: serverPost, statusCode: 200)
            }

            throw URLError(.unknown)
        }

        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974")) { request in
            try HTTPStubsResponse(value: serverPost, statusCode: 200)
        }

        try await repository._save(post, overwrite: false)

        // THEN the content got updated to the version from the local revision
        XCTAssertEqual(post.content, "content-b")
        // THEN the rest of the changes are consolidated on the server and the
        // new changes made elsewhere are not overwritten thanks to the detla update
        XCTAssertEqual(post.postTitle, "title-c")
        // THEN the local revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertNil(revision.managedObjectContext)
    }
}

// MARK: - Helpers

private func stub(condition: @escaping (URLRequest) -> Bool, _ response: @escaping (URLRequest) throws -> HTTPStubsResponse) {
    OHHTTPStubs.stub(condition: condition) { request in
        do {
            return try response(request)
        } catch {
            XCTFail("Unexpected error: \(error)")
            return HTTPStubsResponse(error: error)
        }
    }
}

private func assertRequestBody(_ request: URLRequest, expected: String) throws {
    let parameters = try request.getBodyParameters()
    let data = try JSONSerialization.data(withJSONObject: parameters, options: [.sortedKeys, .prettyPrinted])
    let string = String(data: data, encoding: .utf8)
    guard string == expected else {
        XCTFail("Unexpected parameters: \(String(describing: string))")
        throw PostRepositorySaveTestsError.unexpectedRequestBody(parameters, expected)
    }
}

private extension URLRequest {
    func getBodyParameters() throws -> [String: Any] {
        guard let data = httpBodyStream?.read() else {
            throw PostRepositorySaveTestsError.requestBodyEmpty
        }
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let parameters = object as? [String: Any] else {
            throw PostRepositorySaveTestsError.invalidRequestBody(data)
        }
        return parameters
    }

    func getIfNotModifiedSince() throws -> Date {
        let parameters = try getBodyParameters()
        guard let value = parameters["if_not_modified_since"] as? String,
              let date = NSDate.rfc3339DateFormatter().date(from: value) else {
            throw PostRepositorySaveTestsError.invalidRequest
        }
        return date
    }
}

private enum PostRepositorySaveTestsError: Error {
    case requestBodyEmpty
    case invalidRequest
    case invalidRequestBody(_ data: Data)
    case unexpectedRequestBody(_ lhs: Any, _ rhs: Any)
}

private extension HTTPStubsResponse {
    convenience init<T: Encodable>(value: T, statusCode: Int) throws {
        let data = try encoder.encode(value)
        self.init(data: data, statusCode: Int32(statusCode), headers: nil)
    }
}

// MARK: - Server

private struct WordPressComPost: Hashable, Codable {
    var id: Int
    var siteID: Int
    var date: Date
    var modified: Date
    var author: WordPressComAuthor?
    var title: String?
    var url: String?
    var content: String?
    var excerpt: String?
    var slug: String?
    var status: String?
    var sticky: Bool?
    var password: String?
    var parent: Bool?
    var type: String?
    var featuredImage: String?
    var format: String?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case siteID = "site_ID" // snake case with uppercase letter!!!
        case date
        case modified
        case author
        case title
        case url = "URL"
        case content
        case excerpt
        case slug
        case status
        case sticky
        case password
        case parent
        case type
        case featuredImage = "featured_image"
        case format
    }

    static var mock: WordPressComPost = {
        let data = try! Bundle.test.json(named: "remote-post")
        return try! decoder.decode(WordPressComPost.self, from: data)
    }()
}

private struct WordPressComAuthor: Hashable, Codable {
    var id: Int
    var login: String?
    var email: Bool?
    var name: String?
    var firstName: String?
    var lastName: String?
    var siteID: Int

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case login
        case email
        case name
        case firstName = "first_name"
        case lastName = "last_name"
        case siteID = "site_ID"
    }
}

private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(NSDate.rfc3339DateFormatter())
    return decoder
}()

private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .formatted(NSDate.rfc3339DateFormatter())
    return encoder
}()
