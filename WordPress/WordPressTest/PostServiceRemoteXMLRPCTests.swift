@testable import WordPress
import wpxmlrpc

class PostServiceRemoteXMLRPCTests: RemoteTestCase, XMLRPCTestable {

    // MARK: - Constants

    let postID: NSNumber = 1
    let postTitle = "Hello world!"

    let getPostSuccessMockFilename          = "xmlrpc-wp-getpost-success.xml"
    let getPostBadXMLFailureFilename        = "xmlrpc-wp-getpost-bad-xml-failure.xml"
    let getPostBadPostIdFailureFilename     = "xmlrpc-wp-getpost-invalid-id-failure.xml"

    // MARK: - Properties

    var remote: Any?

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = PostServiceRemoteXMLRPC(api: getXmlRpcApi(), username: XMLRPCTestableConstants.xmlRpcUserName, password: XMLRPCTestableConstants.xmlRpcPassword)
    }

    override func tearDown() {
        super.tearDown()
        
        remote = nil
    }

    // MARK: - Get Post Tests

    func testGetPostSucceeds() {
        let expect = expectation(description: "Get post success")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl, filename: getPostSuccessMockFilename, contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            remoteInstance.getPostWithID(postID, success: { post in
                XCTAssertEqual(post?.postID, self.postID, "The post ids should be equal")
                XCTAssertEqual(post?.title, self.postTitle, "The post titles should be equal")
                expect.fulfill()
            }) { error in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetPostWithBadIdFails() {
        let expect = expectation(description: "Get post with bad post ID failure")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl, filename: getPostBadPostIdFailureFilename, contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            remoteInstance.getPostWithID(postID, success: { post in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }) { error in
                guard let error = error as NSError? else {
                    XCTFail("The returned error could not be cast as NSError")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(error.domain, WPXMLRPCFaultErrorDomain, "The error domain should be WPXMLRPCFaultErrorDomain")
                XCTAssertEqual(error.code, XMLRPCTestableConstants.xmlRpcNotFoundErrorCode, "The error code should be 404")
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetPostWithBadAuthFails() {
        let expect = expectation(description: "Get post with bad Auth failure")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl, filename: XMLRPCTestableConstants.xmlRpcBadAuthFailureFilename, contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            remoteInstance.getPostWithID(postID, success: { post in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }) { error in
                guard let error = error as NSError? else {
                    XCTFail("The returned error could not be cast as NSError")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(error.domain, WPXMLRPCFaultErrorDomain, "The error domain should be WPXMLRPCFaultErrorDomain")
                XCTAssertEqual(error.code, XMLRPCTestableConstants.xmlRpcBadAuthErrorCode, "The error code should be 403")
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetPostWithMalformedResponseXMLFails() {
        let expect = expectation(description: "Get posts with invalid XML response failure")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl, filename: XMLRPCTestableConstants.xmlRpcMalformedXMLFailureFilename, contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            remoteInstance.getPostWithID(postID, success: { post in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }) { error in
                guard let error = error as NSError? else {
                    XCTFail("The returned error could not be cast as NSError")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(error.domain, WPXMLRPCFaultErrorDomain, "The error domain should be WPXMLRPCFaultErrorDomain")
                XCTAssertEqual(error.code, XMLRPCTestableConstants.xmlRpcParseErrorCode, "The error code should be 403")
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
