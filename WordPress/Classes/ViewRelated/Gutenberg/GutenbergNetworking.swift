import Alamofire
import WordPressKit

struct GutenbergNetworkRequest {
    typealias CompletionHandler = (Swift.Result<Any, NSError>) -> Void

    private let path: String
    private unowned let blog: Blog
    private let httpMethod: GutenbergHTTPMethod
    private let parameters: [String: AnyObject]?

    init(path: String, blog: Blog) {
        self.path = path
        self.blog = blog
        self.httpMethod = .get
        self.parameters = nil
    }

    init(path: String, blog: Blog, parameters: [String: AnyObject]? = nil) {
        self.path = path
        self.blog = blog
        self.httpMethod = .post
        self.parameters = parameters
    }

    func request(completion: @escaping CompletionHandler) {
        if blog.isAccessibleThroughWPCom(), let dotComID = blog.dotComID {
            switch httpMethod {
            case .post:
                dotComPostRequest(with: dotComID, completion: completion)
            case .get:
                dotComGetRequest(with: dotComID, completion: completion)
            }
        } else {
            selfHostedRequest(completion: completion)
        }
    }

    // MARK: - dotCom

    private func dotComGetRequest(with dotComID: NSNumber, completion: @escaping CompletionHandler) {
        blog.wordPressComRestApi()?.GET(dotComPath(with: dotComID), parameters: nil, success: { (response, httpResponse) in
            completion(.success(response))
        }, failure: { (error, httpResponse) in
            completion(.failure(error.nsError(with: httpResponse)))
        })
    }

    private func dotComPostRequest(with dotComID: NSNumber, completion: @escaping CompletionHandler) {
        blog.wordPressComRestApi()?.POST(dotComPath(with: dotComID), parameters: parameters, success: { (response, httpResponse) in
            completion(.success(response))
        }, failure: { (error, httpResponse) in
            completion(.failure(error.nsError(with: httpResponse)))
        })
    }

    private func dotComPath(with dotComID: NSNumber) -> String {
        return path.replacingOccurrences(of: "/wp/v2/", with: "/wp/v2/sites/\(dotComID)/")
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

        switch httpMethod {
        case .post:
            api.POST(path, parameters: parameters) { (result, httpResponse) in
                    switch result {
                        case .success(let response):
                            completion(.success(response))
                        case .failure(let error):
                            completion(.failure(error as NSError))
                    }
                }
        case .get:
            api.GET(path, parameters: nil) { (result, httpResponse) in
                    switch result {
                        case .success(let response):
                            completion(.success(response))
                        case .failure(let error):
                            completion(.failure(error as NSError))
                    }
                }
        }
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

enum GutenbergHTTPMethod: String {
    case get = "GET"
    case post = "POST"
}
