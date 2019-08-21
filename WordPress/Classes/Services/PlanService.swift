import Foundation
import CocoaLumberjack
import WordPressKit


open class PlanService: LocalCoreDataService {

    public func getAllSitesNonLocalizedPlanDescriptionsForAccount(_ account: WPAccount,
                                                                  success: @escaping ([Int: RemotePlanSimpleDescription]) -> Void,
                                                                  failure: @escaping (Error?) -> Void) {
        guard let api = account.wordPressComRestApi else {
            success([Int: RemotePlanSimpleDescription]())
            return
        }

        let remote = PlanServiceRemote(wordPressComRestApi: api)
        remote.getPlanDescriptionsForAllSitesForLocale("en", success: { result in
            success(result)
        }, failure: failure)
    }

    @objc public func getWpcomPlans(_ account: WPAccount,
                                    success: @escaping () -> Void,
                          failure: @escaping (Error?) -> Void) {

        guard let api = account.wordPressComRestApi else {
            failure(nil)
            return
        }

        let remote = PlanServiceRemote(wordPressComRestApi: api)
        remote.getWpcomPlans({ plans in

            self.mergeRemoteWpcomPlans(plans.plans, remoteGroups: plans.groups, remoteFeatures: plans.features, onComplete: {
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
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Plan")
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
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PlanGroup")
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
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PlanFeature")
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
                plan = NSEntityDescription.insertNewObject(forEntityName: "Plan", into: managedObjectContext) as? Plan
            }
            plan?.order = Int16(plansToKeep.count)
            plan?.groups = remotePlan.groups
            plan?.products = remotePlan.products
            plan?.name = remotePlan.name
            plan?.shortname = remotePlan.shortname
            plan?.tagline = remotePlan.tagline
            plan?.summary = remotePlan.description
            plan?.features = remotePlan.features
            plan?.icon = remotePlan.icon

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
                group = NSEntityDescription.insertNewObject(forEntityName: "PlanGroup", into: managedObjectContext) as? PlanGroup
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
                feature = NSEntityDescription.insertNewObject(forEntityName: "PlanFeature", into: managedObjectContext) as? PlanFeature
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
    @objc public func plansWithPricesForBlog(_ blog: Blog, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        guard let restAPI = blog.wordPressComRestApi(),
            let siteID = blog.dotComID?.intValue else {
                let description = NSLocalizedString("Unable to update plan prices. There is a problem with the supplied blog.",
                                                    comment: "This is an error message that could be shown when updating Plans in the app.")
                let error = NSError(domain: "PlanService", code: 0, userInfo: [NSLocalizedDescriptionKey: description])
                failure(error)
                return
        }
        let remote_v1_3 = PlanServiceRemote_ApiVersion1_3(wordPressComRestApi: restAPI)
        remote_v1_3.getPlansForSite(
            siteID,
            success: { (plans) in
                guard let planId = plans.activePlan.planID,
                    let planIdInt = Int(planId) else {
                        // There won't necessarily be an active plan so this is not really a failure
                        success()
                        return
                }
                PlanStorage.updateHasDomainCredit(planIdInt,
                                                  forSite: siteID,
                                                  hasDomainCredit: plans.activePlan.hasDomainCredit ?? false)
                success()
        },
            failure: { error in
                DDLogError("Failed checking prices for blog for site \(siteID): \(error.localizedDescription)")
                failure(error)
        })
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
