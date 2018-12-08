import Foundation
import CocoaLumberjack
import WordPressKit


open class PlanService: LocalCoreDataService {

    @objc public func getWpcomPlans(_ success: @escaping () -> Void,
                          failure: @escaping (Error?) -> Void) {

        let remote = PlanServiceRemote(wordPressComRestApi: WordPressComRestApi())
        remote.getWpcomPlans({ [weak self] plans in

            self?.mergeRemoteWpcomPlans(plans.plans, remoteGroups: plans.groups, remoteFeatures: plans.features, onComplete: {
                success()
            })

        }, failure: failure)
    }

    func mergeRemoteWpcomPlans(_ remotePlans: [RemoteWpcomPlan],
                               remoteGroups: [RemotePlanGroup],
                               remoteFeatures: [RemotePlanFeature],
                               onComplete: @escaping () -> Void ) {

        mergeRemoteWpcomPlans(remotePlans)
        mergeRemotePlanGroups(remoteGroups)
        mergeRemotePlanFeatures(remoteFeatures)

        ContextManager.sharedInstance().save(managedObjectContext) {
            onComplete()
        }
    }


    func allPlans() -> [Plan] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Plan.entityName())
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        do {
            return try managedObjectContext.fetch(fetchRequest) as! [Plan]
        } catch let error as NSError {
            DDLogError("Error fetching Plans: \(error.localizedDescription)")
            return [Plan]()
        }
    }


    func findPlanByShortname(_ shortname: String) -> Plan? {
        let plans = allPlans() as NSArray
        let results = plans.filtered(using: NSPredicate(format: "shortname = %@", shortname))
        return results.first as? Plan
    }


    func allPlanGroups() -> [PlanGroup] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: PlanGroup.entityName())
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        do {
            return try managedObjectContext.fetch(fetchRequest) as! [PlanGroup]
        } catch let error as NSError {
            DDLogError("Error fetching PlanGroups: \(error.localizedDescription)")
            return [PlanGroup]()
        }
    }


    func findPlanGroupBySlug(_ slug: String) -> PlanGroup? {
        let groups = allPlanGroups() as NSArray
        let results = groups.filtered(using: NSPredicate(format: "slug = %@", slug))
        return results.first as? PlanGroup
    }


    func allPlanFeatures() -> [PlanFeature] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: PlanFeature.entityName())
        do {
            return try managedObjectContext.fetch(fetchRequest) as! [PlanFeature]
        } catch let error as NSError {
            DDLogError("Error fetching PlanFeatures: \(error.localizedDescription)")
            return [PlanFeature]()
        }
    }


    func findPlanFeatureBySlug(_ slug: String) -> PlanFeature? {
        let features = allPlanFeatures() as NSArray
        let results = features.filtered(using: NSPredicate(format: "slug = %@", slug))
        return results.first as? PlanFeature
    }


    func mergeRemoteWpcomPlans(_ remotePlans: [RemoteWpcomPlan]) {

        // create or update plans
        var plansToKeep = [Plan]()
        for remotePlan in remotePlans {
            var plan = findPlanByShortname(remotePlan.shortname)
            if plan == nil {
                plan = NSEntityDescription.insertNewObject(forEntityName: Plan.entityName(), into: managedObjectContext) as? Plan
            }
            plan?.order = Int16(plansToKeep.count)
            plan?.groups = remotePlan.groups
            plan?.products = remotePlan.products
            plan?.name = remotePlan.name
            plan?.shortname = remotePlan.shortname
            plan?.tagline = remotePlan.tagline
            plan?.summary = remotePlan.description
            plan?.features = remotePlan.features

            plansToKeep.append(plan!)
        }

        // Delete missing plans
        let plans = allPlans()
        for plan in plans {
            if plansToKeep.contains(plan) {
                continue
            }
            managedObjectContext.delete(plan)
        }

    }


    func mergeRemotePlanGroups(_ remoteGroups: [RemotePlanGroup]) {

        // create or update plans
        var groupsToKeep = [PlanGroup]()
        for remoteGroup in remoteGroups {
            var group = findPlanGroupBySlug(remoteGroup.slug)
            if group == nil {
                group = NSEntityDescription.insertNewObject(forEntityName: PlanGroup.entityName(), into: managedObjectContext) as? PlanGroup
            }

            group?.order = Int16(groupsToKeep.count)
            group?.slug = remoteGroup.slug
            group?.name = remoteGroup.name

            groupsToKeep.append(group!)
        }

        // Delete missing plans
        let groups = allPlanGroups()
        for group in groups {
            if groupsToKeep.contains(group) {
                continue
            }
            managedObjectContext.delete(group)
        }

    }

    func mergeRemotePlanFeatures(_ remoteFeatures: [RemotePlanFeature]) {

        // create or update plans
        var featuresToKeep = [PlanFeature]()
        for remoteFeature in remoteFeatures {
            var feature = findPlanFeatureBySlug(remoteFeature.slug)
            if feature == nil {
                feature = NSEntityDescription.insertNewObject(forEntityName: PlanFeature.entityName(), into: managedObjectContext) as? PlanFeature
            }

            feature?.slug = remoteFeature.slug
            feature?.summary = remoteFeature.description
            feature?.title = remoteFeature.title

            featuresToKeep.append(feature!)
        }

        // Delete missing plans
        let features = allPlanFeatures()
        for feature in features {
            if featuresToKeep.contains(feature) {
                continue
            }
            managedObjectContext.delete(feature)
        }
    }
}

extension PlanService {
    @objc public func plansWithPricesForBlog(_ siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let remote_v1_3 = PlanServiceRemote_ApiVersion1_3(wordPressComRestApi: WordPressComRestApi())
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
            failure: { _ in })
    }
}

struct PlanStorage {
    static func activatePlan(_ planID: Int, forSite siteID: Int) {
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

    static func updateHasDomainCredit(_ planID: Int, forSite siteID: Int, hasDomainCredit: Bool) {
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

//public typealias PPlan = RemotePlan
//public typealias PPlanFeature = RemotePlanFeature
//public typealias PlanFeatureGroup = RemotePlanFeatureGroup
//public typealias PlanFeatures = RemotePlanFeatures
//
//struct PlanService<S: InAppPurchaseStore> {
//    // FIXME: @koke 2016-03-22
//    // This was going to be generic but it's causing a lot of trouble. Figure out conflicts first
////    typealias S = StoreKitStore
//    let store: S
//    let remote: PlanServiceRemote
//    fileprivate let featuresRemote: PlanFeatureServiceRemote
//
//    init(store: S, remote: PlanServiceRemote, featuresRemote: PlanFeatureServiceRemote) {
//        self.store = store
//        self.remote = remote
//        self.featuresRemote = featuresRemote
//    }
//
//    func plansWithPricesForBlog(_ siteID: Int, success: @escaping (SitePricedPlans) -> Void, failure: @escaping (Error) -> Void) {
//        remote.getPlansForSite(siteID,
//            success: { activePlan, availablePlans in
//                if let activePlan = activePlan {
//                    PlanStorage.activatePlan(activePlan.id, forSite: siteID)
//                }
//
//                // Purchasing is currently disabled in the app, so return empty prices for all the plans.
//                let pricedPlans: [PricedPlan] = availablePlans.map { ($0, "") }
//                let result = (siteID: siteID, activePlan: activePlan, availablePlans: pricedPlans)
//                success(result)
//            }, failure: failure)
//
//        if FeatureFlag.automatedTransfersCustomDomain.enabled {
//            let remote_v1_3 = PlanServiceRemote_ApiVersion1_3(wordPressComRestApi: remote.wordPressComRestApi)
//
//            remote_v1_3.getPlansForSite(
//                siteID,
//                success: { (plans) in
//                    guard let planId = plans.activePlan.planID,
//                        let planIdInt = Int(planId) else {
//                            return
//                    }
//                    PlanStorage.updateHasDomainCredit(planIdInt,
//                                                      forSite: siteID,
//                                                      hasDomainCredit: plans.activePlan.hasDomainCredit ?? false)
//            },
//            failure: { _ in })
//        }
//    }
//
//    func verifyPurchase(_ siteID: Int, productID: String, receipt: Data, completion: (Bool) -> Void) {
//        // Let's pretend this succeeds for now
//        completion(true)
//    }
//}
//
//extension PlanService {
//    init?(siteID: Int, store: S) {
//        self.store = store
//        let manager = ContextManager.sharedInstance()
//        let context = manager.mainContext
//        let service = BlogService(managedObjectContext: context)
//        guard let blog = service.blog(byBlogId: NSNumber(value: siteID)) else {
//            let error = "Tried to obtain a PlanService for a non-existing site (ID: \(siteID))"
//            assertionFailure(error)
//            DDLogError(error)
//            return nil
//        }
//        guard let account = blog.account else {
//            let error = "Tried to obtain a PlanService for a self hosted site"
//            assertionFailure(error)
//            DDLogError(error)
//            return nil
//        }
//
//        guard let api = account.wordPressComRestApi else {
//            return nil
//        }
//
//        self.remote = PlanServiceRemote(wordPressComRestApi: api)
//        self.featuresRemote = PlanFeatureServiceRemote(wordPressComRestApi: api)
//    }
//}
//extension PlanService {
//    init?(blog: Blog, store: S) {
//        guard let api = blog.wordPressComRestApi() else {
//            return nil
//        }
//
//        let remote = PlanServiceRemote(wordPressComRestApi: api)
//        let featuresRemote = PlanFeatureServiceRemote(wordPressComRestApi: api)
//
//        self.init(store: store, remote: remote, featuresRemote: featuresRemote)
//    }
//}
//
//enum PlanServiceError: Error {
//    case missingFeaturesForPlan
//    case missingFeatureForSlug
//}
//
//extension PlanService {
//    func featureGroupsForPlan(_ plan: Plan, features: PlanFeatures) throws -> [PlanFeatureGroup] {
//        guard let planFeatures = features[plan.id] else {
//            throw PlanServiceError.missingFeaturesForPlan
//        }
//        return try plan.featureGroups.map({ group in
//            let features: [PlanFeature] = try group.slugs.map({ slug in
//                guard let feature = planFeatures.filter({ $0.slug == slug }).first else {
//                    throw PlanServiceError.missingFeatureForSlug
//                }
//                return feature
//            })
//            return PlanFeatureGroup(title: group.title, features: features)
//        })
//        return [PlanFeatureGroup]()
//    }
//
//    func updateAllPlanFeatures(success: @escaping (PlanFeatures) -> Void, failure: @escaping (Error) -> Void) {
//        featuresRemote.getPlanFeatures({
//            success($0)
//        }, failure: failure)
//    }
//}

// We need to call this from Obj-C — there's no way to call `PlanService` directly, with it being
// a generic Swift struct, so it's just a simple shim that exposes a obj-c compatible API.
//@objc class PlanServiceWrapper: NSObject {
//
//    let service: PlanService<StoreKitStore>
//    let blogID: Int
//
//    @objc init?(blog: Blog) {
//        guard let service = PlanService(blog: blog, store: StoreKitStore()),
//            let blogID = blog.dotComID as? Int else {
//            return nil
//        }
//
//        self.blogID = blogID
//        self.service = service
//    }
//
//    @objc func syncPlans(completion: @escaping (Bool, Error?) -> Void) {
//        service.plansWithPricesForBlog(blogID,
//                                       success: { (_) in
//                                        completion(true, nil)
//        },
//                                       failure: { error in
//                                        completion(false, error)
//        })
//    }
//
//}
