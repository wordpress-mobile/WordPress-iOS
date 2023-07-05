import WordPressKit

final class ComplianceLocationService {
    func getIPCountryCode(completion: @escaping (Result<String, Error>) -> Void) {
        IPLocationRemote().fetchIPCountryCode { result in
            switch result {
            case .success(let countryCode):
                completion(.success(countryCode))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
