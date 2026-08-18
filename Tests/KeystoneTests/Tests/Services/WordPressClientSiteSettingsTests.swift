import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
import WordPressAPI
import WordPressAPIInternal
@testable import WordPress
@testable import WordPressCore

final class WordPressClientSiteSettingsTests: XCTestCase {

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    private func makeClient() throws -> WordPressClient {
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
        // the stub instead of the network; each test's more specific stub,
        // registered later, takes precedence for the request under test.
        stub(condition: isHost("example.com")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        return WordPressClient(api: api, siteURL: URL(string: "https://example.com")!)
    }

    static let settingsJSON = """
        {"title":"Updated Title","description":"tag","url":"https://example.com",
         "email":"a@example.com","timezone":"","date_format":"F j, Y","time_format":"g:i a",
         "start_of_week":1,"language":"en_US","use_smilies":false,"default_category":1,
         "default_post_format":"0","posts_per_page":10,"show_on_front":"posts",
         "page_on_front":0,"page_for_posts":0,"default_ping_status":"open",
         "default_comment_status":"open","site_logo":null,"site_icon":0}
        """

    func testUpdateReplacesCachedSettings() async throws {
        let client = try makeClient()
        var requestCount = 0
        stub(condition: { $0.url?.absoluteString.contains("/wp/v2/settings") == true || $0.url?.query?.contains("rest_route") == true }) { _ in
            requestCount += 1
            return HTTPStubsResponse(
                data: Self.settingsJSON.data(using: .utf8)!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        let updated = try await client.updateSiteSettings(params: SiteSettingsUpdateParams(title: "Updated Title"))
        XCTAssertEqual(updated.title, "Updated Title")
        let updateRequests = requestCount

        // The cache must serve the update response without another request.
        let cached = try await client.fetchSiteSettings()
        XCTAssertEqual(cached.title, "Updated Title")
        XCTAssertEqual(requestCount, updateRequests)
    }
}
