import Foundation
import Testing
import HTTPFixtures

@Suite
struct FixtureSetTests {
    // MARK: - URL

    @Test func urlPathIgnoresTheQuery() throws {
        let fixtures = try makeFixtureSet([
            "me.json": mapping(#"{"method": "GET", "urlPath": "/rest/v1.1/me"}"#)
        ])

        #expect(fixtures.response(for: get("/rest/v1.1/me?locale=en")).status == 200)
        #expect(fixtures.response(for: get("/rest/v1.1/me/sites")).status == 404)
    }

    @Test func urlMatchesThePathAndQueryExactly() throws {
        let fixtures = try makeFixtureSet([
            "xmlrpc.json": mapping(#"{"method": "POST", "url": "/xmlrpc.php"}"#)
        ])

        #expect(fixtures.response(for: post("/xmlrpc.php")).status == 200)
        #expect(fixtures.response(for: post("/xmlrpc.php?rsd")).status == 404)
    }

    @Test func urlPatternHasToMatchTheWholePathAndQuery() throws {
        let fixtures = try makeFixtureSet([
            "me.json": mapping(#"{"method": "GET", "urlPattern": "/rest/v1.1/me(/)?($|\\?.*)"}"#)
        ])

        #expect(fixtures.response(for: get("/rest/v1.1/me")).status == 200)
        #expect(fixtures.response(for: get("/rest/v1.1/me/?locale=en")).status == 200)
        #expect(fixtures.response(for: get("/rest/v1.1/me/sites")).status == 404)
    }

    @Test func urlPatternTriesEveryAlternative() throws {
        // An unanchored search would settle for "posts" and miss that "posts/new" matches in full.
        let fixtures = try makeFixtureSet([
            "posts.json": mapping(#"{"urlPattern": "/sites/1/(posts|posts/new)"}"#)
        ])

        #expect(fixtures.response(for: get("/sites/1/posts/new")).status == 200)
    }

    @Test func urlPathPatternIgnoresTheQuery() throws {
        let fixtures = try makeFixtureSet([
            "stats.json": mapping(#"{"urlPathPattern": "/rest/v1.1/sites/\\d+/stats"}"#)
        ])

        #expect(fixtures.response(for: get("/rest/v1.1/sites/106707880/stats?period=day")).status == 200)
        #expect(fixtures.response(for: get("/rest/v1.1/sites/abc/stats")).status == 404)
    }

    @Test func matchesAnyHost() throws {
        let fixtures = try makeFixtureSet([
            "avatar.json": mapping(#"{"urlPath": "/avatar/abc"}"#)
        ])

        let request = StubRequest(url: URL(string: "https://gravatar.com/avatar/abc?s=96")!)
        #expect(fixtures.response(for: request).status == 200)
    }

    @Test func methodHasToMatch() throws {
        let fixtures = try makeFixtureSet([
            "new.json": mapping(#"{"method": "POST", "urlPath": "/posts/new"}"#),
            "any.json": mapping(#"{"method": "ANY", "urlPath": "/anything"}"#)
        ])

        #expect(fixtures.response(for: post("/posts/new")).status == 200)
        #expect(fixtures.response(for: get("/posts/new")).status == 404)
        #expect(fixtures.response(for: request("DELETE", "/anything")).status == 200)
    }

    // MARK: - Query

    @Test func queryParametersAreComparedDecoded() throws {
        let fixtures = try makeFixtureSet([
            "drafts.json": mapping(
                #"""
                {
                    "urlPath": "/posts",
                    "queryParameters": {"status": {"equalTo": "draft,pending"}, "number": {"matches": "\\d+"}}
                }
                """#
            )
        ])

        #expect(fixtures.response(for: get("/posts?status=draft%2Cpending&number=20&extra=1")).status == 200)
        #expect(fixtures.response(for: get("/posts?status=publish&number=20")).status == 404)
        #expect(fixtures.response(for: get("/posts?status=draft%2Cpending&number=all")).status == 404)
        #expect(fixtures.response(for: get("/posts?status=draft%2Cpending")).status == 404)
    }

    @Test func absentQueryParameterMustNotBeSent() throws {
        let fixtures = try makeFixtureSet([
            "available.json": mapping(#"{"urlPath": "/is-available", "queryParameters": {"format": {"absent": true}}}"#)
        ])

        #expect(fixtures.response(for: get("/is-available?q=a")).status == 200)
        #expect(fixtures.response(for: get("/is-available?q=a&format=json")).status == 404)
    }

    // MARK: - Body

    @Test func bodyPatternsAllHaveToMatch() throws {
        let fixtures = try makeFixtureSet([
            "options.json": mapping(
                #"""
                {
                    "method": "POST",
                    "url": "/xmlrpc.php",
                    "bodyPatterns": [
                        {"matches": ".*<methodName>wp.getOptions</methodName>.*"},
                        {"matches": ".*<string>e2eflowtestingmobile</string>.*"}
                    ]
                }
                """#
            )
        ])

        let method = "<methodName>wp.getOptions</methodName>"
        let user = "<string>e2eflowtestingmobile</string>"
        #expect(fixtures.response(for: post("/xmlrpc.php", body: "<call>\(method)\(user)</call>")).status == 200)
        #expect(fixtures.response(for: post("/xmlrpc.php", body: "<call>\(method)</call>")).status == 404)
        #expect(fixtures.response(for: post("/xmlrpc.php")).status == 404)
    }

    @Test func equalToJSONIgnoresKeyOrder() throws {
        let fixtures = try makeFixtureSet([
            "reply.json": mapping(
                #"{"method": "POST", "bodyPatterns": [{"equalToJson": {"content": "Hello", "context": "edit"}}]}"#
            )
        ])

        #expect(fixtures.response(for: post("/reply", body: #"{"context": "edit", "content": "Hello"}"#)).status == 200)
        #expect(fixtures.response(for: post("/reply", body: #"{"context": "edit", "content": "Bye"}"#)).status == 404)
    }

    @Test func matchesJSONPath() throws {
        let fixtures = try makeFixtureSet([
            "post.json": mapping(
                #"{"method": "POST", "urlPath": "/new", "bodyPatterns": [{"matchesJsonPath": "$[?(@.type == 'post')]"}]}"#,
                response: #"{"status": 201}"#
            ),
            "site.json": mapping(
                #"{"method": "POST", "urlPath": "/new", "bodyPatterns": [{"matchesJsonPath": "$.options.template"}]}"#,
                response: #"{"status": 202}"#
            )
        ])

        #expect(fixtures.response(for: post("/new", body: #"{"type": "post"}"#)).status == 201)
        #expect(fixtures.response(for: post("/new", body: #"{"options": {"template": "default"}}"#)).status == 202)
        #expect(fixtures.response(for: post("/new", body: #"{"type": "page"}"#)).status == 404)
    }

    // MARK: - Choosing between mappings

    private static let allPosts = #"{"urlPath": "/posts"}"#
    private static let draftPosts = #"{"urlPath": "/posts", "queryParameters": {"status": {"equalTo": "draft"}}}"#

    @Test func theMoreSpecificMappingWinsAtEqualPriority() throws {
        let fixtures = try makeFixtureSet([
            "a-all.json": mapping(Self.allPosts, response: #"{"status": 200, "body": "all"}"#),
            "b-drafts.json": mapping(Self.draftPosts, response: #"{"status": 200, "body": "drafts"}"#)
        ])

        #expect(fixtures.response(for: get("/posts?status=draft")).text == "drafts")
        #expect(fixtures.response(for: get("/posts?status=publish")).text == "all")
    }

    @Test func aLowerPriorityNumberWinsOverSpecificity() throws {
        let fixtures = try makeFixtureSet([
            "all.json": mapping(
                Self.allPosts,
                response: #"{"status": 200, "body": "all"}"#,
                attributes: #""priority": 1"#
            ),
            "drafts.json": mapping(Self.draftPosts, response: #"{"status": 200, "body": "drafts"}"#)
        ])

        #expect(fixtures.response(for: get("/posts?status=draft")).text == "all")
    }

    @Test func scenariosChangeWhatLaterRequestsGet() throws {
        let fixtures = try makeFixtureSet([
            "before.json": mapping(
                #"{"method": "GET", "urlPath": "/posts"}"#,
                response: #"{"status": 200, "body": "no posts"}"#,
                attributes: #""scenarioName": "new_post", "requiredScenarioState": "Started""#
            ),
            "publish.json": mapping(
                #"{"method": "POST", "urlPath": "/posts/new"}"#,
                attributes: #""scenarioName": "new_post", "newScenarioState": "published""#
            ),
            "after.json": mapping(
                #"{"method": "GET", "urlPath": "/posts"}"#,
                response: #"{"status": 200, "body": "one post"}"#,
                attributes: #""scenarioName": "new_post", "requiredScenarioState": "published""#
            )
        ])

        #expect(fixtures.response(for: get("/posts")).text == "no posts")
        #expect(fixtures.response(for: post("/posts/new")).status == 200)
        #expect(fixtures.response(for: get("/posts")).text == "one post")
    }

    // MARK: - Responses

    @Test func reportsTheMappingThatAnswered() throws {
        let fixtures = try makeFixtureSet([
            "wpcom/me/me.json": mapping(#"{"urlPath": "/rest/v1.1/me"}"#)
        ])

        #expect(fixtures.response(for: get("/rest/v1.1/me")).source == "wpcom/me/me.json")
    }

    @Test func answersAnUnmatchedRequestWithAnError() throws {
        let fixtures = try makeFixtureSet([
            "me.json": mapping(#"{"urlPath": "/rest/v1.1/me"}"#)
        ])

        let response = fixtures.response(for: get("/rest/v1.1/sites/1/posts?number=20"))
        #expect(response.status == 404)
        #expect(response.source == nil)
        #expect(response.text.contains("No fixture matches GET /rest/v1.1/sites/1/posts?number=20"))
    }

    @Test func jsonBodyIsServedAsItIsWritten() throws {
        let fixtures = try makeFixtureSet([
            "me.json": mapping(
                #"{"urlPath": "/me"}"#,
                response: #"{"status": 200, "jsonBody": {"ID": 152748359, "URL": "https://example.com/a"}}"#
            )
        ])

        let response = fixtures.response(for: get("/me"))
        #expect(response.headers["Content-Type"] == "application/json")
        #expect(response.text == #"{"ID": 152748359, "URL": "https://example.com/a"}"#)
    }

    @Test func rendersTemplatesInTheBodyAndHeaders() throws {
        let fixtures = try makeFixtureSet([
            "me.json": mapping(
                #"{"urlPath": "/me"}"#,
                response: #"""
                    {
                        "status": 200,
                        "jsonBody": {"self": "{{request.requestLine.baseUrl}}/me", "date": "{{now format='yyyy-MM-dd'}}"},
                        "headers": {"Link": "<{{request.requestLine.baseUrl}}/wp-json/>"}
                    }
                    """#
            )
        ])

        let response = fixtures.response(for: get("/me"))
        #expect(response.text == #"{"self": "https://public-api.wordpress.com/me", "date": "2025-06-15"}"#)
        #expect(response.headers["Link"] == "<https://public-api.wordpress.com/wp-json/>")
    }

    @Test func rendersTheTemplatesOfAJSONBodyInTheOrderTheyAreWritten() throws {
        // The first key defines the variable the second one reads. Sorting the keys would break it.
        let fixtures = try makeFixtureSet([
            "post.json": mapping(
                #"{"urlPath": "/post"}"#,
                response: #"""
                    {
                        "status": 200,
                        "jsonBody": {
                            "modified": "{{#assign 'format'}}yyyy-MM-dd'T'HH:mm:ss{{/assign}}{{now format=format}}",
                            "date": "{{now offset='-1 days' format=format}}",
                            "nested": {"braces": "}", "quote": "\"]"}
                        }
                    }
                    """#
            )
        ])

        let json = try JSONSerialization.jsonObject(with: fixtures.response(for: get("/post")).body) as? [String: Any]
        #expect(json?["modified"] as? String == "2025-06-15T15:06:40")
        #expect(json?["date"] as? String == "2025-06-14T15:06:40")
        #expect(json?["nested"] as? [String: String] == ["braces": "}", "quote": "\"]"])
    }

    @Test func delayIsReadInMilliseconds() throws {
        let fixtures = try makeFixtureSet([
            "slow.json": mapping(#"{"urlPath": "/slow"}"#, response: #"{"fixedDelayMilliseconds": 1500}"#)
        ])

        #expect(fixtures.response(for: get("/slow")).delay == 1.5)
    }

    // MARK: - Loading

    @Test func rejectsAMatcherItDoesNotSupport() throws {
        let error = #expect(throws: FixtureError.self) {
            try makeFixtureSet([
                "wpcom/me.json": mapping(#"{"urlPath": "/me", "headers": {"Accept": {"contains": "json"}}}"#)
            ])
        }

        #expect(error?.file == "wpcom/me.json")
        #expect(error?.reason == "request has unsupported keys: headers")
    }

    @Test func rejectsATemplateItCannotRender() throws {
        let error = #expect(throws: FixtureError.self) {
            try makeFixtureSet([
                "me.json": mapping(
                    #"{"urlPath": "/me"}"#,
                    response: #"{"status": 200, "body": "{{randomValue type='UUID'}}"}"#
                )
            ])
        }

        #expect(error?.file == "me.json")
    }

    @Test func rejectsADirectoryWithoutMappings() throws {
        #expect(throws: FixtureError.self) {
            try FixtureSet(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        }
    }
}

/// The fixtures the Jetpack UI tests run against.
///
/// The app refuses to launch with fixtures it can't read, which fails every UI test at once. This
/// reports the same problem in the time it takes to run a unit test.
@Suite
struct JetpackUITestFixturesTests {
    private static let directory = URL(filePath: #filePath)
        .appending(path: "../../../../Tests/JetpackUITests/Fixtures")
        .standardizedFileURL

    /// Skipped where the tests run without the source tree next to them.
    @Test(.enabled(if: FileManager.default.fileExists(atPath: directory.path(percentEncoded: false))))
    func everyMappingLoads() throws {
        _ = try FixtureSet(directory: Self.directory)
    }
}
