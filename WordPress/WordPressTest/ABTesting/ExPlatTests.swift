import XCTest

@testable import WordPress

class ExPlatTests: XCTestCase {
    // Save the returned experiments variation
    //
    func testRefresh() {
        let expectation = XCTestExpectation(description: "Save experiments")
        let abTesting = ExPlat(configuration: ExPlatTestConfiguration(), service: ExPlatServiceMock())

        abTesting.refresh {
            XCTAssertEqual(abTesting.experiment("experiment"), .control)
            XCTAssertEqual(abTesting.experiment("another_experiment"), .treatment)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // Keep the already saved experiments in case of a failure
    //
    func testError() {
        let expectation = XCTestExpectation(description: "Keep experiments")
        let serviceMock = ExPlatServiceMock()
        let abTesting = ExPlat(configuration: ExPlatTestConfiguration(), service: serviceMock)
        abTesting.refresh {

            serviceMock.returnAssignments = false
            abTesting.refresh {
                XCTAssertEqual(abTesting.experiment("experiment"), .control)
                XCTAssertEqual(abTesting.experiment("another_experiment"), .treatment)
                expectation.fulfill()
            }

        }

        wait(for: [expectation], timeout: 2.0)
    }

    // Schedule a timer to automatically refresh
    //
    func testScheduleRefresh() {
        let expectation = XCTestExpectation(description: "Automatically refresh")
        let serviceMock = ExPlatServiceMock()
        let abTesting = ExPlat(configuration: ExPlatTestConfiguration(), service: serviceMock)
        abTesting.refresh {

            DispatchQueue.main.async {
                XCTAssertTrue(abTesting.scheduledTimer!.isValid)
                XCTAssertEqual(round(abTesting.scheduledTimer!.timeInterval), 60)
                expectation.fulfill()
            }

        }

        wait(for: [expectation], timeout: 2.0)
    }
}

private class ExPlatServiceMock: ExPlatService {
    var returnAssignments = true

    init() {
        super.init(configuration: ExPlatTestConfiguration())
    }

    override func getAssignments(completion: @escaping (Assignments?) -> Void) {
        guard returnAssignments else {
            completion(nil)
            return
        }

        completion(
            Assignments(
                ttl: 60,
                variations: [
                    "experiment": "control",
                    "another_experiment": "treatment",
                    "expired_experiment": nil
                ]
            )
        )
    }
}
