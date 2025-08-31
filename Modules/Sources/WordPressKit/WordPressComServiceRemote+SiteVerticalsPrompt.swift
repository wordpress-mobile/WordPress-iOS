import Foundation

// MARK: - Site Verticals Prompt : Request

public typealias SiteVerticalsPromptRequest = Int64

// MARK: - Site Verticals Prompt : Response

public struct SiteVerticalsPrompt: Decodable {
    public let title: String
    public let subtitle: String
    public let hint: String

    public init(title: String, subtitle: String, hint: String) {
        self.title = title
        self.subtitle = subtitle
        self.hint = hint
    }

    private enum CodingKeys: String, CodingKey {
        case title      = "site_topic_header"
        case subtitle   = "site_topic_subheader"
        case hint       = "site_topic_placeholder"
    }
}

public typealias SiteVerticalsPromptServiceCompletion = ((SiteVerticalsPrompt?) -> Void)

/// Site verticals services, exclusive to WordPress.com.
///
public extension WordPressComServiceRemote {

    /// Retrieves the prompt information presented to users when searching Verticals.
    ///
    /// - Parameters:
    ///   - request:    the value object with which to compose the request.
    ///   - completion: a closure including the result of the request for site verticals.
    ///
    func retrieveVerticalsPrompt(request: SiteVerticalsPromptRequest, completion: @escaping SiteVerticalsPromptServiceCompletion) {

        let endpoint = "verticals/prompt"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)

        let requestParameters: [String: AnyObject] = [
            "segment_id": request as AnyObject
        ]

        wordPressComRESTAPI.get(
            path,
            parameters: requestParameters,
            success: { [weak self] responseObject, httpResponse in
                WPKitLogInfo("\(responseObject) | \(String(describing: httpResponse))")

                guard let self = self else {
                    return
                }

                do {
                    let response = try self.decodeResponse(responseObject: responseObject)
                    completion(response)
                } catch {
                    WPKitLogError("Failed to decode SiteVerticalsPrompt : \(error.localizedDescription)")
                    completion(nil)
                }
            },
            failure: { error, httpResponse in
                WPKitLogError("\(error) | \(String(describing: httpResponse))")
                completion(nil)
        })
    }
}

// MARK: - Serialization support
//
private extension WordPressComServiceRemote {

    func decodeResponse(responseObject: Any) throws -> SiteVerticalsPrompt {

        let decoder = JSONDecoder()

        let data = try JSONSerialization.data(withJSONObject: responseObject, options: [])
        let response = try decoder.decode(SiteVerticalsPrompt.self, from: data)

        return response
    }
}
