import Foundation
import CocoaLumberjack

struct DomainSuggestion {
    let name: String
    let isFree: Bool

    init(json: [String: AnyObject]) throws {
        // name
        guard let domain_name = json["domain_name"] as? String else {
            throw DomainsServiceRemote.ResponseError.decodingFailed
        }
        name = domain_name

        // isFree
        if let is_free = json["is_free"] as? Int {
            isFree = is_free == 1
        } else {
            isFree = false
        }
    }
}

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

    /* from https://opengrok.a8c.com/source/xref/trunk/public.api/rest/wpcom-json-endpoints/class.wpcom-store-domains-api-endpoints.php
 "'description'      => 'Get a list of suggested domain names that are available for registration based on a given term or domain name.',
 154    // 'group'            => 'domains',
 155    'group'            => '__do_not_document',
 156    'stat'             => 'domains:suggestions',
 157    'force'            => 'wpcom',
 158    'method'           => 'GET',
 159    'path'             => '/domains/suggestions',
 160    'query_parameters' => array(
 161        'context'                 => false,
 162        'query'                   => '(string) Term (e.g "flowers") or domain name (e.g. "flowers.com") to search alternative domain names from',
 163        'quantity'                => '(int=5) Maximum number of suggestions to return (limited to 36)',
 164        'include_wordpressdotcom' => '(bool) Whether or not to include wordpress.com subdomains',
 165        'include_dotblogsubdomain'=> '(bool) Whether or not to include .blog subdomains',
 166        'vendor'                  => '(string) Suggestions vendor to use (domainsbot available)',
 167        'tlds'                    => "(array) List of TLDs to restrict the results to, e.g. [ 'com', 'net' ]",
 168        'vertical'                => '(string) Optional. A vertical code (e.g. a8c.8) to improve domain suggestions',
 169        'recommendations_only'    => '(bool) Optional. Determines whether exact matches are included in results, or only recommendations for similar domains.',
 170        'tld_weight_overrides'    => '(array) Optional. List of identifiers which will be used in Domain_Suggestions to override the weights of certain TLDs.',
 171    ),
 172    'example_request'  => 'http://public-api.wordpress.com/rest/v1/domains/suggestions?query=flowers&quantity=5',
 173    'response_format'  => array( 'List of domain names available for registration' ),
 174    'example_response' => '[
 175        {
 176            "domain_name": "silkflowers.me",
 177            "cost": "$25.00"
 178        },
 179        {
 180            "domain_name": "bestflowers.me",
 181            "cost": "$25.00"
 182        },
 183        {
 184            "domain_name": "bestflowers.co",
 185            "cost": "$25.00"
 186        },
 187        {
 188            "domain_name": "wholesaleflowers.me",
 189            "cost": "$25.00"
 190        },
 191        {
 192            "domain_name": "wholesaleflowers.org",
 193            "cost": "$18.00"
 194        }
 195    ]'
     /// an actual response
(
        {
        cost = Free;
        "domain_name" = "testsuggest.wordpress.com";
        "is_free" = 1;
    },
        {
        cost = "C$29.15";
        "domain_name" = "testsuggest.blog";
        "product_id" = 76;
        "product_slug" = "dotblog_domain";
        relevance = 1;
        "supports_privacy" = 1;
    },
        {
        cost = "C$24.00";
        "domain_name" = "testsuggest.com";
        "product_id" = 6;
        "product_slug" = "domain_reg";
        relevance = 1;
        "supports_privacy" = 1;
    },
        {
        cost = "C$24.00";
        "domain_name" = "testsuggest.ca";
        "product_id" = 83;
        "product_slug" = "dotca_domain";
        relevance = 1;
        "supports_privacy" = 0;
    },
        {
        cost = "C$29.15";
        "domain_name" = "demosuggest.blog";
        "product_id" = 76;
        "product_slug" = "dotblog_domain";
        relevance = "0.968";
        "supports_privacy" = 1;
    }
)
    */
    public func getDomainSuggestions(base query: String, success: @escaping ([String]) -> Void, failure: @escaping (Error) -> Void) {
        let endPoint = "domains/suggestions"
        let servicePath = path(forEndpoint: endPoint, withVersion: ._1_1)
        let parameters: [String: AnyObject] = ["query": query as AnyObject,
                                               "include_wordpressdotcom": true as AnyObject,
                                               "only_wordpressdotcom": true as AnyObject]

        wordPressComRestApi.GET(servicePath!,
                                parameters: parameters,
                                success: {
                                    response, _ in
                                    do {
                                        let suggestions = try map(suggestions: response)
                                        let domains = suggestions.map { suggestion -> String in
                                            return suggestion.name
                                        }
                                        success(domains)
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

private func map(suggestions response: AnyObject) throws -> [DomainSuggestion] {
    guard let jsonSuggestions = response as? [[String: AnyObject]] else {
        throw DomainsServiceRemote.ResponseError.decodingFailed
    }
    var suggestions: [DomainSuggestion] = []
    for jsonSuggestion in jsonSuggestions {
        do {
            let suggestion = try DomainSuggestion(json: jsonSuggestion)
            suggestions.append(suggestion)
        }
    }
    return suggestions
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
