import XCTest
@testable import WordPress

class SiteAssemblyServiceTests: XCTestCase {

    // MARK: SiteAssemblyService
    
    func testInitialStatus_SiteAssemblyService_IsIdle() {
        let service: SiteAssemblyService = EnhancedSiteCreationService()

        let actualStatus = service.currentStatus

        let expectedStatus: SiteAssemblyStatus = .idle
        XCTAssertEqual(actualStatus, expectedStatus)
    }

    // MARK: SiteAssemblyStatus

    func testSiteAssemblyStatus_InProgressDescription_IsLocalized() {
        let status: SiteAssemblyStatus = .inProgress

        let actualStatusDescription = status.description

        let expectedStatusDescription = NSLocalizedString("We’re creating your new site.", comment: "")
        XCTAssertEqual(actualStatusDescription, expectedStatusDescription)
    }
}
