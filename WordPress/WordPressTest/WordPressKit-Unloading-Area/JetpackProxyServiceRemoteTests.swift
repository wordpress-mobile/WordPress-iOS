import XCTest
@testable import WordPressKit

class JetpackProxyServiceRemoteTests: XCTestCase {
    let timeout: TimeInterval = 1.0
    let api = MockWordPressComRestApi()
    let siteID = 1001

    private var remote: JetpackProxyServiceRemote {
        return .init(wordPressComRestApi: api)
    }

    // MARK: - Tests

    func testProxyRequestEndpoint() {
        // the mock rest API doesn't append the base URL, so we're just going to verify the path.
        let urlString = "rest/v1.1/jetpack-blogs/\(siteID)/rest-api"

        remote.proxyRequest(for: siteID, path: "path", method: .get) { _ in }

        guard let passedURLString = api.URLStringPassedIn else {
            return XCTFail()
        }
        XCTAssertTrue(passedURLString.hasSuffix(urlString))
    }

    func testJSONParameter() {
        remote.proxyRequest(for: siteID, path: "path", method: .get) { _ in }

        guard let passedParameter = api.parametersPassedIn as? [String: AnyObject] else {
            return XCTFail()
        }
        XCTAssertEqual(passedParameter["json"] as? String, "true")
    }

    func testPathParameter() {
        let path = "/wp/v2/posts"
        let method = JetpackProxyServiceRemote.DotComMethod.get

        remote.proxyRequest(for: siteID, path: path, method: method) { _ in }

        guard let passedParameter = api.parametersPassedIn as? [String: AnyObject] else {
            return XCTFail()
        }
        XCTAssertEqual(passedParameter["path"] as? String, "\(path)&_method=\(method.rawValue)")
    }

    func testBodyParameterKeyForGETMethod() {
        let method = JetpackProxyServiceRemote.DotComMethod.get
        let params = ["key": "value"]

        remote.proxyRequest(for: siteID, path: "path", method: method, parameters: params) { _ in }

        guard let passedParameter = api.parametersPassedIn as? [String: AnyObject] else {
            return XCTFail()
        }
        XCTAssertNotNil(passedParameter["query"])
    }

    func testBodyParameterKeyForPOSTMethod() {
        let method = JetpackProxyServiceRemote.DotComMethod.post
        let params = ["key": "value"]

        remote.proxyRequest(for: siteID, path: "path", method: method, parameters: params) { _ in }

        guard let passedParameter = api.parametersPassedIn as? [String: AnyObject] else {
            return XCTFail()
        }
        XCTAssertNotNil(passedParameter["body"])
    }

    func testBodyParameterEncoding() {
        let method = JetpackProxyServiceRemote.DotComMethod.post
        let params = [
            "key1": "value1",
            "key2": "value2"
        ]

        remote.proxyRequest(for: siteID, path: "path", method: method, parameters: params) { _ in }

        guard let passedParameter = api.parametersPassedIn as? [String: AnyObject],
              let jsonString = passedParameter["body"] as? String,
              let jsonData = jsonString.data(using: .utf8),
              let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] else {
            return XCTFail()
        }
        XCTAssertEqual(jsonDictionary, params)
    }

    func testBodyParameterShouldNotExistWhenEmpty() {
        let params = [String: String]()

        remote.proxyRequest(for: siteID, path: "path", method: .post, parameters: params) { _ in }

        guard let passedParameter = api.parametersPassedIn as? [String: AnyObject] else {
            return XCTFail()
        }
        XCTAssertNil(passedParameter["body"])
    }

    func testLocaleParameter() {
        let locale = "en_US"

        remote.proxyRequest(for: siteID, path: "path", method: .post, locale: locale) { _ in }

        guard let passedParameter = api.parametersPassedIn as? [String: AnyObject] else {
            return XCTFail()
        }
        XCTAssertEqual(passedParameter["locale"] as? String, locale)
    }

    func testLocaleParameterShouldNotExistWhenEmpty() {
        let locale = String()

        remote.proxyRequest(for: siteID, path: "path", method: .post, locale: locale) { _ in }

        guard let passedParameter = api.parametersPassedIn as? [String: AnyObject] else {
            return XCTFail()
        }
        XCTAssertNil(passedParameter["locale"])
    }
}
