import Foundation

struct PlanService<S: Store> {
    let store: StoreFacade<S>

    init(storeFacade: StoreFacade<S>) {
        self.store = storeFacade
    }

    func plansForBlog(siteID: Int, success: [Plan] -> Void, failure: ErrorType -> Void) {
        // Hardcoded for now. Use success/failure in case we retrieve plans from the API instead.
        success([.Free, .Premium, .Business])
    }

    func plansWithPricesForBlog(siteID: Int, success: [(Plan, String)] -> Void, failure: ErrorType -> Void) {
        plansForBlog(siteID,
            success: { plans in
                return self.store.getPricesForPlans(plans,
                    success: { prices in
                        success(Array(zip(plans, prices)))
                    }, failure: failure)
            }, failure: failure)
    }
}