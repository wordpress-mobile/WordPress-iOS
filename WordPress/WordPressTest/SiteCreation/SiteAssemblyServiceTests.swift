import XCTest
@testable import WordPress

class SiteAssemblyServiceTests: XCTestCase {

    private var pendingSiteInput: SiteCreatorOutput?

    override func setUp() {
        super.setUp()

        let defaultInput = SiteCreator()

        defaultInput.segment = SiteSegment(identifier: Identifier(value: "12345"), // NB: complete type-switch via #10670
            title: "A title",
            subtitle: "A subtitle",
            icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!,
            iconColor: .red)

        defaultInput.vertical = SiteVertical(identifier: Identifier(value: "678910"), // NB: complete type-switch via #10670,
            title: "A title",
            isNew: true)

        defaultInput.information = SiteInformation(title: "A title", tagLine: "A tagline")

        let domainSuggestionPayload: [String: AnyObject] = [
            "domain_name": "domainName.com" as AnyObject,
            "product_id": 42 as AnyObject,
            "supports_privacy": true as AnyObject,
            ]
        defaultInput.address = try! DomainSuggestion(json: domainSuggestionPayload)

        pendingSiteInput = try! defaultInput.build()
    }

    func testSiteAssemblyService_InitialStatus_IsIdle() {
        let service: SiteAssemblyService = MockSiteAssemblyService()

        let actualStatus = service.currentStatus

        let expectedStatus: SiteAssemblyStatus = .idle
        XCTAssertEqual(actualStatus, expectedStatus)
    }

    func testSiteAssemblyService_StatusInflight_IsInProgress() {
        let service: SiteAssemblyService = MockSiteAssemblyService()

        XCTAssertNotNil(pendingSiteInput)
        let output = pendingSiteInput!
        service.createSite(creatorOutput: output, changeHandler: nil)
        let actualStatus = service.currentStatus

        let expectedStatus: SiteAssemblyStatus = .inProgress
        XCTAssertEqual(actualStatus, expectedStatus)
    }

    func testSiteAssemblyService_StatusPostRequest_WhenMockingHappyPath_IsSuccess_() {
        let inProgressExpectation = expectation(description: "Site assembly service invocation should first transition to in progress.")
        let successExpectation = expectation(description: "Site assembly service invocation should transition to success.")

        let service: SiteAssemblyService = MockSiteAssemblyService()

        XCTAssertNotNil(pendingSiteInput)
        let output = pendingSiteInput!
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

    func testSiteAssemblyService_StatusPostRequest__WhenMockingError_IsFailure() {
        let inProgressExpectation = expectation(description: "Site assembly service invocation should first transition to in progress.")
        let failureExpectation = expectation(description: "Site assembly service invocation should transition to failed.")

        let service: SiteAssemblyService = MockSiteAssemblyService(shouldSucceed: false)

        XCTAssertNotNil(pendingSiteInput)
        let output = pendingSiteInput!
        service.createSite(creatorOutput: output) { status in
            if status == .inProgress {
                inProgressExpectation.fulfill()
            }

            if .failed == status {
                failureExpectation.fulfill()
            }
        }

        wait(for: [inProgressExpectation, failureExpectation], timeout: 10, enforceOrder: true)
    }
}
