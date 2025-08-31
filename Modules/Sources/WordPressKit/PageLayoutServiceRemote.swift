import Foundation

public class PageLayoutServiceRemote {

    public typealias CompletionHandler = (Swift.Result<RemotePageLayouts, Error>) -> Void
    public static func fetchLayouts(_ api: WordPressComRestApi, forBlogID blogID: Int?, withParameters parameters: [String: AnyObject]?, completion: @escaping CompletionHandler) {
        let urlPath: String
        if let blogID = blogID {
            urlPath = "/wpcom/v2/sites/\(blogID)/block-layouts"
        } else {
            urlPath = "/wpcom/v2/common-block-layouts"
        }

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

    private static func parseLayouts(fromResponse response: Any) -> RemotePageLayouts? {
        guard let data = try? JSONSerialization.data(withJSONObject: response) else {
            return nil
        }
        return try? JSONDecoder().decode(RemotePageLayouts.self, from: data)
    }
}
