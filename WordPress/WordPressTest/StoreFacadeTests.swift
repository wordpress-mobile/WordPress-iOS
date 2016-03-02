import XCTest
import Nimble
@testable import WordPress

class StoreFacadeTests: XCTestCase {
    func testGetPricesForPlans() {
        let store = MockStoreFacade.succeeding(after: 0)
        store.getPricesForPlans([.Free, .Premium, .Business],
            success: { pricedPlans in
                expect(pricedPlans.count).to(equal(3))
                expect(pricedPlans[0].price as String).to(equal(""))
                expect(pricedPlans[0].plan).to(equal(Plan.Free))
                expect(pricedPlans[1].price as String).to(equal("$99.88"))
                expect(pricedPlans[1].plan).to(equal(Plan.Premium))
                expect(pricedPlans[2].price as String).to(equal("$299.88"))
                expect(pricedPlans[2].plan).to(equal(Plan.Business))
            }, failure: { _ in
                XCTFail()
        })
    }

    func testGetPricesLocalization() {
        let store = MockStoreFacade.succeeding(after: 0)
        store.products[0].priceLocale = NSLocale(localeIdentifier: "es-ES")
        store.products[1].priceLocale = NSLocale(localeIdentifier: "es-ES")
        store.getPricesForPlans(
            [.Free, .Premium, .Business],
            success: { pricedPlans in
                expect(pricedPlans.count).to(equal(3))
                expect(pricedPlans[0].price as String).to(equal(""))
                expect(pricedPlans[1].price as String).to(equal("99,88 €"))
                expect(pricedPlans[2].price as String).to(equal("299,88 €"))
            },
            failure: { error in
                XCTFail()
            }
        )
    }
}
