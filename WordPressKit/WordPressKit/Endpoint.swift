import Foundation
import Alamofire

public protocol Endpoint {
    associatedtype Output
    func buildRequest() throws -> URLRequest
    func parseResponse(data: Data) throws -> Output

    /// Validates a response.
    ///
    /// If the endpoint doesn't need validation, implement this as an empty method.
    /// Otherwise, inspect the arguments and throw an error if necessary.
    func validate(request: URLRequest?, response: HTTPURLResponse, data: Data?) throws
}

extension Endpoint {
    func request(completion: @escaping (Result<Output>) -> Void) {
        do {
            let request = try buildRequest()

            Alamofire
                .request(request)
                .validate()
                .validate({ (request, response, data) in
                    do {
                        try self.validate(request: request, response: response, data: data)
                        return .success
                    } catch {
                        return .failure(error)
                    }
                })
                .responseData(completionHandler: { (response) in
                    let result = response.result.flatMap(self.parseResponse(data:))
                    completion(result)
                })
        } catch {
            completion(.failure(error))
        }
    }
}
