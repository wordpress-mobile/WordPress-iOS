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

    func testPublishSimpleSyncedDraft() async throws {
        // GIVEN simple synced draft post
        let post = PostBuilder(mainContext, blog: blog).build {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = Date()
            $0.postTitle = "Hello"
            $0.content = "<!-- wp:paragraph -->\n<p>World</p>\n<!-- /wp:paragraph -->"
        }
        try mainContext.save()

        // GIVEN server configured to accept the patch request
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            try validateRequestBody(request, expected: ["status": "publish"])
            let responseData = try Bundle.test.json(named: "remote-post")
            return HTTPStubsResponse(data: responseData, statusCode: 200, headers: nil)
        }

        // WHEN publishing a post without creating a revision
        let parameters = RemotePostUpdateParameters()
        parameters.status = PostStatusPublish
        try await repository._save(post: post, with: parameters)

        // THEN post got published
        XCTAssertEqual(post.status, .publish)
    }
}

// TODO: add more control over RemotePost in body"
// TODO: Undo with(snippet:) change

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

private func validateRequestBody(_ request: URLRequest, expected: [String: AnyHashable]) throws {
    guard let data = request.httpBodyStream?.read() else {
        throw PostRepositorySaveTestsError.requestBodyEmpty
    }
    guard let object = try? JSONSerialization.jsonObject(with: data) else {
        throw PostRepositorySaveTestsError.invalidRequestBody(data)
    }
    func makeJSON(from object: Any) -> Data? {
        try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
    guard makeJSON(from: object) == makeJSON(from: expected) else {
        throw PostRepositorySaveTestsError.unexpectedRequestBody(object, expected)
    }
}

private enum PostRepositorySaveTestsError: Error {
    case requestBodyEmpty
    case invalidRequestBody(_ data: Data)
    case unexpectedRequestBody(_ lhs: Any, _ rhs: Any)
}
