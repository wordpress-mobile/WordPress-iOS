import XCTest
@testable import WordPress

final class PlanWizardContentViewModelTests: XCTestCase {
    private var sut: PlanWizardContentViewModel!
    private var siteCreator: SiteCreator!

    override func setUpWithError() throws {
        siteCreator = SiteCreator()
        sut = PlanWizardContentViewModel(siteCreator: siteCreator)
    }

    override func tearDownWithError() throws {
        siteCreator = nil
        sut = nil
    }

    // MARK: - isPlanSelected

    func testIsPlanSelectedWithRedirectScheme() {
        let url = URL(string: PlanWizardContentViewModel.Constants.redirectScheme + "://")!

        XCTAssertTrue(sut.isPlanSelected(url))
    }

    func testIsPlanSelectedWithRedirectSchemeAndParameters() {
        var components = URLComponents(string: PlanWizardContentViewModel.Constants.redirectScheme + "://")!
        components.queryItems = [.init(name: "parameter", value: "5")]

        XCTAssertTrue(sut.isPlanSelected(components.url!))
    }

    func testPlanNotSelectedWithoutRedirectScheme() {
        let url = URL(string: "https://www.wordpress.com/plans/")!

        XCTAssertFalse(sut.isPlanSelected(url))
    }

    // MARK: - selectedPlanId

    func testSelectedPlanId() {
        var components = URLComponents(string: PlanWizardContentViewModel.Constants.redirectScheme + "://")!
        components.queryItems = [.init(name: PlanWizardContentViewModel.Constants.planIdParameter, value: "125")]

        XCTAssertEqual(sut.selectedPlanId(from: components.url!), 125)
    }

    func testSelectedPlanIdWithMoreParameters() {
        var components = URLComponents(string: PlanWizardContentViewModel.Constants.redirectScheme + "://")!
        components.queryItems = [
            .init(name: "parameter", value: "5"),
            .init(name: PlanWizardContentViewModel.Constants.planIdParameter, value: "125"),
            .init(name: "parameter2", value: "abc")
        ]

        XCTAssertEqual(sut.selectedPlanId(from: components.url!), 125)
    }

    // MARK: - URL

    func testURLWithPaidDomain() {
        let domainName = "domain.com"
        siteCreator.address = DomainSuggestion(domainName: domainName, productID: 101, supportsPrivacy: false, costString: "$20", isFree: false)

        let url = URLComponents(url: sut.url, resolvingAgainstBaseURL: true)

        let parameter = url?.queryItems?.first(where: { $0.name == PlanWizardContentViewModel.Constants.paidDomainNameParameter })
        XCTAssertEqual(parameter?.value, domainName)
    }

    func testURLWithFreeDomain() {
        let domainName = "domain.wordpress.com"
        siteCreator.address = DomainSuggestion(domainName: domainName, productID: 101, supportsPrivacy: false, costString: "$0", isFree: true)

        let url = URLComponents(url: sut.url, resolvingAgainstBaseURL: true)

        let parameter = url?.queryItems?.first(where: { $0.name == PlanWizardContentViewModel.Constants.paidDomainNameParameter })
        XCTAssertEqual(parameter, nil)
    }
}
