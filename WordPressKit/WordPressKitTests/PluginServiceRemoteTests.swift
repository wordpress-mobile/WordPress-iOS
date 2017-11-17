import Foundation
import XCTest
import WordPressKit

class PluginServiceRemoteTests: RemoteTestCase, RESTTestable {
    let siteID = 123
    let getPluginsSuccessMockFilename = "site-plugins-success.json"
    let getPluginsErrorMockFilename = "site-plugins-error.json"
    var sitePluginsEndpoint: String {
        return "sites/\(siteID)/plugins"
    }

    var remote: PluginServiceRemote!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = PluginServiceRemote(wordPressComRestApi: getRestApi())
    }

    override func tearDown() {
        super.tearDown()

        remote = nil
    }

    // MARK: - Plugin Tests

    func testGetSitePluginsSucceeds() {
        let expect = expectation(description: "Get site plugins success")

        stubRemoteResponse(sitePluginsEndpoint,
                           filename: getPluginsSuccessMockFilename,
                           contentType: .ApplicationJSON)
        remote.getPlugins(siteID: siteID, success: { (sitePlugins) in
            XCTAssertEqual(sitePlugins.plugins.count, 5)
            XCTAssertTrue(sitePlugins.capabilities.autoupdate)
            XCTAssertTrue(sitePlugins.capabilities.modify)
            expect.fulfill()
        }, failure: { (error) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetSitePluginFails() {
        let expect = expectation(description: "Get site plugins fails")

        stubRemoteResponse(sitePluginsEndpoint,
                           filename: getPluginsErrorMockFilename,
                           contentType: .ApplicationJSON)
        remote.getPlugins(siteID: siteID, success: { (_)  in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { (error) in
            let error = error as NSError
            let expected = PluginServiceRemote.ResponseError.unauthorized as NSError
            XCTAssertEqual(error, expected)
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
