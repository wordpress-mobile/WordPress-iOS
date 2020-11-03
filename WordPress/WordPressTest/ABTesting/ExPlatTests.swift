import XCTest
import OHHTTPStubs
import Nimble

@testable import WordPress

class ExPlatTests: XCTestCase {
    override func setUp() {
        super.setUp()
        stubDomainsResponseWithFile("explat-assignments.json")
    }

    override func tearDown() {
        super.tearDown()

        OHHTTPStubs.removeAllStubs()
    }

    func testRefresh() {
        let abTesting = ExPlat.withDefaultApi()

        abTesting.refresh()

        expect(UserDefaults.standard.object(forKey: "explat") as? [String: String?]).toEventually(equal(["experiment": "control"]))
    }

    private func stubDomainsResponseWithFile(_ filename: String) {
        stub(condition: { request in
            return (request.url!.absoluteString as NSString).contains("wpcom/v2/experiments/0.1.0/assignments/calypso") && request.httpMethod! == "GET"
        }) { _ in
            let stubPath = OHPathForFile(filename, type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
    }
}
