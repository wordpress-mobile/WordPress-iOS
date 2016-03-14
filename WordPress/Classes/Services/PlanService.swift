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
                PlanStorage.activatePlan(activePlan, forSite: siteID)
                self.store.getPricesForPlans(availablePlans,
                    success: { pricedPlans in
                        let result = (activePlan: activePlan, availablePlans: pricedPlans)
                        success(result)
                    }, failure: failure)
            }, failure: failure)
    }
}

struct PlanStorage {
    static func activatePlan(plan: Plan, forSite siteID: Int) {
        let manager = ContextManager.sharedInstance()
        let context = manager.newDerivedContext()
        let service = BlogService(managedObjectContext: context)
        context.performBlockAndWait {
            guard let blog = service.blogByBlogId(siteID) else {
                let error = "Tried to activate a plan for a non-existing site (ID: \(siteID))"
                assertionFailure(error)
                DDLogSwift.logError(error)
                return
            }
            if blog.planID != plan.id {
                blog.planID = plan.id
                manager.saveContextAndWait(context)
            }
        }
    }
}

extension PlanService {
    init(blog: Blog, store: S) {
        let remote = PlansRemote(api: blog.restApi())
        self.init(remote: remote, store: store)
    }
}