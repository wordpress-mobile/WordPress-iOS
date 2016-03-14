import Foundation

struct PlanService<S: Store> {
    let store: S
    let remote: PlansRemote

    init(remote: PlansRemote, store: S) {
        self.store = store
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
    init(blog: Blog, store: S) {
        let remote = PlansRemote(api: blog.restApi())
        self.init(remote: remote, store: store)
    }
}