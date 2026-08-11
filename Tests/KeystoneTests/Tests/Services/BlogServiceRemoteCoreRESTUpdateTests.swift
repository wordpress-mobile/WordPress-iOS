import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
import WordPressAPI
@testable import WordPress
@testable import WordPressCore

final class BlogServiceRemoteCoreRESTUpdateTests: XCTestCase {

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testTitleOnlyUpdateSendsOnlyTitle() async throws {
        let api = try WordPressAPI(
            urlSession: URLSession(configuration: .ephemeral),
            siteInfo: .selfHosted(
                siteUrl: .parse(input: "https://example.com"),
                apiRoot: .parse(input: "https://example.com/wp-json")
            ),
            authentication: .none
        )
        // WordPressClient's init eagerly starts api-root/user/theme/settings
        // tasks. Install a host-wide stub before constructing it so those hit
        // the stub instead of the network; the more specific settings stub
        // registered below takes precedence for the request under test.
        stub(condition: isHost("example.com")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let client = WordPressClient(api: api, siteURL: URL(string: "https://example.com")!)
        let remote = BlogServiceRemoteCoreREST(client: client)

        var capturedBody: [String: Any] = [:]
        stub(condition: { $0.url?.absoluteString.contains("/wp/v2/settings") == true || $0.url?.query?.contains("rest_route") == true }) { request in
            if let body = request.ohhttpStubs_httpBody,
                let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            {
                capturedBody = json
            }
            return HTTPStubsResponse(
                data: WordPressClientSiteSettingsTests.settingsJSON.data(using: .utf8)!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        let sparse = RemoteBlogSettings()
        sparse.name = "Updated Title"
        try await remote.updateBlogSettings(sparse)

        XCTAssertEqual(capturedBody["title"] as? String, "Updated Title")
        XCTAssertNil(capturedBody["description"])
        XCTAssertNil(capturedBody["default_comment_status"])
        XCTAssertNil(capturedBody["site_icon"])
    }
}
