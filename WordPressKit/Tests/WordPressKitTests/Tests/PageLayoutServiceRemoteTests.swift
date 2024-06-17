import XCTest
@testable import WordPressKit

class PageLayoutServiceRemoteTests: RemoteTestCase, RESTTestable {
    let blogID: Int = 1234
    let successMockFilename = "page-layout-blog-layouts-success.json"
    let malformedMockFilename = "page-layout-blog-layouts-malformed.json"
    let blogSpecificEndPoint = "wpcom/v2/sites/1234/block-layouts"
    let commonLayoutsEndPoint = "wpcom/v2/common-block-layouts"

    var restAPI: WordPressComRestApi!

    // MARK: - Overridden Methods
    override func setUp() {
        super.setUp()
        restAPI = getRestApi()
    }

    override func tearDown() {
        super.tearDown()
        restAPI = nil
    }

    // MARK: - Success Tests
    func testFetchBlogSpecificLayouts() {
        let expect = expectation(description: "Fetch blog specific site layouts")
        stubRemoteResponse(blogSpecificEndPoint, filename: successMockFilename, contentType: .ApplicationJSON)
        PageLayoutServiceRemote.fetchLayouts(restAPI, forBlogID: blogID, withParameters: nil) { (result) in
            switch result {
            case .success(let layouts):
                XCTAssertNotNil(layouts.categories)
                XCTAssertNotNil(layouts.layouts)
                expect.fulfill()
            case .failure:
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testFetchCommonLayouts() {
        let expect = expectation(description: "Fetch blog specific site layouts")
        stubRemoteResponse(commonLayoutsEndPoint, filename: successMockFilename, contentType: .ApplicationJSON)
        PageLayoutServiceRemote.fetchLayouts(restAPI, forBlogID: nil, withParameters: nil) { (result) in
            switch result {
            case .success(let layouts):
                XCTAssertNotNil(layouts.categories)
                XCTAssertNotNil(layouts.layouts)
                expect.fulfill()
            case .failure:
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Malformed Data Tests
    func testMalformedData() {
        let expect = expectation(description: "Fetch blog specific site layouts")
        stubRemoteResponse(blogSpecificEndPoint, filename: malformedMockFilename, contentType: .ApplicationJSON)
        PageLayoutServiceRemote.fetchLayouts(restAPI, forBlogID: blogID, withParameters: nil) { (result) in
            switch result {
            case .success:
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            case .failure(let error):
                XCTAssertNotNil(error)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }
}
