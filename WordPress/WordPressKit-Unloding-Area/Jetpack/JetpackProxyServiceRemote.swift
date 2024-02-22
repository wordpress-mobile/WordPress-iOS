/// Encapsulates Jetpack Proxy requests.
public class JetpackProxyServiceRemote: ServiceRemoteWordPressComREST {

    /// Represents the most common HTTP methods for the proxied request.
    public enum DotComMethod: String {
        case get
        case post
        case put
        case delete
    }

    /// Sends a proxied request to a Jetpack-connected site through the Jetpack Proxy API.
    /// The proxy API expects the client to be authenticated with a WordPress.com account.
    ///
    /// - Parameters:
    ///   - siteID: The dotcom ID of the Jetpack-connected site.
    ///   - path: The request endpoint to be proxied.
    ///   - method: The HTTP method for the proxied request.
    ///   - parameters: The request parameter for the proxied request. Defaults to empty.
    ///   - locale: The user locale, if any. Defaults to nil.
    ///   - completion: Closure called after the request completes.
    /// - Returns: A Progress object, which can be used to cancel the request if needed.
    @discardableResult
    public func proxyRequest(for siteID: Int,
                             path: String,
                             method: DotComMethod,
                             parameters: [String: AnyHashable] = [:],
                             locale: String? = nil,
                             completion: @escaping (Result<AnyObject, Error>) -> Void) -> Progress? {
        let urlString = self.path(forEndpoint: "jetpack-blogs/\(siteID)/rest-api", withVersion: ._1_1)

        // Construct the request parameters to be forwarded to the actual endpoint.
        var requestParams: [String: AnyHashable] = [
            "json": "true",
            "path": "\(path)&_method=\(method.rawValue)"
        ]

        // The parameters need to be encoded into a JSON string.
        if !parameters.isEmpty,
           let data = try? JSONSerialization.data(withJSONObject: parameters, options: []),
           let jsonString = String(data: data, encoding: .utf8) {
            // Use "query" for the body parameters if the method is GET. Otherwise, always use "body".
            let bodyParameterKey = (method == .get ? "query" : "body")
            requestParams[bodyParameterKey] = jsonString
        }

        if let locale,
           !locale.isEmpty {
            requestParams["locale"] = locale
        }

        return wordPressComRestApi.POST(urlString, parameters: requestParams as [String: AnyObject]) { response, _ in
            completion(.success(response))
        } failure: { error, _ in
            completion(.failure(error))
        }
    }
}
