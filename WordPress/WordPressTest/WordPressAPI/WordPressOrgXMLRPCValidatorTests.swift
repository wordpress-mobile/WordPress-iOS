import XCTest
import WordPress
import OHHTTPStubs

public class WordPressOrgXMLRPCValidatorTests: XCTestCase {

    let xmlrpcEndpoint = "http://mywordpresssite.com/xmlrpc.php"

    public override func setUp() {
        super.setUp()
    }

    public override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    private func isXmlRpcAPIRequest() -> OHHTTPStubsTestBlock {
        return { request in
            return request.URL?.host == "mywordpresssite.com"
        }
    }

    private func isAbsoluteURLString(urlString: String) -> OHHTTPStubsTestBlock {
        return { req in req.URL?.absoluteString == urlString }
    }

    public func testGuessXMLRPCURLForSiteForEmptyURLs() {
        var errorToCheck: NSError?
        let validator = WordPressOrgXMLRPCValidator()
        let emptyURLs = ["", "   ", "\t   "]
        for emptyURL in emptyURLs {
            let expectationEmpty = self.expectationWithDescription("Call should fail with error when invoking with empty string")
            validator.guessXMLRPCURLForSite(emptyURL, success: { (xmlrpcURL) in
                    expectationEmpty.fulfill()
                    XCTFail("This call should fail")
                }, failure: { (error) in
                    print(error)
                    expectationEmpty.fulfill()
                    errorToCheck = error
            })
            self.waitForExpectationsWithTimeout(2, handler: nil)
            XCTAssertTrue(errorToCheck?.domain == String(reflecting: WordPressOrgXMLRPCValidatorError.self), "Expected to get an WordPressOrgXMLRPCApiErrorDomain error")
            XCTAssertTrue(errorToCheck?.code == WordPressOrgXMLRPCValidatorError.EmptyURL.rawValue, "Expected to get an WordPressOrfXMLRPCApiEmptyURL error")
        }
    }

    public func testGuessXMLRPCURLForSiteForMalformedURLs() {
        var errorToCheck: NSError?
        let validator = WordPressOrgXMLRPCValidator()
        let malformedURLs = ["mywordpresssite.com\test", "mywordpres ssite.com/test", "http:\\mywordpresssite.com/test"]
        for malformedURL in malformedURLs {
            let expectationMalFormedURL = self.expectationWithDescription("Call should fail with error when invoking with malformed urls")
            validator.guessXMLRPCURLForSite(malformedURL, success: { (xmlrpcURL) in
                expectationMalFormedURL.fulfill()
                XCTFail("This call should fail")
                }, failure: { (error) in
                expectationMalFormedURL.fulfill()
                errorToCheck = error
            })
            self.waitForExpectationsWithTimeout(2, handler: nil)
            XCTAssertTrue(errorToCheck?.domain == String(reflecting: WordPressOrgXMLRPCValidatorError.self), "Expected to get an WordPressOrgXMLRPCApiErrorDomain error")
            XCTAssertTrue(errorToCheck?.code == WordPressOrgXMLRPCValidatorError.InvalidURL.rawValue, "Expected to get an WordPressOrgXMLRPCApiEmptyURL error")
        }
    }

    public func testGuessXMLRPCURLForSiteForInvalidSchemes() {
        var errorToCheck: NSError?
        let validator = WordPressOrgXMLRPCValidator()
        let incorrectSchemes = ["hppt://mywordpresssite.com/test", "ftp://mywordpresssite.com/test", "git://mywordpresssite.com/test"]
        for incorrectScheme in incorrectSchemes {
            let expectation = self.expectationWithDescription("Call should fail with error when invoking with urls with incorrect schemes")
            validator.guessXMLRPCURLForSite(incorrectScheme, success: { (xmlrpcURL) in
                expectation.fulfill()
                XCTFail("This call should fail")
                }, failure: { (error) in
                    expectation.fulfill()
                    errorToCheck = error
            })
            self.waitForExpectationsWithTimeout(2, handler: nil)
            XCTAssertTrue(errorToCheck?.domain == String(reflecting: WordPressOrgXMLRPCValidatorError.self), "Expected to get an WordPressOrgXMLRPCApiErrorDomain error")
            XCTAssertTrue(errorToCheck?.code == WordPressOrgXMLRPCValidatorError.InvalidScheme.rawValue, "Expected to get an WordPressOrgXMLRPCApiEmptyURL error")
        }
    }

    public func testGuessXMLRPCURLForSiteForCorrectSchemes() {

        stub(isXmlRpcAPIRequest()) { request in
            let stubPath = OHPathForFile("xmlrpc-response-system-listmethods.xml", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type": "application/xml"])
        }

        let validSchemes = ["http://mywordpresssite.com/xmlrpc.php",
                            "https://mywordpresssite.com/xmlrpc.php",
                            "mywordpresssite.com/xmlrpc.php"
        ]
        let validator = WordPressOrgXMLRPCValidator()
        for url in validSchemes {
            let expectation = self.expectationWithDescription("Callback should be successful")
            validator.guessXMLRPCURLForSite(url, success: { (xmlrpcURL) in
                expectation.fulfill()
                XCTAssertEqual(xmlrpcURL.host, "mywordpresssite.com", "Resolved host doens't match original url: \(url)")
                XCTAssertEqual(xmlrpcURL.lastPathComponent, "xmlrpc.php", "Resolved last path component doens't match original url: \(url)")
                }, failure: { (error) in
                    expectation.fulfill()
                    XCTFail("This call should succeed")
            })
            self.waitForExpectationsWithTimeout(2, handler: nil)
        }
    }

    func testGuessXMLRPCURLForSiteForAdditionOfXMLRPC() {
        stub(isXmlRpcAPIRequest()) { request in
            let stubPath = OHPathForFile("xmlrpc-response-system-listmethods.xml", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type": "application/xml"])
        }

        let urls = ["http://mywordpresssite.com",
                    "https://mywordpresssite.com",
                    "mywordpresssite.com",
                    "mywordpresssite.com/blog1",
                    "mywordpresssite.com/xmlrpc.php",
                    "mywordpresssite.com/xmlrpc.php?test=test"
        ]

        let validator = WordPressOrgXMLRPCValidator()
        for url in urls {
            let expectation = self.expectationWithDescription("Callback should be successful")
            validator.guessXMLRPCURLForSite(url, success: { (xmlrpcURL) in
                expectation.fulfill()
                XCTAssertEqual(xmlrpcURL.host, "mywordpresssite.com", "Resolved host doens't match original url: \(url)")
                XCTAssertEqual(xmlrpcURL.lastPathComponent, "xmlrpc.php", "Resolved last path component doens't match original url: \(url)")
                    if xmlrpcURL.query != nil {
                        XCTAssertEqual(xmlrpcURL.query, "test=test", "Resolved query components doens't match original url: \(url)")
                    }
                }, failure: { (error) in
                    expectation.fulfill()
                    XCTFail("This call should succeed")
            })
            self.waitForExpectationsWithTimeout(2, handler: nil)
        }
    }

    func testGuessXMLRPCURLForSiteForSucessfulRedirects() {
        let originalURL = "http://mywordpresssite.com/xmlrpc.php"
        let redirectedURL = "https://mywordpresssite.com/xmlrpc.php"

        // Fail first request with 301
        stub(isAbsoluteURLString(originalURL)) { request in
            let stubPath = OHPathForFile("xmlrpc-response-redirect.html", self.dynamicType)
            return fixture(stubPath!, status: 301, headers: ["Content-Type": "application/html", "Location": redirectedURL])
        }

        stub(isAbsoluteURLString(redirectedURL)) { request in
            let stubPath = OHPathForFile("xmlrpc-response-system-listmethods.xml", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type": "application/xml"])
        }

        let validator = WordPressOrgXMLRPCValidator()
        let expectation = self.expectationWithDescription("Call should be successful")
        validator.guessXMLRPCURLForSite(originalURL, success: { (xmlrpcURL) in
            expectation.fulfill()
            XCTAssertEqual(xmlrpcURL.absoluteString, redirectedURL, "Resolved host doens't match the redirected url: \(redirectedURL)")
            }, failure: { (error) in
                expectation.fulfill()
                XCTFail("This call should succeed")
        })
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    public func testGuessXMLRPCURLForSiteForFallbackToOriginalURL() {
        let originalURL = "http://mywordpresssite.com/rpc"
        let appendedURL = "\(originalURL)/xmlrpc.php"

        // Fail url with appended xmlrpc.php request with 403
        stub(isAbsoluteURLString(appendedURL)) { request in
            let stubPath = OHPathForFile("xmlrpc-response-redirect.html", self.dynamicType)
            return fixture(stubPath!, status: 403, headers: ["Content-Type": "application/html"])
        }

        stub(isAbsoluteURLString(originalURL)) { request in
            let stubPath = OHPathForFile("xmlrpc-response-system-listmethods.xml", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type": "application/xml"])
        }

        let validator = WordPressOrgXMLRPCValidator()
        let expectation = self.expectationWithDescription("Call should be successful")
        validator.guessXMLRPCURLForSite(originalURL, success: { (xmlrpcURL) in
            expectation.fulfill()
            XCTAssertEqual(xmlrpcURL.absoluteString, originalURL, "Resolved host doens't match the original url: \(originalURL)")
            }, failure: { (error) in
                expectation.fulfill()
                XCTFail("This call should succeed")
        })
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    public func testGuessXMLRPCURLForSiteForFallbackToStandardRSD() {
        let baseURL = "http://mywordpresssite.com"
        let htmlURL = baseURL.stringByAppendingString("wp-login")
        let appendedURL = htmlURL.stringByAppendingString("/xmlrpc.php")
        let xmlRPCURL = baseURL.stringByAppendingString("/xmlrpc.php")
        let rsdURL = xmlRPCURL.stringByAppendingString("?rsd")

        // Fail url with appended xmlrpc.php request with 403
        stub(isAbsoluteURLString(appendedURL)) { request in
            let stubPath = OHPathForFile("xmlrpc-response-redirect.html", self.dynamicType)!
            return fixture(stubPath, status: 403, headers: ["Content-Type": "application/html"])
        }

        // Return html page for original url
        stub(isAbsoluteURLString(htmlURL)) { request in
            let stubPath = OHPathForFile("html_page_with_link_to_rsd.html", self.dynamicType)!
            return fixture(stubPath, status: 200, headers: ["Content-Type": "application/html"])
        }

        // Return rsd xml
        stub(isAbsoluteURLString(rsdURL)) { request in
            let stubPath = OHPathForFile("rsd.xml", self.dynamicType)!
            return fixture(stubPath, status: 200, headers: nil)
        }

        stub(isAbsoluteURLString(xmlRPCURL)) { request in
            let stubPath = OHPathForFile("xmlrpc-response-system-listmethods.xml", self.dynamicType)!
            return fixture(stubPath, headers: ["Content-Type": "application/xml"])
        }

        let validator = WordPressOrgXMLRPCValidator()
        let expectation = self.expectationWithDescription("Call should be successful")
        validator.guessXMLRPCURLForSite(htmlURL, success: { (xmlrpcURL) in
            expectation.fulfill()
            XCTAssertEqual(xmlrpcURL.absoluteString, xmlRPCURL, "Resolved host doens't match the xml rpc url: \(xmlRPCURL)")
            }, failure: { (error) in
                expectation.fulfill()
                XCTFail("This call should succeed")
        })
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    public func testGuessXMLRPCURLForSiteForFallbackToNonStandardRSD() {
        let baseURL = "http://mywordpresssite.com"
        let htmlURL = baseURL.stringByAppendingString("wp-login")
        let appendedURL = htmlURL.stringByAppendingString("/xmlrpc.php")
        let xmlRPCURL = baseURL.stringByAppendingString("/xmlrpc.php")
        let rsdURL = baseURL.stringByAppendingString("/rsd.php")

        // Fail url with appended xmlrpc.php request with 403
        stub(isAbsoluteURLString(appendedURL)) { request in
            let stubPath = OHPathForFile("xmlrpc-response-redirect.html", self.dynamicType)!
            return fixture(stubPath, status: 403, headers: ["Content-Type": "application/html"])
        }

        // Return html page for original url
        stub(isAbsoluteURLString(htmlURL)) { request in
            let stubPath = OHPathForFile("html_page_with_link_to_rsd_non_standard.html", self.dynamicType)!
            return fixture(stubPath, status: 200, headers: ["Content-Type": "application/html"])
        }

        // Return rsd xml
        stub(isAbsoluteURLString(rsdURL)) { request in
            let stubPath = OHPathForFile("rsd.xml", self.dynamicType)!
            return fixture(stubPath, status: 200, headers: nil)
        }

        stub(isAbsoluteURLString(xmlRPCURL)) { request in
            let stubPath = OHPathForFile("xmlrpc-response-system-listmethods.xml", self.dynamicType)!
            return fixture(stubPath, headers: ["Content-Type": "application/xml"])
        }

        let validator = WordPressOrgXMLRPCValidator()
        let expectation = self.expectationWithDescription("Call should be successful")
        validator.guessXMLRPCURLForSite(htmlURL, success: { (xmlrpcURL) in
            expectation.fulfill()
            XCTAssertEqual(xmlrpcURL.absoluteString, xmlRPCURL, "Resolved host doens't match the xml rpc url: \(xmlRPCURL)")
            }, failure: { (error) in
                expectation.fulfill()
                XCTFail("This call should succeed")
        })
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    public func testGuessXMLRPCURLForSiteForFaultAnswers() {
        let originalURL = "http://originalURL/xmlrpc.php"
        stub(isAbsoluteURLString(originalURL)) { request in
            let stubPath = OHPathForFile("xmlrpc-response-fault.xml", self.dynamicType)!
            return fixture(stubPath, status: 200, headers: ["Content-Type": "application/xml"])
        }

        let validator = WordPressOrgXMLRPCValidator()
        let expectation = self.expectationWithDescription("Call should fail gracefull")
        validator.guessXMLRPCURLForSite(originalURL,
            success: { (xmlrpcURL) in
                expectation.fulfill()
                XCTFail("Call to faul responseshould not enter success block.")
            }, failure: { (error) in
                expectation.fulfill()
                XCTAssertTrue(!error.domain.isEmpty, "Check if we are getting an error message")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    public func testGuessXMLRPCURLForSiteForFailedPluginRedirects() {
        let originalURL = "http://mywordpresssite.com/xmlrpc.php"
        let redirectedURL = "https://mywordpresssite.com/xmlrpc.php"
        // Fail first request with 301
        stub(isAbsoluteURLString(originalURL)) { request in
            let stubPath = OHPathForFile("xmlrpc-response-redirect.html", self.dynamicType)
            return fixture(stubPath!, status: 301, headers: ["Content-Type": "application/html", "Location": redirectedURL])
        }

        stub(isAbsoluteURLString(redirectedURL)) { request in
            let stubPath = OHPathForFile("plugin_redirect.html", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type": "application/html"])
        }

        let validator = WordPressOrgXMLRPCValidator()
        let expectation = self.expectationWithDescription("Call should be successful")
        validator.guessXMLRPCURLForSite(originalURL, success: { (xmlrpcURL) in
            expectation.fulfill()
            XCTFail("Call that has a plugin redirect should fail")
            }, failure: { (error) in
                expectation.fulfill()
                XCTAssertTrue(error.domain == String(reflecting: WordPressOrgXMLRPCValidatorError.self), "Expected to get an WordPressOrgXMLRPCValidatorError error")
                XCTAssertTrue(error.code == WordPressOrgXMLRPCValidatorError.MobilePluginRedirectedError.rawValue, "Expected to get an .MobilePluginRedirectedError error code")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
}
