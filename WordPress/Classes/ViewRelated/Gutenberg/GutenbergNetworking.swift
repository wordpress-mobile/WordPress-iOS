import Alamofire
import WordPressKit

struct GutenbergNetworkRequest {
    typealias CompletionHandler = (Swift.Result<Any, NSError>) -> Void

    // Please note: even though this variable is named 'path', the actually values (passed from React Native) contain
    // path and query.
    //
    // For example, when uploading an image to a post in a self-hosted site, this struct is instantiated with a path
    // `/wp/v2/media/<id>?context=edit&_locale=user`.
    private let path: String
    private unowned let blog: Blog
    private let method: HTTPMethod
    private let data: [String: AnyObject]?

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }

    init(path: String, blog: Blog, method: HTTPMethod = .get, data: [String: AnyObject]? = nil) {
        self.path = path
        self.blog = blog
        self.method = method
        self.data = data
    }

    func request(completion: @escaping CompletionHandler) {
        if blog.isAccessibleThroughWPCom(), let dotComID = blog.dotComID {
            switch method {
            case .get:
                dotComGetRequest(with: dotComID, completion: completion)
            case .post:
                dotComPostRequest(with: dotComID, data: data, completion: completion)
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

    private func dotComPostRequest(with dotComID: NSNumber, data: [String: AnyObject]?, completion: @escaping CompletionHandler) {
        blog.wordPressComRestApi()?.POST(dotComPath(with: dotComID), parameters: data, success: { (response, httpResponse) in
            completion(.success(response))
        }, failure: { (error, httpResponse) in
            completion(.failure(error.nsError(with: httpResponse)))
        })
    }

    private func dotComPath(with dotComID: NSNumber) -> String {
        return path.replacingOccurrences(of: "/wp/v2/", with: "/wp/v2/sites/\(dotComID)/")
            .replacingOccurrences(of: "/wpcom/v2/", with: "/wpcom/v2/sites/\(dotComID)/")
            .replacingOccurrences(of: "/oembed/1.0/", with: "/oembed/1.0/sites/\(dotComID)/")
    }

    // MARK: - Self-Hosed

    private func selfHostedRequest(completion: @escaping CompletionHandler) {
        performSelfHostedRequest(completion: completion)
    }

    private func performSelfHostedRequest(completion: @escaping CompletionHandler) {
        guard let api = blog.selfHostedSiteRestApi else {
            completion(.failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)))
            return
        }

        let task: Task<WordPressAPIResult<Any, WordPressOrgRestApiError>, Never>

        switch method {
        case .get:
            task = Task {
                await api.get(path: path)
            }
        case .post:
            task = Task {
                await api.post(path: path, parameters: data ?? [:])
            }
        }

        Task { @MainActor in
            let result = await task.value
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

    private func handleEmbedError(path: String, error: WordPressAPIError<WordPressOrgRestApiError>, completion: @escaping CompletionHandler) -> Bool {
        if path.starts(with: "/oembed/1.0/") {
            if case let .unacceptableStatusCode(response: response, body: _) = error, response.statusCode == 404 {
                completion(.failure(URLError(URLError.Code(rawValue: 404)) as NSError))
                return true
            }
        }
        return false
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
