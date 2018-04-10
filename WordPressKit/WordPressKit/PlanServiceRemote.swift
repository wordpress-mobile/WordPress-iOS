import Foundation
import WordPressShared
import CocoaLumberjack

public class PlanServiceRemote: ServiceRemoteWordPressComREST {
    public typealias SitePlans = (activePlan: RemotePlan, availablePlans: [RemotePlan])

    public enum ResponseError: Error {
        case decodingFailure
        case unsupportedPlan
        case noActivePlan
    }

    public func getPlansForSite(_ siteID: Int, success: @escaping (SitePlans) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "sites/\(siteID)/plans"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_2)
        let locale = WordPressComLanguageDatabase().deviceLanguage.slug
        let parameters = ["locale": locale]

        wordPressComRestApi.GET(path!,
            parameters: parameters as [String : AnyObject]?,
            success: {
                response, _ in
                do {
                    try success(mapPlansResponse(response))
                } catch {
                    DDLogError("Error parsing plans response for site \(siteID)")
                    DDLogError("\(error)")
                    DDLogDebug("Full response: \(response)")
                    failure(error)
                }
            }, failure: {
                error, _ in
                failure(error)
        })
    }

}

private func mapPlansResponse(_ response: AnyObject) throws -> (activePlan: RemotePlan, availablePlans: [RemotePlan]) {
    guard let json = response as? [[String: AnyObject]] else {
        throw PlanServiceRemote.ResponseError.decodingFailure
    }

    let parsedResponse: (RemotePlan?, [RemotePlan]) = try json.reduce((nil, []), {
        (result, planDetails: [String: AnyObject]) in
        guard let planId = planDetails["product_id"] as? Int,
            let title = planDetails["product_name_short"] as? String,
            let fullTitle = planDetails["product_name"] as? String,
            let tagline = planDetails["tagline"] as? String,
            let featureGroupsJson = planDetails["features_highlight"] as? [[String: AnyObject]] else {
            throw PlanServiceRemote.ResponseError.decodingFailure
        }

        guard let icon = planDetails["icon"] as? String,
            let iconUrl = URL(string: icon),
            let activeIcon = planDetails["icon_active"] as? String,
            let activeIconUrl = URL(string: activeIcon) else {
            return result
        }

        let productIdentifier = (planDetails["apple_sku"] as? String).flatMap({ $0.nonEmptyString() })
        let featureGroups = try parseFeatureGroups(featureGroupsJson)

        let plan = RemotePlan(id: planId, title: title, fullTitle: fullTitle, tagline: tagline, iconUrl: iconUrl, activeIconUrl: activeIconUrl, productIdentifier: productIdentifier, featureGroups: featureGroups)

        let plans = result.1 + [plan]
        if let isCurrent = planDetails["current_plan"] as? Bool,
            isCurrent {
            return (plan, plans)
        } else {
            return (result.0, plans)
        }
    })

    guard let activePlan = parsedResponse.0 else {
        throw PlanServiceRemote.ResponseError.noActivePlan
    }
    let availablePlans = parsedResponse.1
    return (activePlan, availablePlans)
}

private func parseFeatureGroups(_ json: [[String: AnyObject]]) throws -> [RemotePlanFeatureGroupPlaceholder] {
    return try json.compactMap { groupJson in
        guard let slugs = groupJson["items"] as? [String] else { throw PlanServiceRemote.ResponseError.decodingFailure }
        return RemotePlanFeatureGroupPlaceholder(title: groupJson["title"] as? String, slugs: slugs)
    }
}
