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

    func testPlanListViewModel() {
        let model = PlanListViewModel(activePlan: .Free)
        expect(model.activePlan).to(equal(Plan.Free))
        expect(model.tableViewModel.sections.count).to(equal(1))
        let section = model.tableViewModel.sections[0]
        expect(section.rows.count).to(equal(3))
    }

    func testPlanImageWhenActivePlanSet() {
        let model = PlanListViewModel(activePlan: .Premium)
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

    func testPlanViewModelEquatable() {
        let freeModel = PlanListViewModel(activePlan: .Free)
        let secondFreeModel = PlanListViewModel(activePlan: .Free)
        let premiumModel = PlanListViewModel(activePlan: .Premium)
        let businessModel = PlanListViewModel(activePlan: .Business)
        let nilModel = PlanListViewModel(activePlan: nil)

        expect(freeModel).to(equal(secondFreeModel))

        // Let's test all the combinations, for science!
        expect(freeModel).toNot(equal(premiumModel))
        expect(freeModel).toNot(equal(businessModel))
        expect(freeModel).toNot(equal(nilModel))
        expect(premiumModel).toNot(equal(freeModel))
        expect(premiumModel).toNot(equal(businessModel))
        expect(premiumModel).toNot(equal(nilModel))
        expect(businessModel).toNot(equal(freeModel))
        expect(businessModel).toNot(equal(premiumModel))
        expect(businessModel).toNot(equal(nilModel))
        expect(nilModel).toNot(equal(freeModel))
        expect(nilModel).toNot(equal(premiumModel))
        expect(nilModel).toNot(equal(businessModel))
    }

    func testPlanViewModelEncodingWithActivePlanSet() {
        let model = PlanListViewModel(activePlan: .Business)
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWithMutableData: data)
        model.encodeWithCoder(coder)
        coder.finishEncoding()

        let decoder = NSKeyedUnarchiver(forReadingWithData: data)
        let decodedModel = PlanListViewModel(coder: decoder)
        expect(decodedModel).to(equal(model))
    }

    func testPlanViewModelEncodingWithActivePlanNotSet() {
        let model = PlanListViewModel(activePlan: nil)
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWithMutableData: data)
        model.encodeWithCoder(coder)
        coder.finishEncoding()

        let decoder = NSKeyedUnarchiver(forReadingWithData: data)
        let decodedModel = PlanListViewModel(coder: decoder)
        expect(decodedModel).to(equal(model))
    }

    let testImage = Plan.Free.image

}

extension ImmuTable {
    private func planRowAtIndex(index: Int) -> PlanListRow {
        return rowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as! PlanListRow
    }
}
