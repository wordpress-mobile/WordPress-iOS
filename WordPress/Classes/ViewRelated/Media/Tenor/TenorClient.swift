import Foundation

typealias TenorResponseBlock = (Swift.Result<TenorResponse, Error>) -> ()

enum TenorError: Error {
    case networkError
    case wrongDataFormat
    case wrongUrl
}

class TenorClient {
    private let endPoint = "https://api.tenor.com/v1/search"
    private let session = URLSession()
    
    // https://api.tenor.com/v1/search?q=excited&key=EP1HSHBGHKKK&limit=5
    func search(_ query: String, pos: Int, limit: Int, completion: @escaping TenorResponseBlock) {
 
        var components = URLComponents(string: endPoint)

        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: ApiCredentials.tenorAppId()),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "pos", value: "\(pos)")
        ]
        
        guard let url = components?.url else {
            completion(.failure(TenorError.wrongUrl))
            return
        }
        
        session.dataTask(with: url) { (data, response, error) in
            if let data = data {
                if let response = try? JSONDecoder().decode(TenorResponse.self, from: data) {
                    completion(.success(response))
                } else {
                    completion(.failure(TenorError.wrongDataFormat))
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }
}
