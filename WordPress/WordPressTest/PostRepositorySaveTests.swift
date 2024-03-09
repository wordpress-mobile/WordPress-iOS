import XCTest
import OHHTTPStubs

@testable import WordPress

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
            try validateRequestBody(request, expected: """
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
            try validateRequestBody(request, expected: """
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
            try validateRequestBody(request, expected: """
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
            try validateRequestBody(request, expected: """
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

//    func testSpotUpdateDraftClientBehind() async throws {
//        // GIVEN a draft post (client behind)
//        let clientDateModified = Date().addingTimeInterval(-30)
//        let serverDateModified = Date()
//
//        let post = PostBuilder(mainContext, blog: blog).build {
//            $0.status = .draft
//            $0.postID = 974
//            $0.authorID = 29043
//            $0.dateCreated = Date().addingTimeInterval(-60)
//            $0.dateModified = clientDateModified
//            $0.postTitle = "Hello"
//            $0.content = "<!-- wp:paragraph -->\n<p>World</p>\n<!-- /wp:paragraph -->"
//        }
//        try mainContext.save()
//
//        // GIVEN a server where the post is ahead and has a new content
//        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
//            let ifNotModifiedSince = try request.getIfNotModifiedSince()
//            if  ifNotModifiedSince < serverDateModified {
//                return HTTPStubsResponse(jsonObject: [
//                    "error": "old-revision",
//                    "message": "There is a revision of this post that is more recent."
//                ], statusCode: 409, headers: nil)
//            }
//            // THEN the app sends a partial update
//            try validateRequestBody(request, expected: ["status": "publish"])
//            let responseData = try Bundle.test.json(named: "remote-post")
//            return HTTPStubsResponse(data: responseData, statusCode: 200, headers: nil)
//        }
//
//        // WHEN spot-updating a post
//        let parameters = RemotePostUpdateParameters()
//        parameters.title = "new-title"
//        try await repository._save(post, with: parameters)
//
//        // THEN the post got published
//        XCTAssertEqual(post.status, .publish)
//    }
}

// MARK: - Helpers

private func stub(condition: @escaping (URLRequest) -> Bool, _ response: @escaping (URLRequest) throws -> HTTPStubsResponse) {
    OHHTTPStubs.stub(condition: condition) { request in
        do {
            return try response(request)
        } catch {
            return HTTPStubsResponse(error: error)
        }
    }
}

private func validateRequestBody(_ request: URLRequest, expected: String) throws {
    let parameters = try request.getBodyParameters()
    let data = try JSONSerialization.data(withJSONObject: parameters, options: [.sortedKeys, .prettyPrinted])
    let string = String(data: data, encoding: .utf8)
    guard string == expected else {
        XCTFail("Unexpected parameters: \(string)")
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
