import Foundation
import Alamofire

/// Represents a specific type of Network request.
///
/// This protocol provides the building blocks to define network requests
/// independent of the network library used. It has 3 responsibilities:
///
///     - Creating a URLRequest
///     - Validating the response
///     - Parsing response data into the expected result
///
/// Validation is an optional step that allows inspection of the URLResponse
/// object. If an endpoint doesn’t need custom validation, it can have an empty
/// implementation.
///
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
                .responseData(queue: DispatchQueue.global(qos: .utility), completionHandler: { (response) in
                    let result = response.result.flatMap(self.parseResponse(data:))
                    DispatchQueue.main.async {
                        completion(result)
                    }
                })
        } catch {
            completion(.failure(error))
        }
    }
}
