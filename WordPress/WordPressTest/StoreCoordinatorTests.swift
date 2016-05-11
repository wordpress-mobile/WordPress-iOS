import Foundation
import Nimble
@testable import WordPress

class StoreCoordinatorTests: XCTestCase {

    func testPurchaseUnavailableWithPaymentDisabled() {
        let availability = availabilityWith(plan: business, active: free, paymentsEnabled: false, pendingState: .none)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseUnavailableForDowngrade() {
        let availability = availabilityWith(plan: premium, active: business, paymentsEnabled: true, pendingState: .none)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseUnavailableForUpgrade() {
        let availability = availabilityWith(plan: business, active: premium, paymentsEnabled: true, pendingState: .none)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseUnavailableForFreePlan() {
        // This test doesn't make much sense now as we don't allow any downgrades right now
        // When we support that however, we still shouldn't allow "purchasing" a Free plan
        let availability = availabilityWith(plan: free, active: premium, paymentsEnabled: true, pendingState: .none)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseUnavailableForActivePlan() {
        let availability = availabilityWith(plan: premium, active: premium, paymentsEnabled: true, pendingState: .none)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchasePendingForSameSitePlan() {
        let availability = availabilityWith(plan: premium, active: free, paymentsEnabled: true, pendingState: .sameSitePlan)
        XCTAssertEqual(availability, PurchaseAvailability.pending)
    }

    func testPurchaseUnavailableForSameSite() {
        let availability = availabilityWith(plan: premium, active: free, paymentsEnabled: true, pendingState: .sameSite)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseUnavailableForSamePlan() {
        let availability = availabilityWith(plan: premium, active: free, paymentsEnabled: true, pendingState: .samePlan)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseUnavailableForDifferentSitePlan() {
        let availability = availabilityWith(plan: premium, active: free, paymentsEnabled: true, pendingState: .differentSitePlan)
        XCTAssertEqual(availability, PurchaseAvailability.unavailable)
    }

    func testPurchaseAvailableOtherwise() {
        let availability = availabilityWith(plan: premium, active: free, paymentsEnabled: true, pendingState: .none)
        XCTAssertEqual(availability, PurchaseAvailability.available)
    }

    func testCannotPurchaseWhenPurchaseAlreadyPending() {
        let payment: PendingPayment = (testProduct, testSite)
        let coordinator = storeCoordinator(paymentsEnabled: true, pending: payment)
        let product = TestPlans.business.product

        // And now attempt a second purchase
        XCTAssertThrowsError(try coordinator.purchaseProduct(product, forSite: testSite))
    }

    func testCanMakePaymentWhenNoPaymentIsPending() {
        let coordinator = storeCoordinator(paymentsEnabled: true, pending: nil)
        let product = TestPlans.business.product

        do {
            try coordinator.purchaseProduct(product, forSite: otherSite)
        } catch {
            XCTFail("Expected call not to throw")
        }
    }

    // ========================= END OF TESTS =============================== //


    // MARK: - Helpers

    private func availabilityWith(plan plan: Plan, active: Plan, paymentsEnabled: Bool, pendingState: PendingState) -> PurchaseAvailability {
        let pendingPayment = pending(plan: plan, productID: testProduct, siteID: testSite, state: pendingState)
        let coordinator = storeCoordinator(paymentsEnabled: paymentsEnabled, pending: pendingPayment)
        return coordinator.purchaseAvailability(forPlan: plan, siteID: testSite, activePlan: active)
    }

    private func storeCoordinator(paymentsEnabled paymentsEnabled: Bool, pending: PendingPayment?) -> StoreCoordinator<MockStore> {
        var store = MockStore.succeeding()
        store.canMakePayments = paymentsEnabled

        let coordinator = StoreCoordinator(store: store, database: EphemeralKeyValueDatabase())

        if let pending = pending,
            let product = TestPlans.allProducts.filter({ $0.productIdentifier == pending.productID }).first {
            try! coordinator.purchaseProduct(product, forSite: pending.siteID)
        }

        return coordinator
    }

    private func pending(plan plan: Plan, productID: String, siteID: Int, state: PendingState) -> PendingPayment? {
        switch state {
        case .none: return nil
        case .sameSitePlan: return (productID, siteID)
        case .sameSite: return (otherPlan(plan).productIdentifier!, siteID)
        case .samePlan: return (productID, otherSite)
        case .differentSitePlan: return (otherPlan(plan).productIdentifier!, otherSite)
        }
    }

    private func otherPlan(plan: Plan) -> Plan {
        if plan == business {
            return premium
        } else {
            return business
        }
    }

    private enum PendingState {
        case none
        case sameSitePlan
        case sameSite
        case samePlan
        case differentSitePlan
    }

    private let free = TestPlans.free.plan
    private let premium = TestPlans.premium.plan
    private let business = TestPlans.business.plan
    private let testSite = 123
    private let otherSite = 321
    private let testProduct = "com.wordpress.test.premium.subscription.1year"
}
