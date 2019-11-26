import XCTest
import OHHTTPStubs
import Nimble

@testable import WordPress

class TenorClientTests: XCTestCase {
    let client = TenorClient(tenorAppId: "dummyId")
    let endpoint = TenorClient.endpoint

    func testWithCorrectResponse() {
        let stubPath = OHPathForFile("tenor.json", type(of: self))!
        OHHTTPStubs.stubRequest(forEndpoint: endpoint, withFileAtPath: stubPath)

        let waitExpectation = expectation(description: "Waiting for mock service")

        let errorMessage = "Correct response format should be converted to a valid response object"

        client.search("test", pos: 0, limit: 10) { (result) in
            switch result {
            case .success(let response):
                XCTAssertTrue(response.results.count > 0, errorMessage)
            case .failure:
                XCTFail(errorMessage)
            }
            waitExpectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testWithIncorrectResponse() {
        OHHTTPStubs.stubRequest(for: endpoint, jsonObject: ["dummy": "object"] as [String: Any])

        let waitExpectation = expectation(description: "Waiting for mock service")

        client.search("test", pos: 0, limit: 10) { (result) in
            switch result {
            case .success:
                 XCTFail("Incorrect response format shouldn't be converted to a response object")
            case .failure(let error):
                expect(error).to(matchError(TenorError.wrongDataFormat), description: "Incorrect response format should cause a wrongDataFormat error")
            }
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testWithNetworkErrorResponse() {
        let notConnectedError = NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue)
        let stubResponse = OHHTTPStubsResponse(error: notConnectedError)

        OHHTTPStubs.stubRequest(for: endpoint, stubResponse: stubResponse)

        let waitExpectation = expectation(description: "Waiting for mock service")

        client.search("test", pos: 0, limit: 10) { (result) in
            switch result {
            case .success:
                 XCTFail("Network problems should prevent returning a response object")
            case .failure(let error):
                XCTAssertEqual(notConnectedError.code, (error as NSError).code, "Network problems should return the correct error object")
            }
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
    }
}
