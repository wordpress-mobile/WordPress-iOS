import Foundation
import CocoaLumberjack
import WordPressKit

public typealias Plan = RemotePlan
public typealias PlanFeature = RemotePlanFeature
public typealias PlanFeatureGroup = RemotePlanFeatureGroup
public typealias PlanFeatures = RemotePlanFeatures

struct PlanService<S: InAppPurchaseStore> {
    // FIXME: @koke 2016-03-22
    // This was going to be generic but it's causing a lot of trouble. Figure out conflicts first
//    typealias S = StoreKitStore
    let store: S
    let remote: PlanServiceRemote
    fileprivate let featuresRemote: PlanFeatureServiceRemote

    private lazy var restApi: WordPressComRestApi = {
        let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return accountService.defaultWordPressComAccount()?.wordPressComRestApi ?? WordPressComRestApi(oAuthToken: "")
    }()

    private lazy var remote_v1_3: PlanServiceRemote_ApiVersion1_3 = {
        return PlanServiceRemote_ApiVersion1_3(wordPressComRestApi: restApi)
    }()

    init(store: S, remote: PlanServiceRemote, featuresRemote: PlanFeatureServiceRemote) {
        self.store = store
        self.remote = remote
        self.featuresRemote = featuresRemote
    }

    mutating func plansWithPricesForBlog(_ siteID: Int, success: @escaping (SitePricedPlans) -> Void, failure: @escaping (Error) -> Void) {
        remote.getPlansForSite(siteID,
            success: {
                activePlan, availablePlans in
                PlanStorage.activatePlan(activePlan.id, forSite: siteID)

                // Purchasing is currently disabled in the app, so return empty prices for all the plans.
                let pricedPlans: [PricedPlan] = availablePlans.map { ($0, "") }
                let result = (siteID: siteID, activePlan: activePlan, availablePlans: pricedPlans)
                success(result)
            }, failure: failure)

        if FeatureFlag.automatedTransfersCustomDomain.enabled {
            remote_v1_3.getPlansForSite(
                siteID,
                success: { (plans) in
                    guard let planId = plans.activePlan.planID,
                        let planIdInt = Int(planId) else {
                            return
                    }
                    PlanStorage.updateHasDomainCredit(planIdInt,
                                                      forSite: siteID,
                                                      hasDomainCredit: plans.activePlan.hasDomainCredit ?? false)
            },
            failure: failure)
        }
    }

    func verifyPurchase(_ siteID: Int, productID: String, receipt: Data, completion: (Bool) -> Void) {
        // Let's pretend this succeeds for now
        completion(true)
    }
}

extension PlanService {
    init?(siteID: Int, store: S) {
        self.store = store
        let manager = ContextManager.sharedInstance()
        let context = manager.mainContext
        let service = BlogService(managedObjectContext: context)
        guard let blog = service.blog(byBlogId: NSNumber(value: siteID)) else {
            let error = "Tried to obtain a PlanService for a non-existing site (ID: \(siteID))"
            assertionFailure(error)
            DDLogError(error)
            return nil
        }
        guard let account = blog.account else {
            let error = "Tried to obtain a PlanService for a self hosted site"
            assertionFailure(error)
            DDLogError(error)
            return nil
        }

        guard let api = account.wordPressComRestApi else {
            return nil
        }

        self.remote = PlanServiceRemote(wordPressComRestApi: api)
        self.featuresRemote = PlanFeatureServiceRemote(wordPressComRestApi: api)
    }
}

struct PlanStorage {
    static func activatePlan(_ planID: PlanID, forSite siteID: Int) {
        let manager = ContextManager.sharedInstance()
        let context = manager.newDerivedContext()
        let service = BlogService(managedObjectContext: context)
        context.performAndWait {
            guard let blog = service.blog(byBlogId: NSNumber(value: siteID)) else {
                let error = "Tried to activate a plan for a non-existing site (ID: \(siteID))"
                assertionFailure(error)
                DDLogError(error)
                return
            }
            if blog.planID?.intValue != planID {
                blog.planID = NSNumber(value: planID)
                manager.saveContextAndWait(context)
            }
        }
    }

    static func updateHasDomainCredit(_ planID: PlanID, forSite siteID: Int, hasDomainCredit: Bool) {
        let manager = ContextManager.sharedInstance()
        let context = manager.newDerivedContext()
        let service = BlogService(managedObjectContext: context)
        context.performAndWait {
            guard let blog = service.blog(byBlogId: NSNumber(value: siteID)) else {
                let error = "Tried to update a plan for a non-existing site (ID: \(siteID))"
                assertionFailure(error)
                DDLogError(error)
                return
            }
            if blog.hasDomainCredit != hasDomainCredit {
                blog.hasDomainCredit = hasDomainCredit
                manager.saveContextAndWait(context)
            }
        }
    }
}

extension PlanService {
    init?(blog: Blog, store: S) {
        guard let api = blog.wordPressComRestApi() else {
            return nil
        }

        let remote = PlanServiceRemote(wordPressComRestApi: api)
        let featuresRemote = PlanFeatureServiceRemote(wordPressComRestApi: api)

        self.init(store: store, remote: remote, featuresRemote: featuresRemote)
    }
}

enum PlanServiceError: Error {
    case missingFeaturesForPlan
    case missingFeatureForSlug
}

extension PlanService {
    func featureGroupsForPlan(_ plan: Plan, features: PlanFeatures) throws -> [PlanFeatureGroup] {
        guard let planFeatures = features[plan.id] else {
            throw PlanServiceError.missingFeaturesForPlan
        }
        return try plan.featureGroups.map({ group in
            let features: [PlanFeature] = try group.slugs.map({ slug in
                guard let feature = planFeatures.filter({ $0.slug == slug }).first else {
                    throw PlanServiceError.missingFeatureForSlug
                }
                return feature
            })
            return PlanFeatureGroup(title: group.title, features: features)
        })
    }

    func updateAllPlanFeatures(success: @escaping (PlanFeatures) -> Void, failure: @escaping (Error) -> Void) {
        featuresRemote.getPlanFeatures({
            success($0)
        }, failure: failure)
    }
}
