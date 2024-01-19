import WordPressKit

class ComplianceLocationService {
    func getIPCountryCode(completion: @escaping (Result<String, Error>) -> Void) {
        IPLocationRemote().fetchIPCountryCode(completion: completion)
    }
}
