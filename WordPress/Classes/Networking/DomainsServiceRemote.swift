import Foundation

class DomainsServiceRemote: ServiceRemoteREST {
    enum Error: ErrorType {
        case DecodeError
    }

    func getDomainsForSite(siteID: Int, success: [Domain] -> Void, failure: ErrorType -> Void) {
        let endpoint = "sites/\(siteID)/domains"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path,
                parameters: nil,
                success: {
                    _, response in
                    do {
                        try success(mapDomainsResponse(response))
                    } catch {
                        DDLogSwift.logError("Error parsing domains response (\(error)): \(response)")
                        failure(error)
                    }
            }, failure: {
                _, error in
                failure(error)
        })
    }
}

private func mapDomainsResponse(response: AnyObject) throws -> [Domain] {
    guard let json = response as? [String: AnyObject],
        let domainsJson = json["domains"] as? [[String: AnyObject]] else {
            throw DomainsServiceRemote.Error.DecodeError
    }

    let domains = try domainsJson.map { domainJson -> Domain in

        guard let domainName = domainJson["domain"] as? String,
            let isPrimary = domainJson["primary_domain"] as? Bool else {
                throw DomainsServiceRemote.Error.DecodeError
        }

        return Domain(domainName: domainName, isPrimaryDomain: isPrimary, domainType: domainTypeFromDomainJSON(domainJson))
    }

    return domains
}

private func domainTypeFromDomainJSON(domainJson: [String: AnyObject]) -> DomainType {
    if let type = domainJson["type"] as? String
        where type == "redirect" {
        return .SiteRedirect
    }

    if let wpComDomain = domainJson["wpcom_domain"] as? Bool
        where wpComDomain == true {
        return .WPCom
    }

    if let hasRegistration = domainJson["has_registration"] as? Bool
        where hasRegistration == true {
        return .Registered
    }

    return .Mapped
}
