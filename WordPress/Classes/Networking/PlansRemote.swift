import Foundation

class PlansRemote: ServiceRemoteREST {
    typealias SitePlans = (activePlan: Plan, availablePlans: [Plan])
    enum Error: ErrorType {
        case DecodeError
        case UnsupportedPlan
        case NoActivePlan
    }


    func getPlansForSite(siteID: Int, success: SitePlans -> Void, failure: ErrorType -> Void) {
        let endpoint = "sites/\(siteID)/plans"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_2)

        api.GET(path,
            parameters: nil,
            success: {
                _, response in
                do {
                    try success(mapPlansResponse(response))
                } catch {
                    failure(error)
                }
            }, failure: {
                _, error in
                failure(error)
        })
    }

}

private func mapPlansResponse(response: AnyObject) throws -> (activePlan: Plan, availablePlans: [Plan]) {
    guard let json = response as? [[String: AnyObject]] else {
        throw PlansRemote.Error.DecodeError
    }

    let parsedResponse: (Plan?, [Plan]) = try json.reduce((nil, []), combine: {
        (result, planDetails: [String: AnyObject]) in
        guard let planId = planDetails["product_id"] as? Int else {
            throw PlansRemote.Error.DecodeError
        }
        guard let plan = defaultPlans.withID(planId) else {
            throw PlansRemote.Error.UnsupportedPlan
        }
  
        if let featureGroupsJson = planDetails["features_highlight"] as? [[String: AnyObject]] {
            try parseFeatureGroups(featureGroupsJson, forPlan: plan)
        }
        
        let plans = result.1 + [plan]
        if let isCurrent = planDetails["current_plan"] as? Bool where
            isCurrent {
            return (plan, plans)
        } else {
            return (result.0, plans)
        }
    })
    
    guard let activePlan = parsedResponse.0 else {
        throw PlansRemote.Error.NoActivePlan
    }
    let availablePlans = parsedResponse.1.sort()
    return (activePlan, availablePlans)
}

private func parseFeatureGroups(json: [[String: AnyObject]], forPlan plan: Plan) throws {
    let groups: [PlanFeatureGroup] = try json.flatMap { groupJson in
        guard let slugs = groupJson["items"] as? [String] else { throw PlansRemote.Error.DecodeError }
        return PlanFeatureGroup(title: groupJson["title"] as? String, slugs: slugs)
    }
    
    PlanFeatureGroup.setGroups(groups, forPlan: plan)
}

