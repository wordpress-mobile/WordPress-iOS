import Alamofire
import WordPressKit

struct GutenbergNetworkRequest {
    typealias CompletionHandler = (Swift.Result<Any, NSError>) -> Void

    private let path: String
    private unowned let blog: Blog

    init(path: String, blog: Blog) {
        self.path = path
        self.blog = blog
    }

    func request(completion: @escaping CompletionHandler) {
        if blog.isAccessibleThroughWPCom(), let dotComID = blog.dotComID {
            dotComRequest(with: dotComID, completion: completion)
        } else {
            selfHostedRequest(completion: completion)
        }
    }

    // MARK: - dotCom

    private func dotComRequest(with dotComID: NSNumber, completion: @escaping CompletionHandler) {
        blog.wordPressComRestApi()?.GET(dotComPath(with: dotComID), parameters: nil, success: { (response, httpResponse) in
            completion(.success(response))
        }, failure: { (error, httpResponse) in
            completion(.failure(error.nsError(with: httpResponse)))
        })
    }

    private func dotComPath(with dotComID: NSNumber) -> String {
        return path.replacingOccurrences(of: "/wp/v2/", with: "/wp/v2/sites/\(dotComID)/")
                   .replacingOccurrences(of: "/oembed/1.0/", with: "/oembed/1.0/sites/\(dotComID)/")
    }

    // MARK: - Self-Hosed

    private func selfHostedRequest(completion: @escaping CompletionHandler) {
        performSelfHostedRequest(completion: completion)
    }

    private func performSelfHostedRequest(completion: @escaping CompletionHandler) {
        guard let api = blog.wordPressOrgRestApi else {
            completion(.failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)))
            return
        }

        api.GET(path, parameters: nil) { (result, httpResponse) in
                switch result {
                    case .success(let response):
                        completion(.success(response))
                    case .failure(let error):
                        if handleEmbedError(path: path, error: error, completion: completion) {
                            return
                        }
                        completion(.failure(error as NSError))
                }
            }
    }

    private func handleEmbedError(path: String, error: Error, completion: @escaping CompletionHandler) -> Bool {
        if path.starts(with: "/oembed/1.0/") {
            if let error = error as? AFError, error.responseCode == 404 {
                completion(.failure(URLError(URLError.Code(rawValue: 404)) as NSError))
                return true
            }
        }
        return false
    }

    private var selfHostedPath: String {
        let removedEditContext = path.replacingOccurrences(of: "context=edit", with: "context=view")
        return "wp-json\(removedEditContext)"
    }
}

/// Helper to get an error instance with the real HTTP Status code, taken from the response object.
/// This is needed since AlamoFire will return code: 7 for any error.
private extension Error {
    func nsError(with response: HTTPURLResponse?) -> NSError {
        let errorCode = response?.statusCode ?? URLError.Code.unknown.rawValue
        let code = URLError.Code(rawValue: errorCode)
        return URLError(code, userInfo: [NSLocalizedDescriptionKey: localizedDescription]) as NSError
    }
}
