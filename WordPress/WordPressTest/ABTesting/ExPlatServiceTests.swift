import XCTest
import OHHTTPStubs

@testable import WordPress

class ExPlatServiceTests: XCTestCase {
    override func tearDown() {
        super.tearDown()

        OHHTTPStubs.removeAllStubs()
    }

    // Return TTL and variations
    //
    func testRefresh() {
        let expectation = XCTestExpectation(description: "Return assignments")
        stubAssignmentsResponseWithFile("explat-assignments.json")
        let service = ExPlatService.withDefaultApi()

        service.getAssignments { assignments in
            XCTAssertEqual(assignments?.ttl, 60)
            XCTAssertEqual(assignments?.variations, ["experiment": "control"])
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // Do not return assignments when the decoding fails
    //
    func testRefreshDecodeFails() {
        let expectation = XCTestExpectation(description: "Do not return assignments")
        stubAssignmentsResponseWithFile("explat-malformed-assignments.json")
        let service = ExPlatService.withDefaultApi()

        service.getAssignments { assignments in
            XCTAssertNil(assignments)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // Do not return assignments when the server returns an error
    //
    func testRefreshServerFails() {
        let expectation = XCTestExpectation(description: "Do not return assignments")
        stubAssignmentsResponseWithError()
        let service = ExPlatService.withDefaultApi()

        service.getAssignments { assignments in
            XCTAssertNil(assignments)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    private func stubAssignmentsResponseWithFile(_ filename: String) {
        stubAssignments(withFile: filename)
    }

    private func stubAssignmentsResponseWithError() {
        stubAssignments(withStatus: 503)
    }

    private func stubAssignments(withFile file: String = "explat-assignments.json", withStatus status: Int32? = nil) {
        let endpoint = "wpcom/v2/experiments/0.1.0/assignments/calypso"
        stub(condition: { request in
            return (request.url!.absoluteString as NSString).contains(endpoint) && request.httpMethod! == "GET"
        }) { _ in
            let stubPath = OHPathForFile(file, type(of: self))
            return fixture(filePath: stubPath!, status: status ?? 200, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
    }
}
