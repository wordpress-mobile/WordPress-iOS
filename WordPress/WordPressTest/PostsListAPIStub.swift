import Foundation
import XCTest
import OHHTTPStubs

@testable import WordPress

extension XCTestCase {
    /// This is a helper function to create HTTP stubs for fetching posts(GET /sites/%s/posts) requests.
    ///
    /// The returned fake posts have only basic properties. The stubs ensure post id is unique and starts from 1.
    /// But it does not promise the returned posts match the request filters (like status).
    ///
    /// You can use the `update` closure to update the returned posts if needed.
    ///
    /// Here are the supported features:
    /// - Pagination. The stubs simulates `total` number of posts in the site, to handle paginated request accordingly.
    /// - Search, but limited. Search is based on title. All fake posts have a title like "Random Post - [post-id]", where post id starts from 1. So, search "1" returns the posts whose id has "1" in it (1, 1x, x1, and so on).
    ///
    /// Here are unsupported features:
    /// - Order. The sorting related arguments are ignored.
    /// - Filter by status. The status argument is ignored.
    func stubGetPostsList(type: String, total: Int, update: ((inout [String: Any]) -> Void)? = nil) {
        let allPosts = (1...total).map { id -> [String: Any] in
            [
                "ID": id,
                "title": "Random Post - \(id)",
                "content": "This is a test.",
                "status": BasePost.Status.publish.rawValue,
                "type": type
            ]
        }

        let handle = stub(condition: isMethodGET() && pathMatches(#"/sites/\d+/posts"#, options: [])) { request in
            let queryItems = URLComponents(url: request.url!, resolvingAgainstBaseURL: true)?.queryItems ?? []

            var result = allPosts

            if let search = queryItems.first(where: { $0.name == "search" })?.value {
                result = result.filter {
                    let title = $0["title"] as? String
                    return title?.contains(search) == true
                }
            }

            var number = (queryItems.first { $0.name == "number" }?.value.flatMap { Int($0) }) ?? 0
            number = number == 0 ? 20 : number // The REST API uses the default value 20 when number is 0.
            let offset = (queryItems.first { $0.name == "offset" }?.value.flatMap { Int($0) }) ?? 0
            let upperBound = number == 0 ? result.endIndex : max(offset, offset + number - 1)
            let allowed = 0..<result.count
            let range = (offset..<(upperBound + 1)).clamped(to: allowed)

            let response: [String: Any] = [
                "found": result.count,
                "posts": result[range].map { post in
                    var json = post
                    update?(&json)
                    return json
                }
            ]

            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil)
        }

        addTeardownBlock {
            HTTPStubs.removeStub(handle)
        }
    }

    func stubGetPostsListWithServerError() {
        let handle = stub(condition: isMethodGET() && pathMatches(#"/sites/\d+/posts"#, options: [])) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }
        addTeardownBlock {
            HTTPStubs.removeStub(handle)
        }
    }
}

// MARK: - Tests that ensure the `preparePostsList` works as expected

class PostsListAPIStubTests:  CoreDataTestCase {

    var repository: PostRepository!
    var blogID: TaggedManagedObjectID<Blog>!

    override func setUp() async throws {
        repository = PostRepository(coreDataStack: contextManager)

        let loggedIn = try await signIn()
        blogID = try await contextManager.performAndSave {
            let blog = try BlogBuilder($0)
                .with(dotComID: 42)
                .withAccount(id: loggedIn)
                .build()
            return TaggedManagedObjectID(blog)
        }
    }

    func testPostsListStubReturnPostsAsRequested() async throws {
        stubGetPostsList(type: "post", total: 20)

        var result = try await repository.search(type: Post.self, input: nil, statuses: [], tag: nil, offset: 0, limit: 10, orderBy: .byDate, descending: true, in: blogID)
        XCTAssertEqual(result.count, 10)

        result = try await repository.search(type: Post.self, input: nil, statuses: [], tag: nil, offset: 0, limit: 20, orderBy: .byDate, descending: true, in: blogID)
        XCTAssertEqual(result.count, 20)

        result = try await repository.search(type: Post.self, input: nil, statuses: [], tag: nil, offset: 0, limit: 30, orderBy: .byDate, descending: true, in: blogID)
        XCTAssertEqual(result.count, 20)
    }

    func testPostsListStubReturnPostsAtCorrectPosition() async throws {
        stubGetPostsList(type: "post", total: 20)

        let all = try await repository.search(type: Post.self, input: nil, statuses: [], tag: nil, offset: 0, limit: 30, orderBy: .byDate, descending: true, in: blogID)

        var result = try await repository.paginate(type: Post.self, statuses: [], offset: 0, number: 5, in: blogID)
        XCTAssertEqual(result, Array(all[0..<5]))

        result = try await repository.paginate(type: Post.self, statuses: [], offset: 3, number: 2, in: blogID)
        XCTAssertEqual(result, [all[3], all[4]])
    }

    func testPostsListStubReturnPostsSearch() async throws {
        stubGetPostsList(type: "post", total: 10)

        let all = try await repository.search(type: Post.self, input: nil, statuses: [], tag: nil, offset: 0, limit: 30, orderBy: .byDate, descending: true, in: blogID)

        var result = try await repository.search(type: Post.self, input: "1", statuses: [], tag: nil, offset: 0, limit: 1, orderBy: .byDate, descending: true, in: blogID)
        XCTAssertEqual(result, [all[0]])

        result = try await repository.search(type: Post.self, input: "2", statuses: [], tag: nil, offset: 0, limit: 1, orderBy: .byDate, descending: true, in: blogID)
        XCTAssertEqual(result, [all[1]])
    }

    func testPostsListStubReturnDefaultNumberOfPosts() async throws {
        stubGetPostsList(type: "post", total: 100)

        let result = try await repository.search(type: Post.self, input: nil, statuses: [], tag: nil, offset: 0, limit: 0, orderBy: .byDate, descending: true, in: blogID)
        XCTAssertEqual(result.count, 20)
    }

}
