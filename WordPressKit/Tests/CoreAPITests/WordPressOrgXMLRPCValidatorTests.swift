import XCTest
import OHHTTPStubs
#if SWIFT_PACKAGE
@testable import CoreAPI
import OHHTTPStubsSwift
#else
@testable import WordPressKit
#endif

final class WordPressOrgXMLRPCValidatorTests: XCTestCase {

    private let exampleURLString = "http://example.com"

    override func setUp() {
        super.setUp()

        // Report error on all unknown requests
        stub(condition: { _ in true }) {
            XCTFail("Unexpected request: \($0)")
            return HTTPStubsResponse(error: URLError(URLError.Code.timedOut))
        }
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    func testItWillGuessXMLRPCOnHTTPSOnlyByDefault() {
        // Given
        var schemes = Set<String>()
        // Stub all, we only care about the URL schemes that are being tested.
        stub(condition: { request -> Bool in
            if let scheme = request.url?.scheme {
                schemes.insert(scheme)
            }
            return true
        }, response: { _ in
            let error = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
            return HTTPStubsResponse(error: error)
        })

        let validator = WordPressOrgXMLRPCValidator()

        // When
        let expectation = self.expectation(description: "Wait for success or failure")
        validator.guessXMLRPCURLForSite(exampleURLString, userAgent: "", success: { _ in
            expectation.fulfill()
        }, failure: { _ in
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 2.0)

        // Then
        if #available(iOS 16.0, *) {
            // 'NSAllowsArbitraryLoads' is true on iOS 16.
            XCTAssertEqual(schemes, ["https", "http"])
        } else {
            XCTAssertEqual(schemes, ["https"])
        }
    }

    func testItWillGuessXMLRPCOnBothHTTPAndHTTPSIfUnsecuredConnectionsAreAllowed() {
        // Given
        var schemes = Set<String>()
        // Stub all, we only care about the URL schemes that are being tested.
        stub(condition: { request -> Bool in
            if let scheme = request.url?.scheme {
                schemes.insert(scheme)
            }
            return true
        }, response: { _ in
            let error = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
            return HTTPStubsResponse(error: error)
        })

        let validator = WordPressOrgXMLRPCValidator(makeUnsecuredAppTransportSecuritySettings())

        // When
        let expectation = self.expectation(description: "Wait for success or failure")
        validator.guessXMLRPCURLForSite(exampleURLString, userAgent: "", success: { _ in
            expectation.fulfill()
        }, failure: { _ in
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 2.0)

        // Then
        XCTAssertEqual(schemes, Set(arrayLiteral: "https", "http"))
    }

    func testNotWordPressSiteError() throws {
        // Create HTTP stubs to simulate a plain static website
        // - Return a plain HTML webpage for all GET requests
        // - Return a 405 method not allowed error for all POST requests
        let path = try XCTUnwrap(xmlrpcResponseInvalidPath)
        stub(condition: isHost("www.apple.com") && isMethodGET()) { _ in
            fixture(filePath: path, status: 200, headers: nil)
        }
        stub(condition: isHost("www.apple.com") && isMethodPOST()) { _ in
            fixture(filePath: path, status: 405, headers: nil)
        }

        let failure = self.expectation(description: "returns error")
        let validator = WordPressOrgXMLRPCValidator()
        validator.guessXMLRPCURLForSite("https://www.apple.com/", userAgent: "test/1.0", success: {
            XCTFail("Unexpected result: \($0)")
        }) { error in
            XCTAssertTrue(error is WordPressOrgXMLRPCValidatorError)
            let validatorError = error as? WordPressOrgXMLRPCValidatorError
            // Since the we simulate a plain static website in this test case, a 'notWordPressError' is the best error
            // case to represent the error. But the current implementation returns an 'invalid' error, which is true too.
            XCTAssertTrue(validatorError == .invalid || validatorError == .notWordPressError, "Got an error: \(error)")
            failure.fulfill()
        }
        wait(for: [failure], timeout: 0.3)
    }

    func testSuccessWithSiteAddress() throws {
        let path = try XCTUnwrap(
            OHPathForFileInBundle("xmlrpc-response-list-methods.xml", Bundle.coreAPITestsBundle)
        )
        stub(condition: isHost("www.apple.com") && isPath("/blog/xmlrpc.php")) { _ in
            fixture(
                filePath: path,
                status: 200,
                headers: [
                    "Content-Type": "application/xml"
                ]
            )
        }

        let success = self.expectation(description: "success result")
        let validator = WordPressOrgXMLRPCValidator()
        validator.guessXMLRPCURLForSite("https://www.apple.com/blog", userAgent: "test/1.0", success: {
            XCTAssertEqual($0.absoluteString, "https://www.apple.com/blog/xmlrpc.php")
            success.fulfill()
        }) {
            XCTFail("Unexpected result: \($0)")
        }
        wait(for: [success], timeout: 0.3)
    }

    func testSuccessWithIrregularXMLRPCAddress() throws {
        let apiCalls = [
            expectation(description: "Request #1: call xmlrpc.php"),
            expectation(description: "Request #2: call the url argument"),
        ]

        let responseInvalidPath = try XCTUnwrap(xmlrpcResponseInvalidPath)
        stub(condition: isHost("www.apple.com") && isPath("/blog/xmlrpc.php")) { _ in
            apiCalls[0].fulfill()
            return fixture(filePath: responseInvalidPath, status: 403, headers: nil)
        }

        let responseListPath = try XCTUnwrap(
            OHPathForFileInBundle("xmlrpc-response-list-methods.xml", Bundle.coreAPITestsBundle)
        )
        stub(condition: isHost("www.apple.com") && isPath("/blog")) { _ in
            apiCalls[1].fulfill()
            return fixture(
                filePath: responseListPath,
                status: 200,
                headers: [
                    "Content-Type": "application/xml"
                ]
            )
        }

        let success = self.expectation(description: "success result")
        let validator = WordPressOrgXMLRPCValidator()
        validator.guessXMLRPCURLForSite("https://www.apple.com/blog", userAgent: "test/1.0", success: {
            XCTAssertEqual($0.absoluteString, "https://www.apple.com/blog")
            success.fulfill()
        }) {
            XCTFail("Unexpected result: \($0)")
        }
        wait(for: apiCalls + [success], timeout: 0.3, enforceOrder: true)
    }

    func testSuccessWithRSDLink() throws {
        let responseInvalidPath = try XCTUnwrap(xmlrpcResponseInvalidPath)
        stub(condition: isHost("www.apple.com") && isPath("/blog/xmlrpc.php")) { _ in
            return fixture(filePath: responseInvalidPath, status: 403, headers: nil)
        }

        stub(condition: isHost("www.apple.com") && isPath("/blog")) { _ in
            let html = """
                <!DOCTYPE html>
                <html>
                    <head>
                        <link rel="EditURI" type="application/rsd+xml" title="RSD" href="https://www.apple.com/blog/rsd" />
                        <title>test site</title>
                    </head>
                    <body>hello world</body>
                </html>
                """
            return HTTPStubsResponse(data: html.data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        stub(condition: isAbsoluteURLString("https://www.apple.com/blog/rsd")) { _ in
            // Grabbed from https://developer.wordpress.org/xmlrpc.php?rsd
            let xml = """
                <?xml version="1.0" encoding="UTF-8"?><rsd version="1.0" xmlns="http://archipelago.phrasewise.com/rsd">
                    <service>
                        <engineName>WordPress</engineName>
                        <engineLink>https://wordpress.org/</engineLink>
                        <homePageLink>https://developer.wordpress.org</homePageLink>
                        <apis>
                            <api name="WordPress" blogID="1" preferred="true" apiLink="https://www.apple.com/blog-xmlrpc.php" />
                            <api name="Movable Type" blogID="1" preferred="false" apiLink="https://www.apple.com/blog-xmlrpc.php" />
                            <api name="MetaWeblog" blogID="1" preferred="false" apiLink="https://www.apple.com/blog-xmlrpc.php" />
                            <api name="Blogger" blogID="1" preferred="false" apiLink="https://www.apple.com/blog-xmlrpc.php" />
                                <api name="WP-API" blogID="1" preferred="false" apiLink="https://www.apple.com/blog-wp-json/" />
                            </apis>
                    </service>
                </rsd>
                """
            return HTTPStubsResponse(
                data: xml.data(using: .utf8)!,
                statusCode: 200,
                headers: [
                    "Content-Type": "application/xml"
                ]
            )
        }

        let responseList = try XCTUnwrap(
            OHPathForFileInBundle("xmlrpc-response-list-methods.xml", Bundle.coreAPITestsBundle)
        )
        stub(condition: isHost("www.apple.com") && isPath("/blog-xmlrpc.php")) { _ in
            fixture(
                filePath: responseList,
                status: 200,
                headers: [
                    "Content-Type": "application/xml"
                ]
            )
        }

        let success = self.expectation(description: "success result")
        let validator = WordPressOrgXMLRPCValidator()
        validator.guessXMLRPCURLForSite("https://www.apple.com/blog", userAgent: "test/1.0", success: {
            XCTAssertEqual($0.absoluteString, "https://www.apple.com/blog-xmlrpc.php")
            success.fulfill()
        }) {
            XCTFail("Unexpected result: \($0)")
        }
        wait(for: [success], timeout: 0.3)
    }

    func testManyRedirectsError() throws {
        // redirect 'POST /redirect/<num>' to '/redirect/<num + 1>'.
        for number in 1...30 {
            stub(condition: isMethodPOST() && { $0.url!.path.hasPrefix("/redirect/\(number)-req") }) {
                HTTPStubsResponse(data: Data(), statusCode: 302, headers: [
                    "Location": $0.url!.absoluteString.replacingOccurrences(of: "/redirect/\(number)-req", with: "/redirect/\(number + 1)-req")
                ])
            }
        }

        // All GET requests get a html webpage.
        let path = try XCTUnwrap(xmlrpcResponseInvalidPath)
        stub(condition: isMethodGET()) { _ in
            fixture(filePath: path, status: 405, headers: nil)
        }

        let failure = self.expectation(description: "returns error")
        let validator = WordPressOrgXMLRPCValidator()
        validator.guessXMLRPCURLForSite("https://www.apple.com/redirect/1-req", userAgent: "test/1.0", success: {
            XCTFail("Unexpected result: \($0)")
        }) { error in
            // The test site here returns many redirection response, a 'httpTooManyRedirects' is the best error
            // case to represent the error. But the current implementation returns an 'invalid' error, which is true too.
            XCTAssertTrue(
                (error as? WordPressOrgXMLRPCValidatorError == .invalid)
                    || (error as? URLError) == URLError(URLError.Code.httpTooManyRedirects),
                "Got an error: \(error)"
            )
            failure.fulfill()
        }
        wait(for: [failure], timeout: 0.3)
    }

    func testMobilePluginRedirectedError() throws {
        // redirect 'POST /redirect/<num>' to '/redirect/<num + 1>'.
        stub(condition: isMethodPOST() && isHost("www.apple.com")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 302, headers: [
                "Location": "https://m.apple.com"
            ])
        }
        let path = try XCTUnwrap(
            OHPathForFileInBundle("xmlrpc-response-mobile-plugin-redirect.html", Bundle.coreAPITestsBundle)
        )
        stub(condition: isMethodPOST() && isHost("m.apple.com")) { _ in
            fixture(
                filePath: path,
                status: 200,
                headers: nil
            )
        }

        let failure = self.expectation(description: "returns error")
        let validator = WordPressOrgXMLRPCValidator()
        validator.guessXMLRPCURLForSite("https://www.apple.com/xmlrpc.php", userAgent: "test/1.0", success: {
            XCTFail("Unexpected result: \($0)")
        }) { error in
            XCTAssertTrue(error is WordPressOrgXMLRPCValidatorError)
            // The test site here returns many redirection response, a 'httpTooManyRedirects' is the best error
            // case to represent the error. But the current implementation returns an 'invalid' error, which is true too.
            XCTAssertEqual(error as? WordPressOrgXMLRPCValidatorError, .mobilePluginRedirectedError)
            failure.fulfill()
        }
        wait(for: [failure], timeout: 0.3)
    }

    func testForbiddenError() {
        // All requests get a '403 Forbidden' error.
        stub(condition: isHost("www.apple.com")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 403, headers: nil)
        }

        let failure = self.expectation(description: "returns error")
        let validator = WordPressOrgXMLRPCValidator()
        validator.guessXMLRPCURLForSite("https://www.apple.com/xmlrpc.php", userAgent: "test/1.0", success: {
            XCTFail("Unexpected result: \($0)")
        }) { error in
            XCTAssertTrue(error is WordPressOrgXMLRPCValidatorError)
            let validatorError = error as? WordPressOrgXMLRPCValidatorError
            // The site returns 403 for all requests, a 'forbidden' error is the best error case to represent the error.
            // But the current implementation returns an 'invalid' error, which is true too.
            XCTAssertTrue(validatorError == .invalid || validatorError == .forbidden, "Got an error: \(error)")
            failure.fulfill()
        }
        wait(for: [failure], timeout: 0.3)
    }

    func testXMLRPCMissingError() {
        stub(condition: isAbsoluteURLString("https://www.apple.com/xmlrpc.php") || isAbsoluteURLString("http://www.apple.com/xmlrpc.php")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 403, headers: nil)
        }

        stub(condition: isHost("www.apple.com") && isMethodGET()) { _ in
            let html = """
            <!DOCTYPE html>
            <html>
                <head>
                    <link rel="EditURI" type="application/rsd+xml" title="RSD" href="https://www.apple.com/rsd" />
                    <title>test site</title>
                </head>
                <body>hello world</body>
            </html>
            """
            return HTTPStubsResponse(data: html.data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        stub(condition: isAbsoluteURLString("https://www.apple.com/rsd")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 404, headers: nil)
        }

        let failure = self.expectation(description: "returns error")
        let validator = WordPressOrgXMLRPCValidator()
        validator.guessXMLRPCURLForSite("https://www.apple.com/xmlrpc.php", userAgent: "test/1.0", success: {
            XCTFail("Unexpected result: \($0)")
        }) { error in
            XCTAssertTrue(error is WordPressOrgXMLRPCValidatorError)
            let validatorError = error as? WordPressOrgXMLRPCValidatorError
            // The site returns provides a RSD link that returns 404. A 'xmlrpc_missing' error is the best error case
            // to represent the error. But the current implementation returns an 'invalid' error, which is true too.
            XCTAssertTrue(validatorError == .xmlrpc_missing || validatorError == .invalid, "Got an error: \(error)")
            failure.fulfill()
        }
        wait(for: [failure], timeout: 0.3)
    }

    let xmlrpcResponseInvalidPath = OHPathForFileInBundle(
        "xmlrpc-response-invalid.html",
        Bundle.coreAPITestsBundle
    )
}

private extension WordPressOrgXMLRPCValidatorTests {
    func makeUnsecuredAppTransportSecuritySettings() -> AppTransportSecuritySettings {
        let provider = FakeInfoDictionaryObjectProvider(appTransportSecurity: [
            "NSAllowsArbitraryLoads": true
        ])

        return AppTransportSecuritySettings(provider)
    }
}
