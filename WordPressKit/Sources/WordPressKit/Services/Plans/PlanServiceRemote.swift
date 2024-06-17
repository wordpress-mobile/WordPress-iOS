import Foundation
import WordPressShared

public class PlanServiceRemote: ServiceRemoteWordPressComREST {
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

    /// Fetch the plan ID and name for each of the user's sites.
    /// Accepts locale as a parameter in order to override automatic localization
    /// and return non-localized results when needed.
    ///
    public func getPlanDescriptionsForAllSitesForLocale(_ locale: String, success: @escaping ([Int: RemotePlanSimpleDescription]) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "me/sites"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        let parameters: [String: String] = [
            "fields": "ID, plan",
            "locale": locale
        ]

        wordPressComRESTAPI.get(path,
                                parameters: parameters as [String: AnyObject],
                                success: {
                                    response, _ in

                                    guard let response = response as? EndpointResponse else {
                                        failure(PlanServiceRemote.ResponseError.decodingFailure)
                                        return
                                    }

                                    let result = self.parsePlanDescriptionsForSites(response)
                                    success(result)
        },
                                failure: {
                                    error, _ in
                                    failure(error)
        })
    }

    // MARK: - Non-public methods

    func parsePlanDescriptionsForSites(_ response: EndpointResponse) -> [Int: RemotePlanSimpleDescription] {
        var result = [Int: RemotePlanSimpleDescription]()

        guard let sites = response["sites"] as? [EndpointResponse] else {
            return result
        }

        for site in sites {
            guard
                let tpl = parsePlanDescriptionForSite(site)
            else {
                continue
            }
            result[tpl.siteID] = tpl.plan
        }

        return result
    }

    func parsePlanDescriptionForSite(_ site: EndpointResponse) -> (siteID: Int, plan: RemotePlanSimpleDescription)? {
        guard
            let siteID = site["ID"] as? Int,
            let plan = site["plan"] as? EndpointResponse,
            let planID = plan["product_id"] as? Int,
            let planName = plan["product_name_short"] as? String,
            let planSlug = plan["product_slug"] as? String else {
                return nil
        }

        var name = planName
        if planSlug.contains("jetpack") {
            name = name + " (Jetpack)"
        }

        return (siteID, RemotePlanSimpleDescription(planID: planID, name: name))
    }

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

    /// Retrieves Zendesk meta data: plan and Jetpack addons, if available
    public func getZendeskMetadata(siteID: Int, completion: @escaping (Result<ZendeskMetadata, Error>) -> Void) {
        let endpoint = "me/sites"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        let parameters = ["fields": "ID, zendesk_site_meta"] as [String: AnyObject]

        Task { @MainActor [wordPressComRestApi] in
            await wordPressComRestApi.perform(.get, URLString: path, parameters: parameters, type: ZendeskSiteContainer.self)
                .eraseToError()
                .flatMap { container in
                    guard let metadata = container.body.sites.filter({ $0.ID == siteID }).first?.zendeskMetadata else {
                        return .failure(PlanServiceRemoteError.noMetadata)
                    }
                    return .success(metadata)
                }
                .execute(completion)
        }
    }
}
