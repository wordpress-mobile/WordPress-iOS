import XCTest
import Nimble

@testable import WordPress

class ExPlatTests: XCTestCase {
    // Save the returned experiments variation
    //
    func testRefresh() {
        let abTesting = ExPlat(service: ExPlatServiceMock())

        abTesting.refresh()

        expect(abTesting.experiment("experiment")).toEventually(equal("control"))
        expect(abTesting.experiment("another_experiment")).toEventually(equal("treatment"))
    }
}

private class ExPlatServiceMock: ExPlatService {
    init() {
        super.init(wordPressComRestApi: WordPressComMockRestApi())
    }

    override func getAssignments(completion: @escaping (Assignments?) -> Void) {
        completion(
            Assignments(
                ttl: 60,
                variations: [
                    "experiment": "control",
                    "another_experiment": "treatment"
                ]
            )
        )
    }
}
