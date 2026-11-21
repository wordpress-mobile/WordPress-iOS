import Foundation
import WordPressKitObjC

open class PlanServiceRemote: ServiceRemoteWordPressComREST {
    public typealias AvailablePlans = (plans: [RemoteWpcomPlan], groups: [RemotePlanGroup], features: [RemotePlanFeature])

    typealias EndpointResponse = [String: AnyObject]

    public enum ResponseError: Int, Error {
        // Error decoding JSON
        case decodingFailure
        // Depricated. An unsupported plan.
        case unsupportedPlan
        // Deprecated. No active plan identified in the results.
        case noActivePlan
    }

    // MARK: - Endpoints

    /// Get the list of WordPress.com plans, their descriptions, and their features.
    ///
    public func getWpcomPlans(_ success: @escaping (AvailablePlans) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "plans/mobile"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)

        wordPressComRESTAPI.get(path,
                                parameters: nil,
                                success: {
                                    response, _ in

                                    guard let response = response as? EndpointResponse else {
                                        failure(PlanServiceRemote.ResponseError.decodingFailure)
                                        return
                                    }

                                    let plans = self.parseWpcomPlans(response)
                                    let groups = self.parseWpcomPlanGroups(response)
                                    let features = self.parseWpcomPlanFeatures(response)

                                    success((plans, groups, features))
        }, failure: {
            error, _ in
            failure(error)
        })
    }

    // MARK: - Non-public methods

    func parseWpcomPlans(_ response: EndpointResponse) -> [RemoteWpcomPlan] {
        guard let json = response["plans"] as? [EndpointResponse] else {
            return [RemoteWpcomPlan]()
        }

        return json.compactMap { parseWpcomPlan($0) }
    }

    func parseWpcomPlanProducts(_ products: [EndpointResponse]) -> String {
        let parsedResult = products.compactMap { $0["plan_id"] as? String }
        return parsedResult.joined(separator: ",")
    }

    func parseWpcomPlanGroups(_ response: EndpointResponse) -> [RemotePlanGroup] {
        guard let json = response["groups"] as? [EndpointResponse] else {
            return [RemotePlanGroup]()
        }
        return json.compactMap { parsePlanGroup($0) }
    }

    func parseWpcomPlanFeatures(_ response: EndpointResponse) -> [RemotePlanFeature] {
        guard let json = response["features"] as? [EndpointResponse] else {
            return [RemotePlanFeature]()
        }
        return json.compactMap { parsePlanFeature($0) }
    }

    func parseWpcomPlan(_ item: EndpointResponse) -> RemoteWpcomPlan? {
        guard
            let groups = (item["groups"] as? [String])?.joined(separator: ","),
            let productsArray = item["products"] as? [EndpointResponse],
            let name = item["name"] as? String,
            let shortname = item["short_name"] as? String,
            let tagline = item["tagline"] as? String,
            let description = item["description"] as? String,
            let features = (item["features"] as? [String])?.joined(separator: ","),
            let icon = item["icon"] as? String,
            let supportPriority = item["support_priority"] as? Int,
            let supportName = item["support_name"] as? String,
            let nonLocalizedShortname = item["nonlocalized_short_name"] as? String else {
                return nil
        }

        let products = parseWpcomPlanProducts(productsArray)

        return RemoteWpcomPlan(groups: groups,
                                     products: products,
                                     name: name,
                                     shortname: shortname,
                                     tagline: tagline,
                                     description: description,
                                     features: features,
                                     icon: icon,
                                     supportPriority: supportPriority,
                                     supportName: supportName,
                                     nonLocalizedShortname: nonLocalizedShortname)
    }

    func parsePlanGroup(_ item: EndpointResponse) -> RemotePlanGroup? {
        guard
            let slug = item["slug"] as? String,
            let name = item["name"] as? String else {
                return nil
        }
        return RemotePlanGroup(slug: slug, name: name)
    }

    func parsePlanFeature(_ item: EndpointResponse) -> RemotePlanFeature? {
        guard
            let slug = item["id"] as? String,
            let title = item["name"] as? String,
            let description = item["description"] as? String else {
                return nil
        }
        return RemotePlanFeature(slug: slug, title: title, description: description, iconURL: nil)
    }
}
