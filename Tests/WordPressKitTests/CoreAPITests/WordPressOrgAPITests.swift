import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPressKit

class WordPressOrgAPITests: XCTestCase {

    let fakeCredential = WordPressOrgRestApi.SelfHostedSiteCredential(
        loginURL: URL(string: "https://wordpress.org/wp-login.php")!,
        username: "test-user",
        password: "test-password",
        adminURL: URL(string: "https://wordpress.org/wp-admin/")!
    )

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    func testSelfHostedSiteSimpleGet() async {
        let expectation = expectation(description: "matches request conditions")
        stub(condition: isMethodGET() && isAbsoluteURLString("https://wordpress.org/wp-json/wp/v2/hello-world?foo=bar")) { _ in
            expectation.fulfill()
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let api = WordPressOrgRestApi(selfHostedSiteWPJSONURL: URL(string: "https://wordpress.org/wp-json/")!, credential: fakeCredential)
        let _ = await api.get(path: "wp/v2/hello-world", parameters: ["foo": "bar"], type: AnyResponse.self)
        await fulfillment(of: [expectation], timeout: 0.1)
    }

    func testSelfHostedSiteSimplePost() async {
        let expectation = expectation(description: "matches request conditions")
        stub(condition: isMethodPOST() && isAbsoluteURLString("https://wordpress.org/wp-json/wp/v2/hello-world")) { request in
            XCTAssertEqual(request.httpBodyText, "foo=bar")
            expectation.fulfill()
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let api = WordPressOrgRestApi(selfHostedSiteWPJSONURL: URL(string: "https://wordpress.org/wp-json/")!, credential: fakeCredential)
        let _ = await api.post(path: "wp/v2/hello-world", parameters: ["foo": "bar"], type: AnyResponse.self)
        await fulfillment(of: [expectation], timeout: 0.1)
    }

    func testWPComSiteSimpleGet() async {
        let expectation = expectation(description: "matches request conditions")
        stub(condition: isMethodGET() && isAbsoluteURLString("https://public-api.wordpress.com/wp/v2/sites/42/hello-world?foo=bar")) { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer faketoken")
            expectation.fulfill()
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let api = WordPressOrgRestApi(dotComSiteID: 42, bearerToken: "faketoken")
        let _ = await api.get(path: "wp/v2/hello-world", parameters: ["foo": "bar"], type: AnyResponse.self)
        await fulfillment(of: [expectation], timeout: 0.1)
    }

    func testWPComSiteSimplePost() async {
        let expectation = expectation(description: "matches request conditions")
        stub(condition: isMethodPOST() && isAbsoluteURLString("https://public-api.wordpress.com/wp/v2/sites/42/hello-world")) { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer faketoken")
            XCTAssertEqual(request.httpBodyText, "foo=bar")
            expectation.fulfill()
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let api = WordPressOrgRestApi(dotComSiteID: 42, bearerToken: "faketoken")
        let _ = await api.post(path: "wp/v2/hello-world", parameters: ["foo": "bar"], type: AnyResponse.self)
        await fulfillment(of: [expectation], timeout: 0.1)
    }

    func testUserAgent() async {
        let expectation = expectation(description: "matches user agents")
        expectation.expectedFulfillmentCount = 2
        stub(condition: { _ in true }) { request in
            expectation.fulfill()
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "fake-user-agent")
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        let selfHostedSite = WordPressOrgRestApi(selfHostedSiteWPJSONURL: URL(string: "https://wordpress.org/wp-json/")!, credential: fakeCredential, userAgent: "fake-user-agent")
        let _ = await selfHostedSite.get(path: "/wp/v2/hello-world", type: AnyResponse.self)

        let dotComSite = WordPressOrgRestApi(dotComSiteID: 42, bearerToken: "faketoken", userAgent: "fake-user-agent")
        let _ = await dotComSite.get(path: "/wp/v2/hello-world", type: AnyResponse.self)

        await fulfillment(of: [expectation], timeout: 0.1)
    }

    func testSelfHostedSiteAuthentication() async throws {
        // The expected API call sequence.
        // [/wp/v2/hello-world|401] -> [nonce-from-ajax|200] -> [/wp/v2/hello-world|200] -> END

        let unauthenticatedReuqest = expectation(description: "Call #1: call an endpoint with a unauthenticated request")
        let ajaxNonceRequest = expectation(description: "Call #2: call ajax endpoint to get nonce")
        let authenticatedReuqest = expectation(description: "Call #3: call an endpoint with an authenticated request")

        stub(condition: { $0.url?.lastPathComponent == "hello-world" }) { request in
            if request.value(forHTTPHeaderField: "X-WP-Nonce") == "fakenonce" {
                authenticatedReuqest.fulfill()
                return HTTPStubsResponse(jsonObject: [String: String](), statusCode: 200, headers: nil)
            } else {
                unauthenticatedReuqest.fulfill()
                return HTTPStubsResponse(jsonObject: [String: String](), statusCode: 401, headers: nil)
            }
        }

        stub(condition: { $0.url?.lastPathComponent == "admin-ajax.php" }) { _ in
            ajaxNonceRequest.fulfill()
            return HTTPStubsResponse(data: "fakenonce".data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let selfHostedSite = WordPressOrgRestApi(selfHostedSiteWPJSONURL: URL(string: "https://wordpress.org/wp-json/")!, credential: fakeCredential)
        let result = await selfHostedSite.get(path: "/wp/v2/hello-world", type: AnyResponse.self)

        // This call should not throw
        _ = try result.get()

        await fulfillment(of: [unauthenticatedReuqest, ajaxNonceRequest, authenticatedReuqest], timeout: 0.1, enforceOrder: true)

        // Remove added stubs and add a new one.
        let requestsHasNonce = expectation(description: "Call an endpoint with an authenticated request")
        requestsHasNonce.expectedFulfillmentCount = 3
        HTTPStubs.removeAllStubs()
        stub(condition: { $0.url?.lastPathComponent == "hello-world" }) { request in
            if request.value(forHTTPHeaderField: "X-WP-Nonce") == "fakenonce" {
                requestsHasNonce.fulfill()
                return HTTPStubsResponse(jsonObject: [String: String](), statusCode: 200, headers: nil)
            } else {
                XCTFail("Unexpected request: \(request)")
                return HTTPStubsResponse(jsonObject: [String: String](), statusCode: 401, headers: nil)
            }
        }

        // Call the same API three times, which should re-use the fetched nonce without refetching requests.
        let _ = await selfHostedSite.get(path: "/wp/v2/hello-world", type: AnyResponse.self)
        let _ = await selfHostedSite.get(path: "/wp/v2/hello-world", type: AnyResponse.self)
        let _ = await selfHostedSite.get(path: "/wp/v2/hello-world", type: AnyResponse.self)

        await fulfillment(of: [requestsHasNonce], timeout: 0.1)
    }

    func testSelfHostedSiteAuthenticationFailure() async throws {
        // The expected API call sequence.
        // [/wp/v2/hello-world|401] -> [nonce-from-ajax|401] -> [wp-login|401] -> [post-new|401] -> [wp-login|401] -> END.

        let unauthenticatedReuqest = expectation(description: "Call #1: call an endpoint with a unauthenticated request")
        let ajaxNonceRequest = expectation(description: "Call #2: call ajax endpoint to get nonce")
        let newPostWebpageRequest = expectation(description: "Call #3: get nonce from new post webpage")
        let loginRequest = expectation(description: "Authenticate during fetching the ajax and new post webpage")
        loginRequest.expectedFulfillmentCount = 2
        let authenticatedReuqest = expectation(description: "[Should never happen] call an endpoint with an authenticated request")
        authenticatedReuqest.isInverted = true

        stub(condition: { $0.url?.lastPathComponent == "hello-world" }) { request in
            if request.value(forHTTPHeaderField: "X-WP-Nonce") == "fakenonce" {
                authenticatedReuqest.fulfill()
                return HTTPStubsResponse(jsonObject: [String: String](), statusCode: 200, headers: nil)
            } else {
                unauthenticatedReuqest.fulfill()
                return HTTPStubsResponse(jsonObject: [String: String](), statusCode: 401, headers: nil)
            }
        }

        stub(condition: { $0.url?.lastPathComponent == "admin-ajax.php" }) { _ in
            ajaxNonceRequest.fulfill()
            return HTTPStubsResponse(jsonObject: [String: String](), statusCode: 401, headers: nil)
        }

        stub(condition: { $0.url?.lastPathComponent == "post-new.php" }) { _ in
            newPostWebpageRequest.fulfill()
            return HTTPStubsResponse(jsonObject: [String: String](), statusCode: 401, headers: nil)
        }

        stub(condition: { $0.url?.lastPathComponent == "wp-login.php" }) { _ in
            loginRequest.fulfill()
            return HTTPStubsResponse(jsonObject: [String: String](), statusCode: 401, headers: nil)
        }

        let selfHostedSite = WordPressOrgRestApi(selfHostedSiteWPJSONURL: URL(string: "https://wordpress.org/wp-json/")!, credential: fakeCredential)
        let result = await selfHostedSite.get(path: "/wp/v2/hello-world", type: AnyResponse.self)

        if case .failure = result {
            // Do nothing
        } else {
            XCTFail("Unexpected result: \(result)")
        }

        await fulfillment(of: [unauthenticatedReuqest, ajaxNonceRequest, newPostWebpageRequest, loginRequest], timeout: 0.1, enforceOrder: true)
        await fulfillment(of: [authenticatedReuqest], timeout: 0.1)
    }

    func testNoRetryInWPComSite() async {
        let expectation = expectation(description: "matches request conditions")
        stub(condition: isMethodGET() && isAbsoluteURLString("https://public-api.wordpress.com/wp/v2/sites/42/hello-world?foo=bar")) { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer faketoken")
            expectation.fulfill()
            return HTTPStubsResponse(jsonObject: [String: String](), statusCode: 401, headers: nil)
        }
        let api = WordPressOrgRestApi(dotComSiteID: 42, bearerToken: "faketoken")
        let _ = await api.get(path: "wp/v2/hello-world", parameters: ["foo": "bar"], type: AnyResponse.self)
        await fulfillment(of: [expectation], timeout: 0.1)
    }

}

private struct AnyResponse: Decodable {}
