import Foundation

struct PlanService {
    let store: StoreFacade
    let remote: PlansRemote

    init(remote: PlansRemote, storeFacade: StoreFacade = StoreKitFacade()) {
        self.store = storeFacade
        self.remote = remote
    }

    func plansWithPricesForBlog(siteID: Int, success: SitePricedPlans -> Void, failure: ErrorType -> Void) {
        remote.getPlansForSite(siteID,
            success: {
                activePlan, availablePlans in
                self.store.getPricesForPlans(availablePlans,
                    success: { pricedPlans in
                        let result = (activePlan: activePlan, availablePlans: pricedPlans)
                        success(result)
                    }, failure: failure)
            }, failure: failure)
    }
}

extension PlanService {
    init(blog: Blog) {
        let remote = PlansRemote(api: blog.restApi())
        self.init(remote: remote)
    }
}
