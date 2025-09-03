import XCTest

@testable import WordPressKit

class JetpackCapabilitiesServiceRemoteTests: RemoteTestCase, RESTTestable {
    let mockRemoteApi = MockWordPressComRestApi()
    var service: JetpackCapabilitiesServiceRemote!

    override func setUp() {
        super.setUp()

        service = JetpackCapabilitiesServiceRemote(wordPressComRestApi: getRestApi())
    }

    /// Return the capabilities for the given siteIDs
    func testSuccessCapabilities() {
        let expect = expectation(description: "Get the available capabilities")
        stubRemoteResponse("wpcom/v2/sites/34197361/rewind/capabilities", filename: "jetpack-capabilities-34197361-success.json", contentType: .ApplicationJSON)
        stubRemoteResponse("wpcom/v2/sites/107159616/rewind/capabilities", filename: "jetpack-capabilities-107159616-success.json", contentType: .ApplicationJSON)

        service.for(siteIds: [34197361, 107159616], success: { capabilities in
            XCTAssertTrue(capabilities.count == 2)
            XCTAssertTrue((capabilities["34197361"] as? [String])!.isEmpty)
            XCTAssertTrue((capabilities["107159616"] as? [String])!.contains("backup"))
            XCTAssertTrue((capabilities["107159616"] as? [String])!.contains("backup-realtime"))
            XCTAssertTrue((capabilities["107159616"] as? [String])!.contains("scan"))
            XCTAssertTrue((capabilities["107159616"] as? [String])!.contains("antispam"))
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// When a single request fails, the associated capabilities are not returned
    func testSingleRequestFails() {
        let expect = expectation(description: "Get the available capabilities")
        stubRemoteResponse("wpcom/v2/sites/34197361/rewind/capabilities", filename: "jetpack-capabilities-34197361-success.json", contentType: .ApplicationJSON)
        stubRemoteResponse("wpcom/v2/sites/107159616/rewind/capabilities", filename: "jetpack-capabilities-malformed.json", contentType: .ApplicationJSON)

        service.for(siteIds: [34197361, 107159616], success: { capabilities in
            XCTAssertTrue(capabilities.count == 1)
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

}
