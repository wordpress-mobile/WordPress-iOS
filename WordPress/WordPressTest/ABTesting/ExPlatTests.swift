import XCTest
import Nimble

@testable import WordPress

class ExPlatTests: XCTestCase {
    // Save the returned assignments
    //
    func testRefresh() {
        let abTesting = ExPlat(service: ExPlatServiceMock.withDefaultApi())

        abTesting.refresh()

        expect(abTesting.experiment("experiment")).to(equal("control"))
    }
}

private class ExPlatServiceMock: ExPlatService {
    override func getAssignments(completion: @escaping (Assignments?) -> Void) {
        completion(Assignments.init(ttl: 60, variations: ["experiment": "control"]))
    }
}
