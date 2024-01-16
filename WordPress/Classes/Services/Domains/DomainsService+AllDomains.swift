import Foundation
import WordPressKit

protocol DomainsServiceAllDomainsFetching {
    func fetchAllDomains(resolveStatus: Bool, noWPCOM: Bool, completion: @escaping (DomainsServiceRemote.AllDomainsEndpointResult) -> Void)
}

extension DomainsService: DomainsServiceAllDomainsFetching {

    /// Makes a GET request to `/v1.1/all-domains` endpoint and returns a list of domain objects.
    ///
    /// - Parameters:
    ///   - resolveStatus: Boolean indicating whether the backend should resolve domain status.
    ///   - noWPCOM: Boolean indicating whether the backend should include `wpcom` domains.
    ///   - completion: The closure to be executed when the API request is complete.
    func fetchAllDomains(resolveStatus: Bool, noWPCOM: Bool, completion: @escaping (AllDomainsEndpointResult) -> Void) {
        var params = AllDomainsEndpointParams()
        params.resolveStatus = resolveStatus
        params.noWPCOM = noWPCOM
        params.locale = Locale.current.identifier
        remote.fetchAllDomains(params: params, completion: completion)
    }

    typealias AllDomainsEndpointResult = DomainsServiceRemote.AllDomainsEndpointResult
    typealias AllDomainsEndpointParams = DomainsServiceRemote.AllDomainsEndpointParams
    typealias AllDomainsListItem = DomainsServiceRemote.AllDomainsListItem
}

extension DomainsService.AllDomainsListItem {

    func matches(searchQuery: String) -> Bool {
        return domain.localizedStandardContains(searchQuery)
        || siteSlug.localizedStandardContains(searchQuery)
        || blogName.localizedStandardContains(searchQuery)
        || (status?.value.localizedStandardContains(searchQuery) ?? false)
    }
}
