import Foundation

class PageLayoutService {
    typealias CompletionHandler = (Swift.Result<GutenbergPageLayouts, Error>) -> Void

    static func layouts(forBlog blog: Blog, completion: @escaping CompletionHandler) {
        if blog.isAccessibleThroughWPCom() {
            fetchWordPressComLayouts(forBlog: blog, completion: completion)
        } else {
            fetchSharedLayouts(forBlog: blog, completion: completion)
        }
    }

    private static func fetchWordPressComLayouts(forBlog blog: Blog, completion: @escaping CompletionHandler) {
        guard let blogId = blog.dotComID as? Int, let api = blog.wordPressComRestApi() else {
            let error = NSError(domain: "PageLayoutService", code: 0, userInfo: [NSDebugDescriptionErrorKey: "Api or dotCom Site ID not found"])
            completion(.failure(error))
            return
        }

        let urlPath = "/wpcom/v2/sites/\(blogId)/block-layouts"
        api.GET(urlPath, parameters: nil, success: { (responseObject, _) in
            guard let result = parseLayouts(fromResponse: responseObject) else {
                let error = NSError(domain: "PageLayoutService", code: 0, userInfo: [NSDebugDescriptionErrorKey: "Unable to parse response"])
                completion(.failure(error))
                return
            }
            completion(.success(result))
        }, failure: { (error, _) in
            completion(.failure(error))
        })
    }

    private static func fetchSharedLayouts(forBlog blog: Blog, completion: @escaping CompletionHandler) {
        // This will be used for self-hosted sites later which are fetched through
    }

    private static func parseLayouts(fromResponse response: AnyObject) -> GutenbergPageLayouts? {
        guard let data = try? JSONSerialization.data(withJSONObject: response as Any) else {
            return nil
        }
        return try? JSONDecoder().decode(GutenbergPageLayouts.self, from: data)
    }
}
