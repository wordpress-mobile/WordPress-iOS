import Foundation
import CocoaLumberjack
import WordPressKit

open class PlanService: NSObject {

    private let coreDataStack: CoreDataStack

    @objc init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

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

            self.mergeRemoteWpcomPlans(plans.plans, remoteGroups: plans.groups, remoteFeatures: plans.features, onComplete: success)

        }, failure: failure)
    }

    private func mergeRemoteWpcomPlans(_ remotePlans: [RemoteWpcomPlan],
                               remoteGroups: [RemotePlanGroup],
                               remoteFeatures: [RemotePlanFeature],
                               onComplete: @escaping () -> Void ) {
        coreDataStack.performAndSave({ context in
            self.mergeRemoteWpcomPlans(remotePlans, in: context)
            self.mergeRemotePlanGroups(remoteGroups, in: context)
            self.mergeRemotePlanFeatures(remoteFeatures, in: context)
        }, completion: onComplete, on: .main)
    }

    func allPlans(in context: NSManagedObjectContext) -> [Plan] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Plan")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        do {
            return try context.fetch(fetchRequest) as! [Plan]
        } catch let error as NSError {
            DDLogError("Error fetching Plans: \(error.localizedDescription)")
            return [Plan]()
        }
    }

    private func findPlanByShortname(_ shortname: String, in context: NSManagedObjectContext) -> Plan? {
        allPlans(in: context).first {
            $0.shortname == shortname
        }
    }

    private func allPlanGroups(in context: NSManagedObjectContext) -> [PlanGroup] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PlanGroup")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        do {
            return try context.fetch(fetchRequest) as! [PlanGroup]
        } catch let error as NSError {
            DDLogError("Error fetching PlanGroups: \(error.localizedDescription)")
            return [PlanGroup]()
        }
    }

    private func findPlanGroupBySlug(_ slug: String, in context: NSManagedObjectContext) -> PlanGroup? {
        allPlanGroups(in: context).first {
            $0.slug == slug
        }
    }

    func allPlanFeatures(in context: NSManagedObjectContext) -> [PlanFeature] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PlanFeature")
        do {
            return try context.fetch(fetchRequest) as! [PlanFeature]
        } catch let error as NSError {
            DDLogError("Error fetching PlanFeatures: \(error.localizedDescription)")
            return [PlanFeature]()
        }
    }

    private func findPlanFeatureBySlug(_ slug: String, in context: NSManagedObjectContext) -> PlanFeature? {
        let features = allPlanFeatures(in: context) as NSArray
        let results = features.filtered(using: NSPredicate(format: "slug = %@", slug))
        return results.first as? PlanFeature
    }

    private func mergeRemoteWpcomPlans(_ remotePlans: [RemoteWpcomPlan], in context: NSManagedObjectContext) {

        // create or update plans
        var plansToKeep = [Plan]()
        for remotePlan in remotePlans {
            var plan = findPlanByShortname(remotePlan.shortname, in: context)
            if plan == nil {
                plan = NSEntityDescription.insertNewObject(forEntityName: "Plan", into: context) as? Plan
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
            plan?.nonLocalizedShortname = remotePlan.nonLocalizedShortname
            plan?.supportName = remotePlan.supportName
            plan?.supportPriority = Int16(remotePlan.supportPriority)

            plansToKeep.append(plan!)
        }

        // Delete missing plans
        let plans = allPlans(in: context)
        for plan in plans {
            if plansToKeep.contains(plan) {
                continue
            }
            context.delete(plan)
        }

    }

    private func mergeRemotePlanGroups(_ remoteGroups: [RemotePlanGroup], in context: NSManagedObjectContext) {

        // create or update plans
        var groupsToKeep = [PlanGroup]()
        for remoteGroup in remoteGroups {
            var group = findPlanGroupBySlug(remoteGroup.slug, in: context)
            if group == nil {
                group = NSEntityDescription.insertNewObject(forEntityName: "PlanGroup", into: context) as? PlanGroup
            }

            group?.order = Int16(groupsToKeep.count)
            group?.slug = remoteGroup.slug
            group?.name = remoteGroup.name

            groupsToKeep.append(group!)
        }

        // Delete missing plans
        let groups = allPlanGroups(in: context)
        for group in groups {
            if groupsToKeep.contains(group) {
                continue
            }
            context.delete(group)
        }

    }

    private func mergeRemotePlanFeatures(_ remoteFeatures: [RemotePlanFeature], in context: NSManagedObjectContext) {

        // create or update plans
        var featuresToKeep = [PlanFeature]()
        for remoteFeature in remoteFeatures {
            var feature = findPlanFeatureBySlug(remoteFeature.slug, in: context)
            if feature == nil {
                feature = NSEntityDescription.insertNewObject(forEntityName: "PlanFeature", into: context) as? PlanFeature
            }

            feature?.slug = remoteFeature.slug
            feature?.summary = remoteFeature.description
            feature?.title = remoteFeature.title

            featuresToKeep.append(feature!)
        }

        // Delete missing plans
        let features = allPlanFeatures(in: context)
        for feature in features {
            if featuresToKeep.contains(feature) {
                continue
            }
            context.delete(feature)
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
                self.coreDataStack.performAndSave({ context in
                    PlanStorage.updateHasDomainCredit(
                        planIdInt,
                        forBlog: blog,
                        hasDomainCredit: plans.activePlan.hasDomainCredit ?? false,
                        in: context
                    )
                }, completion: success, on: .main)
            },
            failure: { error in
                DDLogError("Failed checking prices for blog for site \(siteID): \(error.localizedDescription)")
                failure(error)
            }
        )
    }
}

private struct PlanStorage {
    static func updateHasDomainCredit(_ planID: Int, forBlog blog: Blog, hasDomainCredit: Bool, in context: NSManagedObjectContext) {
        guard let blogInContext = try? context.existingObject(with: blog.objectID) as? Blog else {
            let error = "Tried to update a plan for a non-existing site"
            assertionFailure(error)
            DDLogError(error)
            return
        }
        if blogInContext.hasDomainCredit != hasDomainCredit {
            blogInContext.hasDomainCredit = hasDomainCredit
        }
    }
}
