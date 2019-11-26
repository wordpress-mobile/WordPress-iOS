import Alamofire

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
        }, failure: { (error, HTTPResponse) in
            completion(.failure(error))
        })
    }

    private func dotComPath(with dotComID: NSNumber) -> String {
        return path.replacingOccurrences(of: "/wp/v2/", with: "/wp/v2/sites/\(dotComID)/")
    }

    // MARK: - Self-Hosed

    private func selfHostedRequest(completion: @escaping CompletionHandler) {
        do {
            let url = try blog.url(withPath: selfHostedPath).asURL()
            performSelfHostedRequest(with: url, completion: completion)
        } catch {
            completion(.failure(error as NSError))
        }
    }

    private func performSelfHostedRequest(with url: URL, completion: @escaping CompletionHandler) {
        SessionManager.default.request(url).validate().responseJSON { (response) in
            switch response.result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error as NSError))
            }
        }
    }

    private var selfHostedPath: String {
        let removedEditContext = path.replacingOccurrences(of: "context=edit", with: "context=view")
        return "wp-json\(removedEditContext)"
    }
}
