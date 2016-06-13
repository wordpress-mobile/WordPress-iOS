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
}
