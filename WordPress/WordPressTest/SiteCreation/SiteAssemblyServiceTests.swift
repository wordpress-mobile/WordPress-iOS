import XCTest
@testable import WordPress

class SiteAssemblyServiceTests: XCTestCase {

    private var creationRequest: SiteCreationRequest?

    override func setUp() {
        super.setUp()

        let siteCreator = SiteCreator()

        siteCreator.segment = SiteSegment(identifier: 12345,
            title: "A title",
            subtitle: "A subtitle",
            icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!,
            iconColor: "#FF0000",
            mobile: true)

        siteCreator.vertical = SiteVertical(identifier: "678910",
            title: "A title",
            isNew: true)

        siteCreator.information = SiteInformation(title: "A title", tagLine: "A tagline")

        let domainSuggestionPayload: [String: AnyObject] = [
            "domain_name": "domainName.com" as AnyObject,
            "product_id": 42 as AnyObject,
            "supports_privacy": true as AnyObject,
            ]
        siteCreator.address = try! DomainSuggestion(json: domainSuggestionPayload)

        creationRequest = try! siteCreator.build()
    }

    func testSiteAssemblyService_InitialStatus_IsIdle() {
        let service: SiteAssemblyService = MockSiteAssemblyService()

        let actualStatus = service.currentStatus

        let expectedStatus: SiteAssemblyStatus = .idle
        XCTAssertEqual(actualStatus, expectedStatus)
    }

    func testSiteAssemblyService_StatusInflight_IsInProgress() {
        let service: SiteAssemblyService = MockSiteAssemblyService()

        XCTAssertNotNil(creationRequest)
        service.createSite(creationRequest: creationRequest!, changeHandler: nil)
        let actualStatus = service.currentStatus

        let expectedStatus: SiteAssemblyStatus = .inProgress
        XCTAssertEqual(actualStatus, expectedStatus)
    }

    func testSiteAssemblyService_StatusPostRequest_WhenMockingHappyPath_IsSuccess_() {
        let inProgressExpectation = expectation(description: "Site assembly service invocation should first transition to in progress.")
        let successExpectation = expectation(description: "Site assembly service invocation should transition to success.")

        let service: SiteAssemblyService = MockSiteAssemblyService()

        XCTAssertNotNil(creationRequest)
        service.createSite(creationRequest: creationRequest!) { status in
            switch status {
            case .inProgress:
                inProgressExpectation.fulfill()
            case .succeeded:
                successExpectation.fulfill()
            default:
                break
            }
        }

        wait(for: [inProgressExpectation, successExpectation], timeout: 3, enforceOrder: true)
    }

    func testSiteAssemblyService_StatusPostRequest__WhenMockingError_IsFailure() {
        let inProgressExpectation = expectation(description: "Site assembly service invocation should first transition to in progress.")
        let failureExpectation = expectation(description: "Site assembly service invocation should transition to failed.")

        let service: SiteAssemblyService = MockSiteAssemblyService(shouldSucceed: false)

        XCTAssertNotNil(creationRequest)
        service.createSite(creationRequest: creationRequest!) { status in
            if status == .inProgress {
                inProgressExpectation.fulfill()
            }

            if status == .failed {
                failureExpectation.fulfill()
            }
        }

        wait(for: [inProgressExpectation, failureExpectation], timeout: 3, enforceOrder: true)
    }
}
