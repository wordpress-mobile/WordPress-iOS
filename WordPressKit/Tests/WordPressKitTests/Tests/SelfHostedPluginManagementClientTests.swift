import Foundation
import XCTest
import OHHTTPStubs

@testable import WordPressKit

class SelfHostedPluginManagementClientTests: XCTestCase {

    override func setUp() {
        super.setUp()

        stub(condition: { _ in true }) {
            XCTFail("Unexpected request: \($0)")
            return HTTPStubsResponse(error: URLError(URLError.Code.networkConnectionLost))
        }
    }

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()
    }

    func testGetPluginsSuccess() throws {
        let response = try fixture(filePath: XCTUnwrap(OHPathForFile("self-hosted-plugins-get.json", type(of: self))), headers: nil)
        stub(condition: isHost("wp-site.com") && isPath("/wp-json/wp/v2/plugins")) { _ in
            response
        }

        let client = SelfHostedPluginManagementClient(with: WordPressOrgRestApi(apiBase: URL(string: "https://wp-site.com/wp-json")!))
        let success = expectation(description: "Get plugins successfully")
        client?.getPlugins(success: { plugins in
            XCTAssertEqual(plugins.plugins.count, 4)

            let plugin = plugins.plugins.first
            XCTAssertEqual(plugin?.name, "Akismet Anti-spam: Spam Protection")
            XCTAssertEqual(plugin?.id, "akismet/akismet")
            XCTAssertEqual(plugin?.slug, "akismet")
            XCTAssertEqual(plugin?.active, true)
            XCTAssertEqual(plugin?.url?.absoluteString, "https://akismet.com/")

            success.fulfill()
        }, failure: {
            XCTFail("Unexpected failure: \($0)")
        })

        wait(for: [success], timeout: 0.3)
    }

    func testGetPluginsFailure() throws {
        stub(condition: isHost("wp-site.com") && isPath("/wp-json/wp/v2/plugins")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }

        let client = SelfHostedPluginManagementClient(with: WordPressOrgRestApi(apiBase: URL(string: "https://wp-site.com/wp-json")!))
        let failure = expectation(description: "Get plugins successfully")
        client?.getPlugins(success: {
            XCTFail("Unexpected success: \($0)")
        }, failure: { _ in
            failure.fulfill()
        })
        wait(for: [failure], timeout: 0.3)
    }

    func testActivatePlugin() {
        stub(condition: isHost("wp-site.com")
             && isPath("/wp-json/wp/v2/plugins/akismet/akismet")
             && isMethodPUT()
             && hasBody("status=active".data(using: .utf8)!)
        ) { _ in
            HTTPStubsResponse(data: "{}".data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let client = SelfHostedPluginManagementClient(with: WordPressOrgRestApi(apiBase: URL(string: "https://wp-site.com/wp-json")!))
        let success = expectation(description: "Get plugins successfully")
        client?.activatePlugin(pluginID: "akismet/akismet", success: success.fulfill, failure: { XCTFail("Unexpected failure: \($0)") })

        wait(for: [success], timeout: 0.3)
    }

    func testDeactivatePlugin() {
        stub(condition: isHost("wp-site.com")
             && isPath("/wp-json/wp/v2/plugins/akismet/akismet")
             && isMethodPUT()
             && hasBody("status=inactive".data(using: .utf8)!)
        ) { _ in
            HTTPStubsResponse(data: "{}".data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let client = SelfHostedPluginManagementClient(with: WordPressOrgRestApi(apiBase: URL(string: "https://wp-site.com/wp-json")!))
        let success = expectation(description: "Get plugins successfully")
        client?.deactivatePlugin(pluginID: "akismet/akismet", success: success.fulfill, failure: { XCTFail("Unexpected failure: \($0)") })

        wait(for: [success], timeout: 0.3)
    }

    func testInstallPlugin() throws {
        let response = try fixture(filePath: XCTUnwrap(OHPathForFile("self-hosted-plugins-install.json", type(of: self))), headers: nil)
        stub(condition: isHost("wp-site.com")
             && isPath("/wp-json/wp/v2/plugins")
             && isMethodPOST()
             && hasBody("slug=google-site-kit".data(using: .utf8)!)
        ) { _ in
            response
        }

        let client = SelfHostedPluginManagementClient(with: WordPressOrgRestApi(apiBase: URL(string: "https://wp-site.com/wp-json")!))
        let success = expectation(description: "Get plugins successfully")
        client?.install(pluginSlug: "google-site-kit", success: { _ in success.fulfill() }, failure: { XCTFail("Unexpected failure: \($0)") })

        wait(for: [success], timeout: 0.3)
    }

}
