import Foundation
import WordPressKit

extension DomainsService {
    
    func fetchAllDomains(params: AllDomainsEndpointParams = .init(), completion: @escaping (AllDomainsEndpointResult) -> Void) {
        remote.getAllDomains(params: params, completion: completion)
    }

    typealias AllDomainsEndpointResult = DomainsServiceRemote.AllDomainsEndpointResult
    typealias AllDomainsEndpointParams = DomainsServiceRemote.AllDomainsEndpointParams
}
