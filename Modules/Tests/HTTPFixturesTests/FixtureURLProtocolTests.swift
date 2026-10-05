#if DEBUG
import Foundation
import Testing
@testable import HTTPFixtures

/// These share the protocol's process-wide fixtures, so they run one at a time.
@Suite(.serialized)
struct FixtureURLProtocolTests {
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureURLProtocol.self]
        return URLSession(configuration: configuration)
    }()

    private static let mappings = [
        "wpcom/me.json": mapping(
            #"{"method": "GET", "urlPath": "/rest/v1.1/me"}"#,
            response: #"{"status": 200, "jsonBody": {"username": "e2eflowtestingmobile"}}"#
        ),
        "wpcom/new-post.json": mapping(
            #"{"method": "POST", "urlPath": "/posts/new", "bodyPatterns": [{"matchesJsonPath": "$[?(@.type == 'post')]"}]}"#,
            response: #"{"status": 201, "body": "{{jsonPath request.body '$.title'}}"}"#
        ),
        "wpcom/slow.json": mapping(
            #"{"urlPath": "/slow"}"#,
            response: #"{"status": 200, "body": "eventually", "fixedDelayMilliseconds": 50}"#
        )
    ]

    @Test func answersARequestFromTheFixtures() async throws {
        FixtureURLProtocol.activate(fixtures: try makeFixtureSet(Self.mappings))
        defer { FixtureURLProtocol.deactivate() }

        let url = URL(string: "https://public-api.wordpress.com/rest/v1.1/me?locale=en")!
        let (data, response) = try await session.data(from: url)

        #expect((response as? HTTPURLResponse)?.statusCode == 200)
        #expect((response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(String(decoding: data, as: UTF8.self) == #"{"username": "e2eflowtestingmobile"}"#)
    }

    @Test func answersARequestNothingMatchesWithA404() async throws {
        FixtureURLProtocol.activate(fixtures: try makeFixtureSet(Self.mappings))
        defer { FixtureURLProtocol.deactivate() }

        let (_, response) = try await session.data(from: URL(string: "https://example.com/unknown")!)

        #expect((response as? HTTPURLResponse)?.statusCode == 404)
    }

    @Test func readsTheBodyOfARequest() async throws {
        FixtureURLProtocol.activate(fixtures: try makeFixtureSet(Self.mappings))
        defer { FixtureURLProtocol.deactivate() }

        var request = URLRequest(url: URL(string: "https://public-api.wordpress.com/posts/new")!)
        request.httpMethod = "POST"
        request.httpBody = Data(#"{"type": "post", "title": "From httpBody"}"#.utf8)
        let (data, response) = try await session.data(for: request)

        #expect((response as? HTTPURLResponse)?.statusCode == 201)
        #expect(String(decoding: data, as: UTF8.self) == "From httpBody")
    }

    @Test func readsTheBodyOfAnUpload() async throws {
        FixtureURLProtocol.activate(fixtures: try makeFixtureSet(Self.mappings))
        defer { FixtureURLProtocol.deactivate() }

        var request = URLRequest(url: URL(string: "https://public-api.wordpress.com/posts/new")!)
        request.httpMethod = "POST"
        let body = Data(#"{"type": "post", "title": "From an upload"}"#.utf8)
        let (data, response) = try await session.upload(for: request, from: body)

        #expect((response as? HTTPURLResponse)?.statusCode == 201)
        #expect(String(decoding: data, as: UTF8.self) == "From an upload")
    }

    @Test func deliversADelayedResponse() async throws {
        FixtureURLProtocol.activate(fixtures: try makeFixtureSet(Self.mappings))
        defer { FixtureURLProtocol.deactivate() }

        let (data, _) = try await session.data(from: URL(string: "https://public-api.wordpress.com/slow")!)

        #expect(String(decoding: data, as: UTF8.self) == "eventually")
    }

    @Test func logsEveryRequestWithItsBodyAndTheMappingThatAnsweredIt() async throws {
        let log = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).log")
        FixtureURLProtocol.activate(fixtures: try makeFixtureSet(Self.mappings), requestLog: log)
        defer { FixtureURLProtocol.deactivate() }

        let newPost = URL(string: "https://public-api.wordpress.com/posts/new")!
        let avatar = URL(string: "https://gravatar.com/avatar/abc?s=96")!
        var request = URLRequest(url: newPost)
        request.httpMethod = "POST"
        request.httpBody = Data(#"{"type": "post", "title": "Two\nlines"}"#.utf8)
        _ = try await session.data(for: request)
        _ = try await session.data(from: avatar)

        let requests = try String(contentsOf: log, encoding: .utf8)
            .split(separator: "\n")
            .map { try JSONDecoder().decode(RecordedRequest.self, from: Data($0.utf8)) }
        #expect(
            requests == [
                RecordedRequest(
                    method: "POST",
                    url: newPost,
                    body: #"{"type": "post", "title": "Two\nlines"}"#,
                    status: 201,
                    fixture: "wpcom/new-post.json"
                ),
                RecordedRequest(method: "GET", url: avatar, body: nil, status: 404, fixture: nil)
            ]
        )
    }

    @Test func leavesRequestsAloneWhenThereAreNoFixtures() {
        let request = URLRequest(url: URL(string: "https://public-api.wordpress.com/rest/v1.1/me")!)

        #expect(!FixtureURLProtocol.canInit(with: request))
    }
}
#endif
