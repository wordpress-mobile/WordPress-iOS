import XCTest
import WordPress
import OHHTTPStubs

class WordPressOrgXMLRPCApiTests: XCTestCase {

    let xmlrpcEndpoint = "http://wordpress.org/xmlrpc.php"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    private func isXmlRpcAPIRequest() -> OHHTTPStubsTestBlock {
        return { request in
            return request.URL?.absoluteString == self.xmlrpcEndpoint
        }
    }

    func testSuccessfullCall() {
        stub(isXmlRpcAPIRequest()) { request in
            let stubPath = OHPathForFile("xmlrpc-response-getpost.xml", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type":"application/xml"])
        }

        let expectation = self.expectationWithDescription("One callback should be invoked")
        let api = WordPressOrgXMLRPCApi(apiBaseURLString:xmlrpcEndpoint)
        api.callMethod("", parameters:nil, success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
            expectation.fulfill()
            XCTAssert(responseObject is [String:AnyObject], "The response should be a dictionary")
            }, failure: { (error, httpResponse) in
                expectation.fulfill()
                XCTFail("This call should be successfull")
            }
        )
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

}
