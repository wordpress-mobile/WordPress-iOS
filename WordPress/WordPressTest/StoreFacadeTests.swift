import XCTest
import Nimble
@testable import WordPress

class StoreFacadeTests: XCTestCase {
    func testGetPricesForPlans() {
        let store = MockStoreFacade.succeeding(after: 0)
        store.getPricesForPlans([.Free, .Premium, .Business],
            success: { prices in
                expect(prices.count).to(equal(3))
                expect(prices[0] as String).to(equal(""))
                expect(prices[1] as String).to(equal("$99.88"))
                expect(prices[2] as String).to(equal("$299.88"))
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
            success: { prices in
                expect(prices.count).to(equal(3))
                expect(prices[0] as String).to(equal(""))
                expect(prices[1] as String).to(equal("99,88 €"))
                expect(prices[2] as String).to(equal("299,88 €"))
            },
            failure: { error in
                XCTFail()
            }
        )
    }
}
