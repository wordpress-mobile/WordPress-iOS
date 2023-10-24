import XCTest
@testable import WordPress

final class PlanWizardContentViewModelTests: XCTestCase {
    private var sut: PlanWizardContentViewModel!
    private var siteCreator: SiteCreator!

    override func setUpWithError() throws {
        try super.setUpWithError()
        siteCreator = SiteCreator()
        sut = PlanWizardContentViewModel(siteCreator: siteCreator)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        siteCreator = nil
        sut = nil
    }

    // MARK: - isPlanSelected

    func testIsPlanSelectedWithPlanSlugParameters() {
        var components = URLComponents(string: PlanWizardContentViewModel.Constants.plansWebAddress)!
        components.queryItems = [.init(name: PlanWizardContentViewModel.Constants.OutputParameter.planSlug, value: "free_plan")]

        XCTAssertTrue(sut.isPlanSelected(components.url!))
    }

    func testIsPlanSelectedWithPlanSlugAndPlanIdParameters() {
        var components = URLComponents(string: PlanWizardContentViewModel.Constants.plansWebAddress)!
        components.queryItems = [
            .init(name: PlanWizardContentViewModel.Constants.OutputParameter.planSlug, value: "paid_plan"),
            .init(name: PlanWizardContentViewModel.Constants.OutputParameter.planId, value: "1009")
        ]

        XCTAssertTrue(sut.isPlanSelected(components.url!))
    }

    func testPlanNotSelectedWithoutPlanSlug() {
        let url = URL(string: PlanWizardContentViewModel.Constants.plansWebAddress)!

        XCTAssertFalse(sut.isPlanSelected(url))
    }

    // MARK: - selectedPlanId

    func testSelectedPlanId() {
        var components = URLComponents(string: PlanWizardContentViewModel.Constants.plansWebAddress)!
        components.queryItems = [.init(name: PlanWizardContentViewModel.Constants.OutputParameter.planId, value: "125")]

        XCTAssertEqual(sut.selectedPlanId(from: components.url!), 125)
    }

    func testSelectedPlanIdWithMoreParameters() {
        var components = URLComponents(string: PlanWizardContentViewModel.Constants.plansWebAddress)!
        components.queryItems = [
            .init(name: "parameter", value: "5"),
            .init(name: PlanWizardContentViewModel.Constants.OutputParameter.planId, value: "125"),
            .init(name: "parameter2", value: "abc")
        ]

        XCTAssertEqual(sut.selectedPlanId(from: components.url!), 125)
    }

    // MARK: - URL

    func testURLWithPaidDomain() {
        let domainName = "domain.com"
        siteCreator.address = DomainSuggestion(domainName: domainName, productID: 101, supportsPrivacy: false, costString: "$20", isFree: false)

        let url = URLComponents(url: sut.url, resolvingAgainstBaseURL: true)

        let parameter = url?.queryItems?.first(where: { $0.name == PlanWizardContentViewModel.Constants.InputParameter.paidDomainName })
        XCTAssertEqual(parameter?.value, domainName)
    }

    func testURLWithFreeDomain() {
        let domainName = "domain.wordpress.com"
        siteCreator.address = DomainSuggestion(domainName: domainName, productID: 101, supportsPrivacy: false, costString: "$0", isFree: true)

        let url = URLComponents(url: sut.url, resolvingAgainstBaseURL: true)

        let parameter = url?.queryItems?.first(where: { $0.name == PlanWizardContentViewModel.Constants.InputParameter.paidDomainName })
        XCTAssertEqual(parameter, nil)
    }
}
