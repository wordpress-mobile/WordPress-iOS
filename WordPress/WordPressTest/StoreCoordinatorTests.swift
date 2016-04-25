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

    func testPendingPaymentStoredWhenAllValuesPresent() {
        let payment: PendingPayment = (5, testProduct, 1000)
        let coordinator = storeCoordinator(paymentsEnabled: true, pending: payment)
        
        XCTAssertEqual(coordinator.pendingPayment?.planID, payment.planID)
        XCTAssertEqual(coordinator.pendingPayment?.productID, payment.productID)
        XCTAssertEqual(coordinator.pendingPayment?.siteID, payment.siteID)
    }
    
    func testPendingPaymentHandlesNil() {
        let payment: PendingPayment? = nil
        let coordinator = storeCoordinator(paymentsEnabled: true, pending: payment)
        
        XCTAssertNil(coordinator.pendingPayment)
    }
    
    func testExistingPendingPaymentIsClearedWhenSetToNil() {
        let payment: PendingPayment = (5, testProduct, 1000)
        let coordinator = storeCoordinator(paymentsEnabled: true, pending: payment)
        
        XCTAssertEqual(coordinator.pendingPayment?.planID, payment.planID)
        XCTAssertEqual(coordinator.pendingPayment?.productID, payment.productID)
        XCTAssertEqual(coordinator.pendingPayment?.siteID, payment.siteID)
        
        coordinator.pendingPayment = nil
        
        XCTAssertNil(coordinator.pendingPayment)
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
        let coordinator = StoreCoordinator(store: store)
        coordinator.pendingPayment = pending
        return coordinator
    }

    private func pending(plan plan: Plan, productID: String, siteID: Int, state: PendingState) -> PendingPayment? {
        switch state {
        case .none: return nil
        case .sameSitePlan: return (plan.id, productID, siteID)
        case .sameSite: return (otherPlan(plan).id, productID, siteID)
        case .samePlan: return (plan.id, productID, otherSite)
        case .differentSitePlan: return (otherPlan(plan).id, productID, otherSite)
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
