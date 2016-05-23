import Foundation

class PlansRemote: ServiceRemoteWordPressComREST {
    typealias SitePlans = (activePlan: Plan, availablePlans: [Plan])
    enum Error: ErrorType {
        case DecodeError
        case UnsupportedPlan
        case NoActivePlan
    }


    func getPlansForSite(siteID: Int, success: SitePlans -> Void, failure: ErrorType -> Void) {
        let endpoint = "sites/\(siteID)/plans"
        let path = pathForEndpoint(endpoint, withVersion: .Version_1_2)
        let locale = WordPressComLanguageDatabase().deviceLanguage.slug
        let parameters = ["locale": locale]

        wordPressComRestApi.GET(path,
            parameters: parameters,
            success: {
                response, _ in
                do {
                    try success(mapPlansResponse(response))
                } catch {
                    DDLogSwift.logError("Error parsing plans response for site \(siteID)")
                    DDLogSwift.logError("\(error)")
                    DDLogSwift.logDebug("Full response: \(response)")
                    failure(error)
                }
            }, failure: {
                error, _ in
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
        guard let planId = planDetails["product_id"] as? Int,
            let title = planDetails["product_name_short"] as? String,
            let fullTitle = planDetails["product_name"] as? String,
            let tagline = planDetails["tagline"] as? String,
            let icon = planDetails["icon"] as? String,
            let iconUrl = NSURL(string: icon),
            let activeIcon = planDetails["icon_active"] as? String,
            let activeIconUrl = NSURL(string: activeIcon),
            let featureGroupsJson = planDetails["features_highlight"] as? [[String: AnyObject]] else {
            throw PlansRemote.Error.DecodeError
        }

        let productIdentifier = (planDetails["apple_sku"] as? String).flatMap({ $0.nonEmptyString() })
        let featureGroups = try parseFeatureGroups(featureGroupsJson)

        let plan = Plan(id: planId, title: title, fullTitle: fullTitle, tagline: tagline, iconUrl: iconUrl, activeIconUrl: activeIconUrl, productIdentifier: productIdentifier, featureGroups: featureGroups)

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

private func parseFeatureGroups(json: [[String: AnyObject]]) throws -> [PlanFeatureGroupPlaceholder] {
    return try json.flatMap { groupJson in
        guard let slugs = groupJson["items"] as? [String] else { throw PlansRemote.Error.DecodeError }
        return PlanFeatureGroupPlaceholder(title: groupJson["title"] as? String, slugs: slugs)
    }
}
