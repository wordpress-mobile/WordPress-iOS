import Foundation
import Gutenberg

class PageLayoutService {
    private struct Parameters {
        static let supportedBlocks = "supported_blocks"
        static let previewWidth = "preview_width"
        static let scale = "scale"
    }

    typealias CompletionHandler = (Swift.Result<GutenbergPageLayouts, Error>) -> Void

    static func layouts(forBlog blog: Blog, withThumbnailSize thumbnailSize: CGSize, completion: @escaping CompletionHandler) {
        if blog.isAccessibleThroughWPCom() {
            fetchWordPressComLayouts(forBlog: blog, withThumbnailSize: thumbnailSize, completion: completion)
        } else {
            fetchSharedLayouts(thumbnailSize, completion: completion)
        }
    }

    private static func fetchWordPressComLayouts(forBlog blog: Blog, withThumbnailSize thumbnailSize: CGSize, completion: @escaping CompletionHandler) {
        guard let blogId = blog.dotComID as? Int, let api = blog.wordPressComRestApi() else {
            let error = NSError(domain: "PageLayoutService", code: 0, userInfo: [NSDebugDescriptionErrorKey: "Api or dotCom Site ID not found"])
            completion(.failure(error))
            return
        }

        let urlPath = "/wpcom/v2/sites/\(blogId)/block-layouts"
        fetchLayouts(thumbnailSize, api, urlPath, completion)
    }

    private static func fetchSharedLayouts(_ thumbnailSize: CGSize, completion: @escaping CompletionHandler) {
        let api = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress())
        let urlPath = "/wpcom/v2/common-block-layouts"
        fetchLayouts(thumbnailSize, api, urlPath, completion)
    }

    private static func fetchLayouts(_ thumbnailSize: CGSize, _ api: WordPressComRestApi, _ urlPath: String, _ completion: @escaping CompletionHandler) {
        api.GET(urlPath, parameters: parameters(thumbnailSize), success: { (responseObject, _) in
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

    // Parameter Generation
    private static func parameters(_ thumbnailSize: CGSize) -> [String: AnyObject] {
        return [
            Parameters.supportedBlocks: supportedBlocks as AnyObject,
            Parameters.previewWidth: previewWidth(thumbnailSize) as AnyObject,
            Parameters.scale: scale as AnyObject
        ]
    }

    private static let supportedBlocks: String = {
        let isDevMode = BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        return Gutenberg.supportedBlocks(isDev: isDevMode).joined(separator: ",")
    }()

    private static func previewWidth(_ thumbnailSize: CGSize) -> String {
        return "\(thumbnailSize.width)"
    }

    private static let scale = UIScreen.main.nativeScale
}
