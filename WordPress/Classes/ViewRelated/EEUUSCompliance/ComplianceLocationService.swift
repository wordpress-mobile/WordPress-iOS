import WordPressKit

class ComplianceLocationService {
    private let session = URLSession(configuration: .ephemeral)

    func getIPCountryCode(completion: @escaping (Result<String, Error>) -> Void) {
        IPLocationRemote(urlSession: session).fetchIPCountryCode(completion: completion)
    }
}
