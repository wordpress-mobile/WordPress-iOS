import XCTest
import Nimble
@testable import WordPress

class PlanListViewControllerTest: XCTestCase {

    // MARK: - PlanListRow tests

    func testPlanListRowAttributedTitleWhenCurrentDoesNotContainPrice() {
        let (title, price) = ("Title", "$99")
        let attributedTitle = PlanListRow.Formatter.attributedTitle(title, price: price, active: true)

        expect(attributedTitle.string).to(contain(title))
        expect(attributedTitle.string).notTo(contain(price))
    }

    func testPlanListRowAttributedTitleWhenNotCurrentContainsTitleAndPrice() {
        let (title, price) = ("Title", "$99")
        let attributedTitle = PlanListRow.Formatter.attributedTitle(title, price: price, active: false)

        expect(attributedTitle.string).to(contain(title))
        expect(attributedTitle.string).to(contain(price))
    }

    // MARK: - PlanListViewModel tests

    func testPlanImageWhenActivePlanSet() {
        let model = PlanListViewModel.Ready((siteID: 123, activePlan: TestPlans.premium.plan, availablePlans: plansWithPrices))
        let tableViewModel = model.tableViewModelWithPresenter(nil, planService: nil)
        let freeRow = tableViewModel.planRowAtIndex(0)
        let premiumRow = tableViewModel.planRowAtIndex(1)
        let businessRow = tableViewModel.planRowAtIndex(2)

        expect(freeRow.iconUrl).to(equal(TestPlans.free.plan.iconUrl))
        expect(premiumRow.iconUrl).to(equal(TestPlans.premium.plan.activeIconUrl))
        expect(businessRow.iconUrl).to(equal(TestPlans.business.plan.iconUrl))
    }

    let plansWithPrices: [PricedPlan] = [
        (TestPlans.free.plan, ""),
        (TestPlans.premium.plan, "$99.99"),
        (TestPlans.business.plan, "$299.99")
    ]
}

extension ImmuTable {
    private func planRowAtIndex(index: Int) -> PlanListRow {
        return rowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as! PlanListRow
    }
}
