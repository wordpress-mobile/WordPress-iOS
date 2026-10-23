import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public struct SiteDesignRequest {
    public enum TemplateGroup: String {
        case stable
        case beta
        case singlePage = "single-page"
    }

    public let parameters: [String: AnyObject]

    @available(*, deprecated, message: "use init(withThumbnailSize:scale:withGroups:) and pass the native scale of the window scene's screen that will display the thumbnails")
    public init(withThumbnailSize thumbnailSize: CGSize, withGroups groups: [TemplateGroup] = []) {
        self.init(withThumbnailSize: thumbnailSize, scale: Self.screenScale, withGroups: groups)
    }

    /// - Parameters:
    ///   - thumbnailSize: The size of the thumbnails, in points.
    ///   - scale: The native scale of the screen that will display the thumbnails,
    ///     for example `view.window?.windowScene?.screen.nativeScale`.
    ///   - groups: The template groups to request.
    public init(withThumbnailSize thumbnailSize: CGSize, scale: CGFloat, withGroups groups: [TemplateGroup] = []) {
        var parameters: [String: AnyObject]
        parameters = [
            "preview_width": "\(thumbnailSize.width)" as AnyObject,
            "preview_height": "\(thumbnailSize.height)" as AnyObject,
            "scale": scale as AnyObject
        ]
        if !groups.isEmpty {
            let groups = groups.map { $0.rawValue }
            parameters["group"] = groups.joined(separator: ",") as AnyObject
        }
        self.parameters = parameters
    }

    // TODO: Modernization - `UIScreen.main.nativeScale` assumes a single display and has no trait-collection
    // equivalent. This bridge only backs the deprecated initializer; remove it once every caller passes the
    // scale of its window scene's screen (`view.window?.windowScene?.screen.nativeScale`) to
    // `init(withThumbnailSize:scale:withGroups:)`.
    private static var screenScale: CGFloat {
        #if canImport(UIKit)
        return UIScreen.main.nativeScale
        #else
        return 1.0
        #endif
    }
}

public class SiteDesignServiceRemote {

    public typealias CompletionHandler = (Swift.Result<RemoteSiteDesigns, Error>) -> Void

    static let endpoint = "/wpcom/v2/common-starter-site-designs"
    static let parameters: [String: AnyObject] = [
        "type": ("mobile" as AnyObject)
    ]

    private static func joinParameters(_ parameters: [String: AnyObject], additionalParameters: [String: AnyObject]?) -> [String: AnyObject] {
        guard let additionalParameters else { return parameters }
        return parameters.reduce(into: additionalParameters, { result, element in
            result[element.key] = element.value
        })
    }

    public static func fetchSiteDesigns(_ api: WordPressComRestApi, request: SiteDesignRequest? = nil, completion: @escaping CompletionHandler) {
        let combinedParameters: [String: AnyObject] = joinParameters(parameters, additionalParameters: request?.parameters)
        api.GET(endpoint, parameters: combinedParameters, success: { responseObject, _ in
            do {
                let result = try parseLayouts(fromResponse: responseObject)
                completion(.success(result))
            } catch {
                NSLog("error response object: %@", String(describing: responseObject))
                completion(.failure(error))
            }
        }, failure: { error, _ in
            completion(.failure(error))
        })
    }

    private static func parseLayouts(fromResponse response: Any) throws -> RemoteSiteDesigns {
        let data = try JSONSerialization.data(withJSONObject: response)
        return try JSONDecoder().decode(RemoteSiteDesigns.self, from: data)
    }
}
