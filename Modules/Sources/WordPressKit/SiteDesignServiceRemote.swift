import Foundation

public struct SiteDesignRequest {
    public enum TemplateGroup: String {
        case stable
        case beta
        case singlePage = "single-page"
    }

    public let parameters: [String: AnyObject]

    public init(withThumbnailSize thumbnailSize: CGSize, withGroups groups: [TemplateGroup] = []) {
        var parameters: [String: AnyObject]
        parameters = [
            "preview_width": "\(thumbnailSize.width)" as AnyObject,
            "preview_height": "\(thumbnailSize.height)" as AnyObject,
            "scale": UIScreen.main.nativeScale as AnyObject
        ]
        if 0 < groups.count {
            let groups = groups.map { $0.rawValue }
            parameters["group"] = groups.joined(separator: ",") as AnyObject
        }
        self.parameters = parameters
    }
}

public class SiteDesignServiceRemote {

    public typealias CompletionHandler = (Swift.Result<RemoteSiteDesigns, Error>) -> Void

    static let endpoint = "/wpcom/v2/common-starter-site-designs"
    static let parameters: [String: AnyObject] = [
        "type": ("mobile" as AnyObject)
    ]

    private static func joinParameters(_ parameters: [String: AnyObject], additionalParameters: [String: AnyObject]?) -> [String: AnyObject] {
        guard let additionalParameters = additionalParameters else { return parameters }
        return parameters.reduce(into: additionalParameters, { (result, element) in
            result[element.key] = element.value
        })
    }

    public static func fetchSiteDesigns(_ api: WordPressComRestApi, request: SiteDesignRequest? = nil, completion: @escaping CompletionHandler) {
        let combinedParameters: [String: AnyObject] = joinParameters(parameters, additionalParameters: request?.parameters)
        api.GET(endpoint, parameters: combinedParameters, success: { (responseObject, _) in
            do {
                let result = try parseLayouts(fromResponse: responseObject)
                completion(.success(result))
            } catch let error {
                NSLog("error response object: %@", String(describing: responseObject))
                completion(.failure(error))
            }
        }, failure: { (error, _) in
            completion(.failure(error))
        })
    }

    private static func parseLayouts(fromResponse response: Any) throws -> RemoteSiteDesigns {
        let data = try JSONSerialization.data(withJSONObject: response)
        return try JSONDecoder().decode(RemoteSiteDesigns.self, from: data)
    }
}
