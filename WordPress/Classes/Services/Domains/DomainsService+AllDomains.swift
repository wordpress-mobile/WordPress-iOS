import Foundation
import WordPressKit

extension DomainsService {

    /// Makes a call request to `GET /v1.1/all-domains` and returns a list of domain objects.
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
}
