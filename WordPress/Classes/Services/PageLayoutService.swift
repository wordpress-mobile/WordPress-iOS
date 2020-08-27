import Foundation
import Gutenberg

class PageLayoutService {
    typealias CompletionHandler = (Swift.Result<GutenbergPageLayouts, Error>) -> Void

    static func layouts(forBlog blog: Blog, completion: @escaping CompletionHandler) {
        if blog.isAccessibleThroughWPCom() {
            fetchWordPressComLayouts(forBlog: blog, completion: completion)
        } else {
            fetchSharedLayouts(completion: completion)
        }
    }

    private static func fetchWordPressComLayouts(forBlog blog: Blog, completion: @escaping CompletionHandler) {
        guard let blogId = blog.dotComID as? Int, let api = blog.wordPressComRestApi() else {
            let error = NSError(domain: "PageLayoutService", code: 0, userInfo: [NSDebugDescriptionErrorKey: "Api or dotCom Site ID not found"])
            completion(.failure(error))
            return
        }

        let urlPath = "/wpcom/v2/sites/\(blogId)/block-layouts"
        fetchLayouts(api, urlPath, completion)
    }

    private static func fetchSharedLayouts(completion: @escaping CompletionHandler) {
        let api = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress())
        let urlPath = "/wpcom/v2/common-block-layouts"
        fetchLayouts(api, urlPath, completion)
    }

    private static func fetchLayouts(_ api: WordPressComRestApi, _ urlPath: String, _ completion: @escaping CompletionHandler) {
        let isDevMode = BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        let supportedBlocks = Gutenberg.supportedBlocks(isDev: isDevMode).joined(separator: ",")
        let parameters: [String: AnyObject] = ["supported_blocks": supportedBlocks as AnyObject]
        api.GET(urlPath, parameters: parameters, success: { (responseObject, _) in
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

    private static func parseLayouts(fromResponse response: Any) -> GutenbergPageLayouts? {
        guard let data = try? JSONSerialization.data(withJSONObject: response) else {
            return nil
        }
        return try? JSONDecoder().decode(GutenbergPageLayouts.self, from: data)
    }
}
