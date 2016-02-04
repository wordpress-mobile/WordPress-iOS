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

    func testPlanListRowTitleWhenCurrent() {
        let row = PlanListRow(title: "Title", active: true, price: "$99", description: "description", icon: testImage)

        let attributedTitle = row.attributedTitle
        expect(attributedTitle.string).to(equal("Title CURRENT PLAN"))
    }

    func testPlanListRowTitleWhenNotCurrent() {
        let row = PlanListRow(title: "Title", active: false, price: "$99", description: "description", icon: testImage)

        let attributedTitle = row.attributedTitle
        expect(attributedTitle.string).to(equal("Title $99 per year"))
    }

    // MARK: - PlanListViewModel tests

    func testPlanListViewModel() {
        let model = PlanListViewModel(activePlan: .Free)
        expect(model.activePlan).to(equal(Plan.Free))
        expect(model.tableViewModel.sections.count).to(equal(1))
        let section = model.tableViewModel.sections[0]
        expect(section.rows.count).to(equal(3))
    }

    func testPlanImageWhenActivePlanSet() {
        let model = PlanListViewModel(activePlan: Plan.Premium)
        let freeRow = model.tableViewModel.planRowAtIndex(0)
        let premiumRow = model.tableViewModel.planRowAtIndex(1)
        let businessRow = model.tableViewModel.planRowAtIndex(2)

        expect(freeRow.icon).to(equal(Plan.Free.image))
        expect(premiumRow.icon).to(equal(Plan.Premium.activeImage))
        expect(businessRow.icon).to(equal(Plan.Business.image))
    }

    func testPlanImageWhenActivePlanNotSet() {
        let model = PlanListViewModel(activePlan: nil)
        let freeRow = model.tableViewModel.planRowAtIndex(0)
        let premiumRow = model.tableViewModel.planRowAtIndex(1)
        let businessRow = model.tableViewModel.planRowAtIndex(2)

        expect(freeRow.icon).to(equal(Plan.Free.image))
        expect(premiumRow.icon).to(equal(Plan.Premium.image))
        expect(businessRow.icon).to(equal(Plan.Business.image))
    }

    let testImage = Plan.Free.image

}

extension ImmuTable {
    private func planRowAtIndex(index: Int) -> PlanListRow {
        return rowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as! PlanListRow
    }
}
