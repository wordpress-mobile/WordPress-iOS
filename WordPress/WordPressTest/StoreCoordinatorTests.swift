import Foundation
import Nimble
@testable import WordPress

class StoreCoordinatorTests: XCTestCase {

    func testPurchaseUnavailableWithPaymentDisabled() {
        let availability = availabilityWith(business, active: free, paymentsEnabled: false, pendingState: .none)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseUnavailableForDowngrade() {
        let availability = availabilityWith(premium, active: business, paymentsEnabled: true, pendingState: .none)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseUnavailableForUpgrade() {
        let availability = availabilityWith(business, active: premium, paymentsEnabled: true, pendingState: .none)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseUnavailableForFreePlan() {
        // This test doesn't make much sense now as we don't allow any downgrades right now
        // When we support that however, we still shouldn't allow "purchasing" a Free plan
        let availability = availabilityWith(free, active: premium, paymentsEnabled: true, pendingState: .none)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseUnavailableForActivePlan() {
        let availability = availabilityWith(premium, active: premium, paymentsEnabled: true, pendingState: .none)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchasePendingForSameSitePlan() {
        let availability = availabilityWith(premium, active: free, paymentsEnabled: true, pendingState: .sameSitePlan)
        XCTAssertEqual(availability, PurchaseAvailability.pending)
    }

    func testPurchaseUnavailableForSameSite() {
        let availability = availabilityWith(premium, active: free, paymentsEnabled: true, pendingState: .sameSite)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseUnavailableForSamePlan() {
        let availability = availabilityWith(premium, active: free, paymentsEnabled: true, pendingState: .samePlan)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseUnavailableForDifferentSitePlan() {
        let availability = availabilityWith(premium, active: free, paymentsEnabled: true, pendingState: .differentSitePlan)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseAvailableOtherwise() {
        let availability = availabilityWith(premium, active: free, paymentsEnabled: true, pendingState: .none)
        XCTAssertEqual(availability, PurchaseAvailability.available)
    }

    func testCannotPurchaseWhenPurchaseAlreadyPending() {
        let payment: PendingPayment = (testProduct, testSite)
        let coordinator = storeCoordinator(true, pending: payment)
        let product = TestPlans.business.product

        // And now attempt a second purchase
        XCTAssertThrowsError(try coordinator.purchaseProduct(product, forSite: testSite))
    }

    func testCanMakePaymentWhenNoPaymentIsPending() {
        let coordinator = storeCoordinator(true, pending: nil)
        let product = TestPlans.business.product

        do {
            try coordinator.purchaseProduct(product, forSite: otherSite)
        } catch {
            XCTFail("Expected call not to throw")
        }
    }

    // ========================= END OF TESTS =============================== //


    // MARK: - Helpers

    fileprivate func availabilityWith(_ plan: Plan, active: Plan, paymentsEnabled: Bool, pendingState: PendingState) -> PurchaseAvailability {
        let pendingPayment = pending(plan, productID: testProduct, siteID: testSite, state: pendingState)
        let coordinator = storeCoordinator(paymentsEnabled, pending: pendingPayment)
        return coordinator.purchaseAvailability(forPlan: plan, siteID: testSite, activePlan: active)
    }

    fileprivate func storeCoordinator(_ paymentsEnabled: Bool, pending: PendingPayment?) -> StoreCoordinator<MockStore> {
        var store = MockStore.succeeding()
        store.canMakePayments = paymentsEnabled

        let coordinator = StoreCoordinator(store: store, database: EphemeralKeyValueDatabase())

        if let pending = pending,
            let product = TestPlans.allProducts.filter({ $0.productIdentifier == pending.productID }).first {
            try! coordinator.purchaseProduct(product, forSite: pending.siteID)
        }

        return coordinator
    }

    fileprivate func pending(_ plan: Plan, productID: String, siteID: Int, state: PendingState) -> PendingPayment? {
        switch state {
        case .none: return nil
        case .sameSitePlan: return (productID, siteID)
        case .sameSite: return (otherPlan(plan).productIdentifier!, siteID)
        case .samePlan: return (productID, otherSite)
        case .differentSitePlan: return (otherPlan(plan).productIdentifier!, otherSite)
        }
    }

    fileprivate func otherPlan(_ plan: Plan) -> Plan {
        if plan == business {
            return premium
        } else {
            return business
        }
    }

    fileprivate enum PendingState {
        case none
        case sameSitePlan
        case sameSite
        case samePlan
        case differentSitePlan
    }

    fileprivate let free = TestPlans.free.plan
    fileprivate let premium = TestPlans.premium.plan
    fileprivate let business = TestPlans.business.plan
    fileprivate let testSite = 123
    fileprivate let otherSite = 321
    fileprivate let testProduct = "com.wordpress.test.premium.subscription.1year"
}
