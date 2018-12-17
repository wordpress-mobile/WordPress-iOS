import XCTest
@testable import WordPress

class SiteAssemblyServiceTests: XCTestCase {

    func testSiteAssemblyService_InitialStatus_IsIdle() {
        let service: SiteAssemblyService = MockSiteAssemblyService()

        let actualStatus = service.currentStatus

        let expectedStatus: SiteAssemblyStatus = .idle
        XCTAssertEqual(actualStatus, expectedStatus)
    }

    func testSiteAssemblyService_StatusInflight_IsInProgress() {
        let service: SiteAssemblyService = MockSiteAssemblyService()

        let output = SiteCreatorOutput()
        service.createSite(creatorOutput: output, changeHandler: nil)
        let actualStatus = service.currentStatus

        let expectedStatus: SiteAssemblyStatus = .inProgress
        XCTAssertEqual(actualStatus, expectedStatus)
    }

    func testSiteAssemblyService_StatusPostRequest_IsSuccess() {
        let inProgressExpectation = expectation(description: "Site assembly service invocation should first transition to in progress.")
        let successExpectation = expectation(description: "Site assembly service invocation should transition to success.")

        let service: SiteAssemblyService = MockSiteAssemblyService()

        let output = SiteCreatorOutput()
        service.createSite(creatorOutput: output) { status in
            if status == .inProgress {
                inProgressExpectation.fulfill()
            }

            if .succeeded == status {
                successExpectation.fulfill()
            }
        }

        wait(for: [inProgressExpectation, successExpectation], timeout: 10, enforceOrder: true)
    }
}
