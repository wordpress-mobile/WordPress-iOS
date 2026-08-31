import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import Testing
import WordPressAPI

@testable import WordPress
@testable import WordPressCore

@Suite(.serialized)
struct CommentServiceRemoteCoreRESTAPITests {

    /// `createComment`'s response comes back in view context, so it is the public
    /// entry point that exercises `RemoteComment.init(comment: CommentWithViewContext)`.
    @Test func createCommentMapsViewContextResponse() async throws {
        let api = try WordPressAPI(
            urlSession: URLSession(configuration: .ephemeral),
            siteInfo: .selfHosted(
                siteUrl: .parse(input: "https://example.com"),
                apiRoot: .parse(input: "https://example.com/wp-json")
            ),
            authentication: .none
        )

        // WordPressClient's init eagerly starts api-root/user/theme/settings
        // tasks. Absorb them with a host-wide stub so they don't hit the network.
        let catchAll = stub(condition: isHost("example.com")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let createStub = stub(condition: { $0.url?.absoluteString.contains("/wp/v2/comments") == true }) { _ in
            HTTPStubsResponse(
                data: Self.viewContextCommentJSON.data(using: .utf8)!,
                statusCode: 201,
                headers: ["Content-Type": "application/json"]
            )
        }
        defer {
            HTTPStubs.removeStub(createStub)
            HTTPStubs.removeStub(catchAll)
        }

        let client = WordPressClient(api: api, siteURL: URL(string: "https://example.com")!)
        let service = CommentServiceRemoteCoreRESTAPI(client: client)

        let input = RemoteComment()
        input.postID = 49

        let created: RemoteComment? = try await withCheckedThrowingContinuation { continuation in
            service.createComment(
                input,
                success: { continuation.resume(returning: $0) },
                failure: { continuation.resume(throwing: $0 ?? URLError(.unknown)) }
            )
        }
        let comment = try #require(created)

        #expect(comment.commentID?.intValue == 2)
        #expect(comment.authorID?.intValue == 135)
        #expect(comment.author == "John Doe")
        #expect(comment.authorUrl == "https://example.com/john-doe")
        #expect(comment.authorAvatarURL == "https://example.com/avatar/sample?s=96")
        #expect(comment.content == "<p>Some example comment.</p>")
        #expect(comment.date == Date(timeIntervalSince1970: 1625136611))
        #expect(comment.link == "https://example.com/example-post/#comment-2")
        #expect(comment.parentID?.intValue == 1)
        #expect(comment.postID?.intValue == 49)
        #expect(comment.status == "approve")
        #expect(comment.type == "comment")
        #expect(!comment.canModerate)

        // View context never carries the author's email or IP, nor raw content.
        #expect(comment.authorEmail == nil)
        #expect(comment.authorIP == nil)
        #expect(comment.rawContent == nil)
    }

    private static let viewContextCommentJSON = """
        {
          "id": 2,
          "post": 49,
          "parent": 1,
          "author": 135,
          "author_name": "John Doe",
          "author_url": "https://example.com/john-doe",
          "date": "2021-07-01T17:50:11",
          "date_gmt": "2021-07-01T10:50:11",
          "content": { "rendered": "<p>Some example comment.</p>" },
          "link": "https://example.com/example-post/#comment-2",
          "status": "approved",
          "type": "comment",
          "author_avatar_urls": {
            "24": "https://example.com/avatar/sample?s=24",
            "48": "https://example.com/avatar/sample?s=48",
            "96": "https://example.com/avatar/sample?s=96"
          }
        }
        """
}
