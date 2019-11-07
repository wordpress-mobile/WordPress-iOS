import Alamofire

struct GutenbergNetworkRequest {
    typealias Response = (Swift.Result<Any, NSError>) -> Void

    private let path: String
    private unowned let blog: Blog

    init(path: String, blog: Blog) {
        self.path = path
        self.blog = blog
    }

    func request(response: @escaping Response) {
        if let dotComID = blog.dotComID {
            dotComRequest(with: dotComID, response: response)
        } else {
            selfHostedRequest(response: response)
        }
    }

    // MARK: - dotCom

    private func dotComRequest(with dotComID: NSNumber, response: @escaping Response) {
        blog.wordPressComRestApi()?.GET(dotComPath(with: dotComID), parameters: nil, success: { (responseObject, httpResponse) in
            response(.success(responseObject))
        }, failure: { (error, HTTPResponse) in
            response(.failure(error))
        })
    }

    private func dotComPath(with dotComID: NSNumber) -> String {
        return path.replacingOccurrences(of: "/wp/v2/", with: "/wp/v2/sites/\(dotComID)/")
    }

    // MARK: - Self-Hosed

    private func selfHostedRequest(response: @escaping Response) {
        do {
            let url = try blog.url(withPath: selfHostedPath).asURL()
            performSelfHostedRequest(with: url, response: response)
        } catch {
            response(.failure(error as NSError))
        }
    }

    private func performSelfHostedRequest(with url: URL, response: @escaping Response) {
        SessionManager.default.request(url).validate().responseJSON { (responseObject) in
            switch responseObject.result {
            case .success(let responseObject):
                response(.success(responseObject))
            case .failure(let error):
                response(.failure(error as NSError))
            }
        }
    }

    private var selfHostedPath: String {
        let removedEditContext = path.replacingOccurrences(of: "context=edit", with: "context=view")
        return "wp-json\(removedEditContext)"
    }
}
