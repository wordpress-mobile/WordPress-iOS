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

typealias PlanFeatures = [PlanID: [PlanFeature]]

struct PlanFeaturesService {
    private static var planFeatures = PlanFeatures()
    
    /// - returns: All features that are part of the specified plan
    static func featuresForPlan(plan: Plan) -> [PlanFeature] {
        return planFeatures[plan.id] ?? []
    }

    /// - returns: The feature that is part of the specified plan, with a matching slug (if one exists).
    static func featureForPlan(plan: Plan, withSlug slug: String) -> PlanFeature? {
        return featuresForPlan(plan).filter({ $0.slug == slug }).first
    }
    
    private let remote = PlanFeaturesRemote(api: WordPressComApi.anonymousApi())
    
    func updateAllPlanFeatures(success: () -> Void, failure: ErrorType -> Void) {
        remote.getPlanFeatures({ planFeatures in
            PlanFeaturesService.planFeatures = planFeatures
            success()
        }, failure: failure)
    }
}
