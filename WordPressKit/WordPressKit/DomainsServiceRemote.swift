import Foundation
import CocoaLumberjack

public class DomainsServiceRemote: ServiceRemoteWordPressComREST {
    public enum ResponseError: Error {
        case decodingFailed
    }

    public func getDomainsForSite(_ siteID: Int, success: @escaping ([RemoteDomain]) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "sites/\(siteID)/domains"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)

        wordPressComRestApi.GET(path!, parameters: nil,
            success: {
                response, _ in
                do {
                    try success(mapDomainsResponse(response))
                } catch {
                    DDLogError("Error parsing domains response (\(error)): \(response)")
                    failure(error)
                }
            }, failure: {
                error, _ in
                failure(error)
        })
    }
}

private func mapDomainsResponse(_ response: AnyObject) throws -> [RemoteDomain] {
    guard let json = response as? [String: AnyObject],
        let domainsJson = json["domains"] as? [[String: AnyObject]] else {
            throw DomainsServiceRemote.ResponseError.decodingFailed
    }

    let domains = try domainsJson.map { domainJson -> RemoteDomain in

        guard let domainName = domainJson["domain"] as? String,
            let isPrimary = domainJson["primary_domain"] as? Bool else {
                throw DomainsServiceRemote.ResponseError.decodingFailed
        }

        return RemoteDomain(domainName: domainName, isPrimaryDomain: isPrimary, domainType: domainTypeFromDomainJSON(domainJson))
    }

    return domains
}

private func domainTypeFromDomainJSON(_ domainJson: [String: AnyObject]) -> DomainType {
    if let type = domainJson["type"] as? String, type == "redirect" {
        return .siteRedirect
    }

    if let wpComDomain = domainJson["wpcom_domain"] as? Bool, wpComDomain == true {
        return .wpCom
    }

    if let hasRegistration = domainJson["has_registration"] as? Bool, hasRegistration == true {
        return .registered
    }

    return .mapped
}
