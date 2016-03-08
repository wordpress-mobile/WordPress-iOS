import XCTest
import Nimble
@testable import WordPress

class PlanListViewControllerTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: - PlanListRow tests

    func testPlanListRowAttributedTitleWhenCurrent() {
        let attributedTitle = PlanListRow.Formatter.attributedTitle("Title", price: "$99", active: true)
        expect(attributedTitle.string).to(equal("Title CURRENT PLAN"))
    }

    func testPlanListRowAttributedTitleWhenNotCurrent() {
        let attributedTitle = PlanListRow.Formatter.attributedTitle("Title", price: "$99", active: false)
        expect(attributedTitle.string).to(equal("Title $99 per year"))
    }

    // MARK: - PlanListViewModel tests

    func testPlanImageWhenActivePlanSet() {
        let model = PlanListViewModel.Ready(activePlan: .Premium, plans: plansWithPrices)
        let presenter = MockImmuTablePresenter()
        let tableViewModel = model.tableViewModelWithPresenter(presenter)
        let freeRow = tableViewModel.planRowAtIndex(0)
        let premiumRow = tableViewModel.planRowAtIndex(1)
        let businessRow = tableViewModel.planRowAtIndex(2)

        expect(freeRow.icon).to(equal(Plan.Free.image))
        expect(premiumRow.icon).to(equal(Plan.Premium.activeImage))
        expect(businessRow.icon).to(equal(Plan.Business.image))
    }

    let plansWithPrices: [(Plan, String)] = [
        (.Free, ""),
        (.Premium, "$99.99"),
        (.Business, "$299.99")
    ]
}

extension ImmuTable {
    private func planRowAtIndex(index: Int) -> PlanListRow {
        return rowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as! PlanListRow
    }
}
