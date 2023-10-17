import Foundation
import WordPressKit

extension DomainsService {

    func fetchAllDomains(params: AllDomainsEndpointParams = .init(), completion: @escaping (AllDomainsEndpointResult) -> Void) {
        remote.fetchAllDomains(params: params, completion: completion)
    }

    typealias AllDomainsEndpointResult = DomainsServiceRemote.AllDomainsEndpointResult
    typealias AllDomainsEndpointParams = DomainsServiceRemote.AllDomainsEndpointParams
}
