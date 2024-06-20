import Foundation
import WordPressShared

public struct WordPressOrgRestApiError: LocalizedError, Decodable, HTTPURLResponseProviding {
    public enum CodingKeys: String, CodingKey {
        case code, message
    }

    public var code: String
    public var message: String?

    var response: HTTPAPIResponse<Data>?

    var httpResponse: HTTPURLResponse? {
        response?.response
    }

    public var errorDescription: String? {
        return message ?? NSLocalizedString(
            "wordpresskit.org-rest-api.not-found",
            value: "Couldn't find your site's REST API URL. The app needs that in order to communicate with your site. Contact your host to solve this problem.",
            comment: "Message to show to user when the app can't find WordPress.org REST API URL."
        )
    }
}

@objc
public final class WordPressOrgRestApi: NSObject {
    public struct SelfHostedSiteCredential {
        public let loginURL: URL
        public let username: String
        public let password: Secret<String>
        public let adminURL: URL

        public init(loginURL: URL, username: String, password: String, adminURL: URL) {
            self.loginURL = loginURL
            self.username = username
            self.password = .init(password)
            self.adminURL = adminURL
        }
    }

    enum Site {
        case dotCom(siteID: UInt64, bearerToken: String, apiURL: URL)
        case selfHosted(apiURL: URL, credential: SelfHostedSiteCredential)
    }

    let site: Site
    let urlSession: URLSession

    var selfHostedSiteNonce: String?

    public convenience init(dotComSiteID: UInt64, bearerToken: String, userAgent: String? = nil, apiURL: URL = WordPressComRestApi.apiBaseURL) {
        self.init(site: .dotCom(siteID: dotComSiteID, bearerToken: bearerToken, apiURL: apiURL), userAgent: userAgent)
    }

    public convenience init(selfHostedSiteWPJSONURL apiURL: URL, credential: SelfHostedSiteCredential, userAgent: String? = nil) {
        assert(apiURL.host != "public-api.wordpress.com", "Not a self-hosted site: \(apiURL)")
        // Potential improvement(?): discover API URL instead. See https://developer.wordpress.org/rest-api/using-the-rest-api/discovery/
        assert(apiURL.lastPathComponent == "wp-json", "Not a REST API URL: \(apiURL)")

        self.init(site: .selfHosted(apiURL: apiURL, credential: credential), userAgent: userAgent)
    }

    init(site: Site, userAgent: String? = nil) {
        self.site = site

        var additionalHeaders = [String: String]()
        if let userAgent {
            additionalHeaders["User-Agent"] = userAgent
        }
        if case let Site.dotCom(_, token, _) = site {
            additionalHeaders["Authorization"] = "Bearer \(token)"
        }

        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = additionalHeaders
        urlSession = URLSession(configuration: configuration)
    }

    deinit {
        urlSession.finishTasksAndInvalidate()
    }

    @objc
    public func invalidateAndCancelTasks() {
        urlSession.invalidateAndCancel()
    }

    public func get<Success: Decodable>(
        path: String,
        parameters: [String: Any]? = nil,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        type: Success.Type = Success.self
    ) async -> WordPressAPIResult<Success, WordPressOrgRestApiError> {
        await perform(.get, path: path, parameters: parameters, jsonDecoder: jsonDecoder, type: type)
    }

    public func get(
        path: String,
        parameters: [String: Any]? = nil,
        options: JSONSerialization.ReadingOptions = []
    ) async -> WordPressAPIResult<Any, WordPressOrgRestApiError> {
        await perform(.get, path: path, parameters: parameters, options: options)
    }

    public func post<Success: Decodable>(
        path: String,
        parameters: [String: Any]? = nil,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        type: Success.Type = Success.self
    ) async -> WordPressAPIResult<Success, WordPressOrgRestApiError> {
        await perform(.post, path: path, parameters: parameters, jsonDecoder: jsonDecoder, type: type)
    }

    public func post(
        path: String,
        parameters: [String: Any]? = nil,
        options: JSONSerialization.ReadingOptions = []
    ) async -> WordPressAPIResult<Any, WordPressOrgRestApiError> {
        await perform(.post, path: path, parameters: parameters, options: options)
    }

    func perform<Success: Decodable>(
        _ method: HTTPRequestBuilder.Method,
        path: String,
        parameters: [String: Any]? = nil,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        type: Success.Type = Success.self
    ) async -> WordPressAPIResult<Success, WordPressOrgRestApiError> {
        await perform(method, path: path, parameters: parameters) {
            try jsonDecoder.decode(type, from: $0)
        }
    }

    func perform(
        _ method: HTTPRequestBuilder.Method,
        path: String,
        parameters: [String: Any]? = nil,
        options: JSONSerialization.ReadingOptions = []
    ) async -> WordPressAPIResult<Any, WordPressOrgRestApiError> {
        await perform(method, path: path, parameters: parameters) {
            try JSONSerialization.jsonObject(with: $0, options: options)
        }
    }

    private func perform<Success>(
        _ method: HTTPRequestBuilder.Method,
        path: String,
        parameters: [String: Any]? = nil,
        decoder: @escaping (Data) throws -> Success
    ) async -> WordPressAPIResult<Success, WordPressOrgRestApiError> {
        var builder = HTTPRequestBuilder(url: apiBaseURL())
            .dotOrgRESTAPI(route: path, site: site)
            .method(method)
        if method.allowsHTTPBody {
            builder = builder.body(form: parameters ?? [:])
        } else {
            builder = builder.query(parameters ?? [:])
        }

        return await perform(builder: builder)
            .mapSuccess { try decoder($0.body) }
    }

    func perform(builder originalBuilder: HTTPRequestBuilder) async -> WordPressAPIResult<HTTPAPIResponse<Data>, WordPressOrgRestApiError> {
        var builder = originalBuilder

        if case .selfHosted = site, let nonce = selfHostedSiteNonce {
            builder = originalBuilder.header(name: "X-WP-Nonce", value: nonce)
        }

        var result = await urlSession.perform(request: builder, errorType: WordPressOrgRestApiError.self)

        // When a self hosted site request fails with 401, authenticate and retry the request.
        if case .selfHosted = site,
            case let .failure(.unacceptableStatusCode(response, _)) = result,
            response.statusCode == 401,
            await refreshNonce(),
            let nonce = selfHostedSiteNonce {
            builder = originalBuilder.header(name: "X-WP-Nonce", value: nonce)
            result = await urlSession.perform(request: builder, errorType: WordPressOrgRestApiError.self)
        }

        return result
            .mapError { error in
                if case let .unacceptableStatusCode(response, body) = error {
                    do {
                        var endpointError = try JSONDecoder().decode(WordPressOrgRestApiError.self, from: body)
                        endpointError.response = HTTPAPIResponse(response: response, body: body)
                        return WordPressAPIError.endpointError(endpointError)
                    } catch {
                        return .unparsableResponse(response: response, body: body, underlyingError: error)
                    }
                }
                return error
            }
    }

}

// MARK: - Authentication

private extension WordPressOrgRestApi {
    func apiBaseURL() -> URL {
        switch site {
        case let .dotCom(_, _, apiURL):
            return apiURL
        case let .selfHosted(apiURL, _):
            return apiURL
        }
    }

    /// Fetch REST API nonce from the site.
    ///
    /// - Returns true if the nonce is fetched and it's different than the cached one.
    func refreshNonce() async -> Bool {
        guard case let .selfHosted(_, credential) = site else {
            return false
        }

        var refreshed = false

        let methods: [NonceRetrievalMethod] = [.ajaxNonceRequest, .newPostScrap]
        for method in methods {
            guard let nonce = await method.retrieveNonce(
                username: credential.username,
                password: credential.password,
                loginURL: credential.loginURL,
                adminURL: credential.adminURL,
                using: urlSession
            ) else {
                continue
            }

            refreshed = selfHostedSiteNonce != nonce

            selfHostedSiteNonce = nonce
            break
        }

        return refreshed
    }
}

// MARK: - Helpers

private extension HTTPRequestBuilder {
    func dotOrgRESTAPI(route aRoute: String, site: WordPressOrgRestApi.Site) -> Self {
        var route = aRoute
        if !route.hasPrefix("/") {
            route = "/" + route
        }

        switch site {
        case let .dotCom(siteID, _, _):
            // Currently only the following namespaces are supported. When adding more supported namespaces, remember to
            // update the "path adapter" code below for the REST API in WP.COM.
            assert(route.hasPrefix("/wp/v2") || route.hasPrefix("/wp-block-editor/v1"), "Unsupported .org REST API route: \(route)")
            route = route
                .replacingOccurrences(of: "/wp/v2/", with: "/wp/v2/sites/\(siteID)/")
                .replacingOccurrences(of: "/wp-block-editor/v1/", with: "/wp-block-editor/v1/sites/\(siteID)/")
        case let .selfHosted(apiURL, _):
            assert(apiURL.lastPathComponent == "wp-json")
        }

        return appendURLString(route)
    }
}
