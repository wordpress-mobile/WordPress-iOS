import XCTest
import OHHTTPStubs

@testable import WordPress

class ExPlatServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        stubDomainsResponseWithFile("explat-assignments.json")
    }

    override func tearDown() {
        super.tearDown()

        OHHTTPStubs.removeAllStubs()
    }

    // Return TTL and variations
    //
    func testRefresh() {
        let expectation = XCTestExpectation(description: "Return assignments")
        let service = ExPlatService.withDefaultApi()

        service.getAssignments { assignments in
            XCTAssertEqual(assignments?.ttl, 60)
            XCTAssertEqual(assignments?.variations, ["experiment": "control"])
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    private func stubDomainsResponseWithFile(_ filename: String) {
        let endpoint = "wpcom/v2/experiments/0.1.0/assignments/calypso"
        stub(condition: { request in
            return (request.url!.absoluteString as NSString).contains(endpoint) && request.httpMethod! == "GET"
        }) { _ in
            let stubPath = OHPathForFile(filename, type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
    }
}
