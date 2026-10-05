import Foundation
import Testing
@testable import HTTPFixtures

@Suite
struct ResponseTemplateTests {
    /// Sunday 15 June 2025, 15:06:40 UTC.
    private let now = Date(timeIntervalSince1970: 1_750_000_000)

    private func render(_ template: String, for request: StubRequest = get("/")) throws -> String {
        var renderer = ResponseTemplate(request: request, now: now)
        return try renderer.render(template)
    }

    @Test func leavesTextWithoutExpressionsAlone() throws {
        #expect(try render(#"{"name": "Tri-County Real Estate"}"#) == #"{"name": "Tri-County Real Estate"}"#)
    }

    @Test func baseURLIsTheHostTheRequestWentTo() throws {
        let request = StubRequest(url: URL(string: "http://localhost:8282/rest/v1.1/me")!)

        #expect(try render("{{request.requestLine.baseUrl}}/me") == "https://public-api.wordpress.com/me")
        #expect(try render("{{request.requestLine.baseUrl}}/me", for: request) == "http://localhost:8282/me")
    }

    @Test func readsTheQueryAndThePath() throws {
        let request = get("/rest/v1.2/read/tags/dogs/mine/new?url=https%3A%2F%2Fexample.com&tags%5B%5D=cats")

        #expect(try render("{{request.query.url}}", for: request) == "https://example.com")
        #expect(try render("{{request.pathSegments.[4]}}", for: request) == "dogs")
        #expect(try render("{{lookup request.query 'tags[]'}}", for: request) == "cats")
        #expect(try render("{{capitalize (lookup request.query 'tags[]')}}", for: request) == "Cats")
        #expect(try render("{{capitalize request.pathSegments.[4]}}", for: request) == "Dogs")
    }

    @Test func aRequestValueThatIsMissingRendersAsNothing() throws {
        #expect(try render("[{{request.query.url}}][{{request.pathSegments.[9]}}]") == "[][]")
    }

    @Test func nowDefaultsToISO8601() throws {
        #expect(try render("{{now}}") == "2025-06-15T15:06:40Z")
    }

    @Test(arguments: [
        ("{{now format='yyyy-MM-dd'}}", "2025-06-15"),
        ("{{now offset='-1 days' format='yyyy-MM-dd'}}", "2025-06-14"),
        ("{{now offset='3 months' format='yyyy-MM-dd'}}", "2025-09-15"),
        ("{{now offset='-1 years' format='yyyy-MM-dd'}}", "2024-06-15"),
        ("{{now offset='-16 hours'}}", "2025-06-14T23:06:40Z"),
        ("{{now offset='2 days' format='HH:mm:ssZ'}}", "15:06:40+0000"),
        ("{{now format='epoch'}}", "1750000000000"),
        ("{{now format='unix'}}", "1750000000")
    ])
    func nowTakesAnOffsetAndAFormat(template: String, expected: String) throws {
        #expect(try render(template) == expected)
    }

    @Test func assignDefinesAVariableAndRendersNothing() throws {
        let template = "{{#assign 'format'}}yyyy-MM-dd'T'HH:mm:ss{{/assign}}{{now offset='-2 hours' format=format}}"

        #expect(try render(template) == "2025-06-15T13:06:40")
    }

    @Test func jsonPathReadsTheRequestBody() throws {
        let request = post("/posts/new", body: #"{"title": "Hello", "terms": {"count": 2}}"#)

        #expect(try render("{{jsonPath request.body '$.title'}}", for: request) == "Hello")
        #expect(try render("{{jsonPath request.body '$.terms.count'}}", for: request) == "2")
        #expect(try render("{{jsonPath request.body '$.missing'}}", for: request).isEmpty)
    }

    @Test(arguments: [
        "{{randomValue type='UUID'}}",
        "{{request.headers.Accept}}",
        "{{now timezone='Australia/Sydney'}}",
        "{{now offset='1 day'}}",
        "{{now",
        "{{#assign 'name'}}value"
    ])
    func rejectsWhatItCannotRender(template: String) {
        #expect(throws: ResponseTemplate.Failure.self) {
            try render(template)
        }
    }
}
