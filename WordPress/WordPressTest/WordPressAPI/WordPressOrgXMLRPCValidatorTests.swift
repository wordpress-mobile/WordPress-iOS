import XCTest
import WordPress
import OHHTTPStubs

public class WordPressOrgXMLRPCValidatorTests: XCTestCase {

    let xmlrpcEndpoint = "http://wordpress.org/xmlrpc.php"

    public override func setUp() {
        super.setUp()
    }

    public override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    private func isXmlRpcAPIRequest() -> OHHTTPStubsTestBlock {
        return { request in
            return request.URL?.absoluteString == self.xmlrpcEndpoint
        }
    }

    public func testGuessXMLRPCURLForSiteForEmptyURLs() {
        var errorToCheck: NSError?
        let validator = WordPressOrgXMLRPCValidator()
        let emptyURLs = ["", "   ", "\t   "]
        for emptyURL in emptyURLs {
            let expectationEmpty = self.expectationWithDescription("Call should fail with error when invoking with empty string")
            validator.guessXMLRPCURLForSite(emptyURL, success:{ (xmlrpcURL) in
                    expectationEmpty.fulfill()
                    XCTFail("This call should fail")
                }, failure:{ (error) in
                    print(error)
                    expectationEmpty.fulfill()
                    errorToCheck = error
            })
            self.waitForExpectationsWithTimeout(2, handler:nil)
            XCTAssertTrue(errorToCheck?.domain == String(reflecting:WordPressOrgXMLRPCValidatorError.self), "Expected to get an WordPressXMLRPCApiErrorDomain error")
            XCTAssertTrue(errorToCheck?.code == WordPressOrgXMLRPCValidatorError.EmptyURL.rawValue, "Expected to get an WordPressXMLRPCApiEmptyURL error")
        }
    }

    public func testGuessXMLRPCURLForSiteForMalformedURLs() {
        var errorToCheck: NSError?
        let validator = WordPressOrgXMLRPCValidator()
        let malformedURLs = ["mywordpresssite.com\test", "mywordpres ssite.com/test", "http:\\mywordpresssite.com/test"]
        for malformedURL in malformedURLs {
            let expectationMalFormedURL = self.expectationWithDescription("Call should fail with error when invoking with malformed urls")
            validator.guessXMLRPCURLForSite(malformedURL, success:{ (xmlrpcURL) in
                expectationMalFormedURL.fulfill()
                XCTFail("This call should fail")
                }, failure:{ (error) in
                expectationMalFormedURL.fulfill()
                errorToCheck = error
            })
            self.waitForExpectationsWithTimeout(2, handler:nil)
            XCTAssertTrue(errorToCheck?.domain == String(reflecting:WordPressOrgXMLRPCValidatorError.self), "Expected to get an WordPressXMLRPCApiErrorDomain error")
            XCTAssertTrue(errorToCheck?.code == WordPressOrgXMLRPCValidatorError.InvalidURL.rawValue, "Expected to get an WordPressXMLRPCApiEmptyURL error")
        }
    }

    public func testGuessXMLRPCURLForSiteForInvalidSchemes() {
        var errorToCheck: NSError?
        let validator = WordPressOrgXMLRPCValidator()
        let incorrectSchemes = ["hppt://mywordpresssite.com/test", "ftp://mywordpresssite.com/test", "git://mywordpresssite.com/test"]
        for incorrectScheme in incorrectSchemes {
            let expectation = self.expectationWithDescription("Call should fail with error when invoking with urls with incorrect schemes")
            validator.guessXMLRPCURLForSite(incorrectScheme , success:{ (xmlrpcURL) in
                expectation.fulfill()
                XCTFail("This call should fail")
                }, failure:{ (error) in
                    expectation.fulfill()
                    errorToCheck = error
            })
            self.waitForExpectationsWithTimeout(2, handler:nil)
            XCTAssertTrue(errorToCheck?.domain == String(reflecting:WordPressOrgXMLRPCValidatorError.self), "Expected to get an WordPressXMLRPCApiErrorDomain error")
            XCTAssertTrue(errorToCheck?.code == WordPressOrgXMLRPCValidatorError.InvalidScheme.rawValue, "Expected to get an WordPressXMLRPCApiEmptyURL error")
        }
    }

    func testGuessXMLRPCURLForSiteForAdditionOfXMLRPC() {
        stub(isXmlRpcAPIRequest()) { request in
            let stubPath = OHPathForFile("xmlrpc-response-system-listmethods.xml", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type":"application/xml"])
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
            validator.guessXMLRPCURLForSite(url , success:{ (xmlrpcURL) in
                expectation.fulfill()
                XCTAssertEqual(xmlrpcURL.host, "mywordpresssite.com", "Resolved host doens't match original url: \(url)")
                XCTAssertEqual(xmlrpcURL.lastPathComponent, "xmlrpc.php", "Resolved last path component doens't match original url: \(url)")
                    if xmlrpcURL.query != nil {
                        XCTAssertEqual(xmlrpcURL.query, "test=test", "Resolved query components doens't match original url: \(url)")
                    }
                }, failure:{ (error) in
                    expectation.fulfill()
                    XCTFail("This call should succeed")
            })
            self.waitForExpectationsWithTimeout(2, handler:nil)
        }
    }
}
