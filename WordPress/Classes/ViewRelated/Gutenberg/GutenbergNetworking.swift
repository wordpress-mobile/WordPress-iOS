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
        }, failure: { (error, HTTPResponse) in
            completion(.failure(error))
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
        blog.wordPressOrgRestApi?.GET(path, parameters: nil) { (result, httpResponse) in
                switch result {
                    case .success(let response):
                        completion(.success(response))
                    case .failure(let error):
                        completion(.failure(error as NSError))
                }
            }
    }
}
