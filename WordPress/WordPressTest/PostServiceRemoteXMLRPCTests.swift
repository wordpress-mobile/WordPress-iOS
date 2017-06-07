@testable import WordPress
import wpxmlrpc

class PostServiceRemoteXMLRPCTests: RemoteTestCase, XMLRPCTestable {

    // MARK: - Constants

    let postID: NSNumber = 1
    let postTitle = "Hello world!"
    let postContent = "Welcome to WordPress."

    let getPostSuccessMockFilename              = "xmlrpc-wp-getpost-success.xml"
    let getPostBadXMLFailureFilename            = "xmlrpc-wp-getpost-bad-xml-failure.xml"
    let getPostBadPostIdFailureFilename         = "xmlrpc-wp-getpost-invalid-id-failure.xml"
    let newPostSuccessMockFilename              = "xmlrpc-metaweblog-newpost-success.xml"
    let newPostBadResponseXMLMockFilename       = "xmlrpc-metaweblog-newpost-bad-xml-failure.xml"
    let newPostInvalidPostTypeMockFilename      = "xmlrpc-metaweblog-newpost-invalid-posttype-failure.xml"
    let updatePostSuccessMockFilename           = "xmlrpc-metaweblog-editpost-success.xml"
    let updatePostBadResponseXMLMockFilename    = "xmlrpc-metaweblog-editpost-bad-xml-failure.xml"
    let updatePostBadFormatMockFilename         = "xmlrpc-metaweblog-editpost-change-format-failure.xml"
    let updatePostChangeTypeFailureFilename     = "xmlrpc-metaweblog-editpost-change-type-failure.xml"

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
        let expect = expectation(description: "Get post with bad auth failure")

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
                XCTAssertEqual(error.code, XMLRPCTestableConstants.xmlRpcForbiddenErrorCode, "The error code should be 403")
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetPostWithMalformedResponseXMLFails() {
        let expect = expectation(description: "Get posts with invalid XML response failure")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl, filename: getPostBadXMLFailureFilename, contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            remoteInstance.getPostWithID(postID, success: { post in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }) { error in
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - New Post Tests

    func testNewPostSucceeds() {
        let expect = expectation(description: "New post success")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl,
                           files: [newPostSuccessMockFilename, getPostSuccessMockFilename],
                           contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.postID = postID
                post.title = postTitle
                post.content = postContent
                return post
            }()

            remoteInstance.createPost(remotePost, success: { post in
                XCTAssertEqual(post?.postID, remotePost.postID, "The post ids should be equal")
                XCTAssertEqual(post?.title, remotePost.title, "The post titles should be equal")
                XCTAssertEqual(post?.content, remotePost.content, "The posts' content should be equal")
                expect.fulfill()
            }) { error in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testNewPostWithInvalidPostTypeFails() {
        let expect = expectation(description: "New post with invalid posttype failure")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl,
                           filename: newPostInvalidPostTypeMockFilename,
                           contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.postID = postID
                post.title = postTitle
                post.content = postContent
                post.type = "Bananas"
                return post
            }()

            remoteInstance.createPost(remotePost, success: { post in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }) { error in
                guard let error = error as NSError? else {
                    XCTFail("The returned error could not be cast as NSError")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(error.domain, WPXMLRPCFaultErrorDomain, "The error domain should be WPXMLRPCFaultErrorDomain")
                XCTAssertEqual(error.code, XMLRPCTestableConstants.xmlRpcUnauthorizedErrorCode, "The error code should be 401")
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testNewPostWithMalformedResponseXMLFails() {
        let expect = expectation(description: "New post with invalid XML response failure")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl, filename: newPostBadResponseXMLMockFilename, contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.postID = postID
                post.title = postTitle
                post.content = postContent
                return post
            }()

            remoteInstance.createPost(remotePost, success: { post in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }) { error in
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testNewPostWithBadAuthFails() {
        let expect = expectation(description: "New post with bad auth failure")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl, filename: XMLRPCTestableConstants.xmlRpcBadAuthFailureFilename, contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.postID = postID
                post.title = postTitle
                post.content = postContent
                return post
            }()

            remoteInstance.createPost(remotePost, success: { post in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }) { error in
                guard let error = error as NSError? else {
                    XCTFail("The returned error could not be cast as NSError")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(error.domain, WPXMLRPCFaultErrorDomain, "The error domain should be WPXMLRPCFaultErrorDomain")
                XCTAssertEqual(error.code, XMLRPCTestableConstants.xmlRpcForbiddenErrorCode, "The error code should be 403")
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Update Post Tests

    func testUpdatePostSucceeds() {
        let expect = expectation(description: "Update post success")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl,
                           filename: updatePostSuccessMockFilename,
                           contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.postID = postID
                post.title = postTitle
                post.content = postContent
                return post
            }()

            remoteInstance.update(remotePost, success: { post in
                XCTAssertEqual(post?.postID, remotePost.postID, "The post ids should be equal")
                XCTAssertEqual(post?.title, remotePost.title, "The post titles should be equal")
                XCTAssertEqual(post?.content, remotePost.content, "The posts' content should be equal")
                expect.fulfill()
            }) { error in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdatePostWithModifiedTypeFails() {
        let expect = expectation(description: "Update post with modified post type failure")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl, filename: updatePostChangeTypeFailureFilename, contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.postID = postID
                post.title = postTitle
                post.content = postContent
                post.type = "something-else"
                return post
            }()

            remoteInstance.update(remotePost, success: { post in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }) { error in
                guard let error = error as NSError? else {
                    XCTFail("The returned error could not be cast as NSError")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(error.domain, WPXMLRPCFaultErrorDomain, "The error domain should be WPXMLRPCFaultErrorDomain")
                XCTAssertEqual(error.code, XMLRPCTestableConstants.xmlRpcUnauthorizedErrorCode, "The error code should be 401")
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdatePostWithInvalidPostTypeFails() {
        let expect = expectation(description: "Update post with invalid format failure")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl,
                           filename: updatePostBadFormatMockFilename,
                           contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.postID = postID
                post.title = postTitle
                post.content = postContent
                post.format = "bad-format"
                return post
            }()

            remoteInstance.update(remotePost, success: { post in
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

    func testUpdatePostWithMalformedResponseXMLFails() {
        let expect = expectation(description: "Update post with invalid XML response failure")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl, filename: updatePostBadResponseXMLMockFilename, contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.postID = postID
                post.title = postTitle
                post.content = postContent
                return post
            }()

            remoteInstance.update(remotePost, success: { post in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }) { error in
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdatePostWithBadAuthFails() {
        let expect = expectation(description: "Update post with bad auth failure")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl, filename: XMLRPCTestableConstants.xmlRpcBadAuthFailureFilename, contentType: .XML)

        if let remoteInstance = remote as? PostServiceRemote {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.postID = postID
                post.title = postTitle
                post.content = postContent
                return post
            }()

            remoteInstance.update(remotePost, success: { post in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }) { error in
                guard let error = error as NSError? else {
                    XCTFail("The returned error could not be cast as NSError")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(error.domain, WPXMLRPCFaultErrorDomain, "The error domain should be WPXMLRPCFaultErrorDomain")
                XCTAssertEqual(error.code, XMLRPCTestableConstants.xmlRpcForbiddenErrorCode, "The error code should be 403")
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
