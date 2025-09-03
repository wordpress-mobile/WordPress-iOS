import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPressKit

class WordPressOrgRestApiTests: XCTestCase {

    let apiBase = URL(string: "https://wordpress.org/wp-json/")!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    private func isAPIRequest() -> HTTPStubsTestBlock {
        return { request in
            return request.url?.absoluteString.hasPrefix(self.apiBase.absoluteString) ?? false
        }
    }

    func testUnauthorizedCall() async throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("wp-forbidden.json", Bundle.coreAPITestsBundle))
        stub(condition: isAPIRequest()) { _ in
            return fixture(filePath: stubPath, status: 401, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        let api = WordPressOrgRestApi(apiBase: apiBase)
        let result = await api.get(path: "wp/v2/settings", type: AnyResponse.self)
        switch result {
        case .success:
            XCTFail("This call should not suceed")
        case let .failure(error):
            XCTAssertEqual(error.response?.statusCode, 401, "Response should be unauthorized")
        }
    }

    func testSuccessfulGetCall() async throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("wp-pages.json", Bundle.coreAPITestsBundle))
        stub(condition: isAPIRequest()) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
        let api = WordPressOrgRestApi(apiBase: apiBase)
        let pages = try await api.get(path: "wp/v2/pages", type: [AnyResponse].self).get()
        XCTAssertEqual(pages.count, 10, "The API should return 10 pages")
    }

    func testSuccessfulPostCall() async throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("wp-reusable-blocks.json", Bundle.coreAPITestsBundle))
        stub(condition: isAPIRequest()) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        struct Response: Decodable {
            struct Content: Decodable {
                var raw: String
            }

            var content: Content
        }

        let api = WordPressOrgRestApi(apiBase: apiBase)
        let blockContent = "<!-- wp:paragraph -->\n<p>Some text</p>\n<!-- /wp:paragraph -->\n\n<!-- wp:list -->\n<ul><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul>\n<!-- /wp:list -->"
        let parameters: [String: String] = ["id": "6", "content": blockContent]
        let response = try await api.post(path: "wp/v2/blocks/6", parameters: parameters, type: Response.self).get()
        XCTAssertEqual(response.content.raw, blockContent, "The API should return the block")
    }

    /// Verify that parameters in POST requests are sent as urlencoded form.
    func testPostParametersContent() async throws {
        var req: URLRequest?
        stub(condition: isHost("wordpress.org")) {
            req = $0
            return HTTPStubsResponse(error: URLError(.notConnectedToInternet))
        }

        struct Empty: Decodable {}

        let api = WordPressOrgRestApi(apiBase: apiBase)
        let _ = await api.post(path: "/rest/v1/foo", parameters: ["arg1": "value1"], type: Empty.self)

        let request = try XCTUnwrap(req)
        XCTAssertEqual(request.httpMethod?.uppercased(), "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://wordpress.org/wp-json/rest/v1/foo")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertEqual(request.httpBodyText, "arg1=value1")
    }

    func testRequestPathModificationsWPV2() async throws {
        stub(condition: isPath("/wp/v2/sites/1001/themes") && containsQueryParams(["status": "active"])) { _ in
            HTTPStubsResponse(jsonObject: [String: String](), statusCode: 200, headers: nil)
        }
        let api = WordPressOrgRestApi(site: .dotCom(siteID: 1001, bearerToken: "fakeToken"))
        let _ = try await api.get(path: "/wp/v2/themes", parameters: ["status": "active"], type: AnyResponse.self).get()
    }

    func testRequestPathModificationsWPBlockEditor() async throws {
        stub(condition: isPath("/wp-block-editor/v1/sites/1001/settings")) { _ in
            HTTPStubsResponse(jsonObject: [String: String](), statusCode: 200, headers: nil)
        }
        let api = WordPressOrgRestApi(site: .dotCom(siteID: 1001, bearerToken: "fakeToken"))
        let _ = try await api.get(path: "/wp-block-editor/v1/settings", type: AnyResponse.self).get()
    }

    func testSettingWPComAPIURL() async {
        var request: URLRequest?
        stub(condition: { _ in true }, response: {
            request = $0
            return HTTPStubsResponse(error: URLError(.networkConnectionLost))
        })

        let api = WordPressOrgRestApi(dotComSiteID: 1001, bearerToken: "token", apiURL: URL(string: "http://localhost:8000")!)
        let _ = await api.get(path: "/wp/v2/hello", type: AnyResponse.self)
        XCTAssertEqual(request?.url?.absoluteString, "http://localhost:8000/wp/v2/sites/1001/hello")
    }

    // Gutenberg Editor in the WordPress app may call `WordPressOrgRestApi` with a 'path' parameter that contain path
    // and query. This unit test ensures WordPressKit doesn't break that feature.
    func testPathWithQuery() async {
        var request: URLRequest?
        stub(condition: { _ in true }, response: {
            request = $0
            return HTTPStubsResponse(error: URLError(.networkConnectionLost))
        })

        let api = WordPressOrgRestApi(site: .dotCom(siteID: 1001, bearerToken: "fakeToken"))

        let _ = await api.get(path: "/wp/v2/get-decodable?context=mobile", type: AnyResponse.self)
        XCTAssertEqual(request?.url?.absoluteString, "https://public-api.wordpress.com/wp/v2/sites/1001/get-decodable?context=mobile")

        let _ = await api.post(path: "/wp/v2/post-decodable?context=mobile", type: AnyResponse.self)
        XCTAssertEqual(request?.url?.absoluteString, "https://public-api.wordpress.com/wp/v2/sites/1001/post-decodable?context=mobile")

        let _ = await api.get(path: "/wp/v2/get-any-json?context=mobile")
        XCTAssertEqual(request?.url?.absoluteString, "https://public-api.wordpress.com/wp/v2/sites/1001/get-any-json?context=mobile")

        let _ = await api.post(path: "/wp/v2/post-any-json?context=mobile")
        XCTAssertEqual(request?.url?.absoluteString, "https://public-api.wordpress.com/wp/v2/sites/1001/post-any-json?context=mobile")
    }
}

extension WordPressOrgRestApi {
    convenience init(apiBase: URL) {
        self.init(
            selfHostedSiteWPJSONURL: apiBase,
            credential: .init(loginURL: URL(string: "https://not-used.com")!, username: "user", password: "pass", adminURL: URL(string: "https://not-used.com")!)
        )
    }
}

extension WordPressOrgRestApi.Site {
    static func dotCom(siteID: UInt64, bearerToken: String) -> Self {
        .dotCom(siteID: siteID, bearerToken: bearerToken, apiURL: WordPressComRestApi.apiBaseURL)
    }
}

private struct AnyResponse: Decodable {}
