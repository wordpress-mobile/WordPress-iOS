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

    fileprivate func isXmlRpcAPIRequest() -> OHHTTPStubsTestBlock {
        return { request in
            return request.url?.absoluteString == self.xmlrpcEndpoint
        }
    }

    func testSuccessfullCall() {
        stub(condition: isXmlRpcAPIRequest()) { request in
            let stubPath = OHPathForFile("xmlrpc-response-getpost.xml", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type" as NSObject: "application/xml" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let api = WordPressOrgXMLRPCApi(endpoint: URL(string: xmlrpcEndpoint)! as URL)
        api.callMethod("wp.getPost", parameters: nil, success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
            expect.fulfill()
            XCTAssert(responseObject is [String: AnyObject], "The response should be a dictionary")
            }, failure: { (error, httpResponse) in
                expect.fulfill()
                XCTFail("This call should be successfull")
            }
        )
        self.waitForExpectations(timeout: 2, handler: nil)
    }

}
